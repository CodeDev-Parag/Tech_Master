import os
import sys

# --- SQLite Hardware/Version Compatibility ---
# Required for ChromaDB on many limited Linux environments (like Render/Debian Slim)
try:
    __import__('pysqlite3')
    sys.modules['sqlite3'] = sys.modules.pop('pysqlite3')
except ImportError:
    pass

import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional

from langchain_google_genai import ChatGoogleGenerativeAI, GoogleGenerativeAIEmbeddings
from langchain_chroma import Chroma
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough
from langchain_core.output_parsers import StrOutputParser
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.docstore.document import Document

# --- Configuration ---
MODEL_NAME = os.getenv("AI_MODEL", "gemini-2.0-flash") 
EMBED_MODEL = os.getenv("AI_EMBED_MODEL", "text-embedding-004")
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

if not GOOGLE_API_KEY:
    print("WARNING: GOOGLE_API_KEY not found in environment variables.")

app = FastAPI(title="Task Master AI Backend")

# --- Middlewares ---
@app.middleware("http")
async def log_requests(request, call_next):
    print(f"DEBUG: Incoming {request.method} request to {request.url.path} from {request.base_url}")
    # Add explicit CORS headers for safety (especially for Web fallback)
    response = await call_next(request)
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS, PUT, DELETE"
    response.headers["Access-Control-Allow-Headers"] = "*"
    print(f"DEBUG: Response status code: {response.status_code}")
    return response

print(f"DEBUG: Server starting on port: {os.getenv('PORT', '8000')}")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- AI Components (Lazy Loaded) ---
_llm = None
_embeddings = None
_vector_store = None

def get_llm():
    global _llm
    if _llm is None:
        if not GOOGLE_API_KEY:
            raise HTTPException(status_code=500, detail="GOOGLE_API_KEY not configured")
        print(f"DEBUG: Initializing LLM {MODEL_NAME}")
        _llm = ChatGoogleGenerativeAI(model=MODEL_NAME, google_api_key=GOOGLE_API_KEY)
    return _llm

def get_embeddings():
    global _embeddings
    if _embeddings is None:
        if not GOOGLE_API_KEY:
            raise HTTPException(status_code=500, detail="GOOGLE_API_KEY not configured")
        print(f"DEBUG: Initializing Embeddings {EMBED_MODEL}")
        _embeddings = GoogleGenerativeAIEmbeddings(model=EMBED_MODEL, google_api_key=GOOGLE_API_KEY)
    return _embeddings

def get_vector_store():
    global _vector_store
    if _vector_store is None:
        print("DEBUG: Initializing Vector Store")
        _vector_store = Chroma(
            collection_name="task_master_data",
            embedding_function=get_embeddings(),
            persist_directory="./chroma_db"
        )
    return _vector_store

# --- Data Models ---
class TaskItem(BaseModel):
    title: str
    description: Optional[str] = ""
    status: str
    priority: str
    date: str

class TrainRequest(BaseModel):
    tasks: List[TaskItem]
    notes: List[str] = []

class ChatRequest(BaseModel):
    message: str
    context_window: int = 5 

# --- RAG Logic ---

def format_docs(docs):
    return "\n\n".join(doc.page_content for doc in docs)

template = """You are the 'Task Master Architect', a personal productivity assistant.
Use the following pieces of context (User's Tasks and Notes) to answer the question at the end.
If the answer is not in the context, just answer generally as a helpful assistant.
Keep answers concise and actionable.

Context:
{context}

Question: {question}

Answer:"""
custom_rag_prompt = ChatPromptTemplate.from_template(template)


# --- Endpoints ---

@app.get("/")
async def root():
    """Root endpoint for status check."""
    return {"status": "Task Master AI Backend is Online", "model": MODEL_NAME}

@app.get("/health")
async def health_check():
    """Verify server is alive and reachable."""
    return {"status": "alive", "model": MODEL_NAME}

import random
from datetime import datetime
import json

# Pre-load quotes for efficiency
QUOTES_FILE = os.path.join(os.path.dirname(__file__), "quotes.json")
_cached_quotes = []

def get_quotes():
    global _cached_quotes
    if not _cached_quotes:
        try:
            with open(QUOTES_FILE, 'r', encoding='utf-8') as f:
                _cached_quotes = json.load(f)
            print(f"DEBUG: Loaded {len(_cached_quotes)} quotes from {QUOTES_FILE}")
        except Exception as e:
            print(f"ERROR loading quotes: {e}")
            # Fallback
            _cached_quotes = [{"quoteText": "The best way to predict the future is to create it.", "quoteAuthor": "Peter Drucker"}]
    return _cached_quotes

@app.get("/quote")
async def get_daily_quote():
    """Returns a quote that changes daily at 12 AM."""
    quotes = get_quotes()
    
    # Selection logic: Use day of the year to ensure it changes every 24h
    # and stays the same for all users on the same day.
    day_of_year = datetime.now().timetuple().tm_yday
    # Use modulo if dataset is smaller than 365 or just to wrap around
    quote_index = day_of_year % len(quotes)
    
    selected = quotes[quote_index]
    return {
        "quote": selected.get("quoteText", "Keep going!"), 
        "author": selected.get("quoteAuthor", "Unknown")
    }

@app.post("/train")
async def train_knowledge_base(data: TrainRequest):
    """
    Clears the current vector DB and re-populates it with the fresh snapshot
    of tasks and notes provided by the app.
    """
    global _vector_store
    try:
        vs = get_vector_store()
        # Reset DB (Simplest strategy for local sync: Wipe and Replace)
        try:
            vs.delete_collection()
        except:
            pass # Collection might not exist
        
        _vector_store = Chroma(
            collection_name="task_master_data",
            embedding_function=get_embeddings(),
            persist_directory="./chroma_db"
        )

        documents = []
        
        # 1. Convert Tasks to Documents
        for task in data.tasks:
            content = f"Task: {task.title}\nStatus: {task.status}\nPriority: {task.priority}\nDueDate: {task.date}\nDescription: {task.description}"
            documents.append(Document(page_content=content, metadata={"type": "task"}))
            
        # 2. Convert Notes to Documents
        for note in data.notes:
             documents.append(Document(page_content=f"Note: {note}", metadata={"type": "note"}))
        
        if documents:
            get_vector_store().add_documents(documents)
            
        return {"status": "success", "indexed_items": len(documents)}
    except Exception as e:
        print(f"ERROR in /train: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

from fastapi.responses import StreamingResponse
import json

@app.post("/chat")
async def chat_endpoint(request: ChatRequest):
    """
    Standard RAG Chat with Streaming.
    """
    try:
        # 1. Retrieve relevant docs
        retriever = get_vector_store().as_retriever(search_kwargs={"k": request.context_window})
        
        # 2. Build Chain
        rag_chain = (
            {"context": retriever | format_docs, "question": RunnablePassthrough()}
            | custom_rag_prompt
            | get_llm()
            | StrOutputParser()
        )
        
        # 3. Stream Generator
        async def response_generator():
            async for chunk in rag_chain.astream(request.message):
                yield json.dumps({"token": chunk}) + "\n"

        return StreamingResponse(response_generator(), media_type="application/x-ndjson")

    except Exception as e:
        print(f"ERROR in /chat: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    # Host 0.0.0.0 is crucial for local network access
    uvicorn.run(app, host="0.0.0.0", port=port)
