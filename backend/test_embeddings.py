import os
import sys
from langchain_google_genai import GoogleGenerativeAIEmbeddings

# Simulating the environment
MODEL_NAME = "models/embedding-001"
# Ensure you have set GOOGLE_API_KEY in your shell environment before running this.
API_KEY = os.getenv("GOOGLE_API_KEY")

if not API_KEY:
    print("ERROR: GOOGLE_API_KEY not found in environment.")
    sys.exit(1)

try:
    print(f"Testing initialization of {MODEL_NAME}...")
    embeddings = GoogleGenerativeAIEmbeddings(model=MODEL_NAME, google_api_key=API_KEY)
    
    query = "This is a test query to verify embeddings."
    print(f"Attempting to embed query: '{query}'")
    vector = embeddings.embed_query(query)
    
    print(f"Success! Vector length: {len(vector)}")
    print("Model is working correctly.")
except Exception as e:
    print(f"FAILED: {str(e)}")
    sys.exit(1)
