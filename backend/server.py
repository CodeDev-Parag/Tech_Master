import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import os

from langchain_ollama import OllamaLLM, OllamaEmbeddings
from langchain_chroma import Chroma
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough
from langchain_core.output_parsers import StrOutputParser
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.docstore.document import Document

# --- Configuration ---
MODEL_NAME = os.getenv("AI_MODEL", "llama3") 
EMBED_MODEL = os.getenv("AI_EMBED_MODEL", "nomic-embed-text")

app = FastAPI(title="Task Master AI Backend")

# --- CORS (Allow Mobile Access) ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- AI Components ---
llm = OllamaLLM(model=MODEL_NAME)
embeddings = OllamaEmbeddings(model=EMBED_MODEL) 
vector_store = Chroma(
    collection_name="task_master_data",
    embedding_function=embeddings,
    persist_directory="./chroma_db"
)

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

@app.post("/train")
async def train_knowledge_base(data: TrainRequest):
    """
    Clears the current vector DB and re-populates it with the fresh snapshot
    of tasks and notes provided by the app.
    """
    global vector_store
    try:
        # Reset DB (Simplest strategy for local sync: Wipe and Replace)
        # Note: Chroma doesn't have a simple 'clear', so we delete collection and recreate
        try:
            vector_store.delete_collection()
        except:
            pass # Collection might not exist
        
        vector_store = Chroma(
            collection_name="task_master_data",
            embedding_function=embeddings,
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
            vector_store.add_documents(documents)
            
        return {"status": "success", "indexed_items": len(documents)}
    except Exception as e:
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
        retriever = vector_store.as_retriever(search_kwargs={"k": request.context_window})
        
        # 2. Build Chain
        rag_chain = (
            {"context": retriever | format_docs, "question": RunnablePassthrough()}
            | custom_rag_prompt
            | llm
            | StrOutputParser()
        )
        
        # 3. Stream Generator
        async def response_generator():
            async for chunk in rag_chain.astream(request.message):
                # Wrap text chunks in JSON or just raw text?
                # Raw text is simplest for client stream processing.
                # But let's send JSON lines for structure if needed.
                # Actually, sending raw text is fine for a chat stream if MIME type is text/event-stream or plain.
                # Let's use simple JSON lines to be safe against newlines.
                yield json.dumps({"token": chunk}) + "\n"

        return StreamingResponse(response_generator(), media_type="application/x-ndjson")

    except Exception as e:
        error_str = str(e).lower()
        if "not found" in error_str or "404" in error_str:
            raise HTTPException(status_code=503, detail="AI model is still loading. Please wait 1-2 minutes.")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    # Host 0.0.0.0 is crucial for local network access
    uvicorn.run(app, host="0.0.0.0", port=8000)
