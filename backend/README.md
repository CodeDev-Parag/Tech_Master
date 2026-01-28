# Task Master AI Backend (Gemini)

This is the AI backend for Task Master, powered by Google Gemini. It provides RAG (Retrieval-Augmented Generation) capabilities for managing tasks and notes, along with automated daily motivational quotes.

## Prerequisites
- Python 3.11+
- `GOOGLE_API_KEY` (Get it from [aistudio.google.com](https://aistudio.google.com/))

## Setup
1. Create a virtual environment: `python -m venv venv`
2. Activate it: `venv\Scripts\activate` (Windows) or `source venv/bin/activate` (Linux/Mac)
3. Install dependencies: `pip install -r requirements.txt`
4. Set your API Key: `set GOOGLE_API_KEY=your_key_here` (Windows)

## How to Run
Run the FastAPI server:
```bash
python server.py
```

## Endpoints
- `GET /health`: Health check.
- `GET /quote`: Returns a daily motivational quote (rotates at 12 AM).
- `POST /train`: Syncs user tasks and notes to the vector database.
- `POST /chat`: RAG-enabled chat stream using synced data.
