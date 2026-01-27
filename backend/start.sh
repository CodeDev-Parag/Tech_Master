#!/bin/bash

# Start Ollama in the background
ollama serve &

# Wait for Ollama to start
echo "Waiting for Ollama to start..."
sleep 5

# Pull the model (This usually takes time on first run)
# We use 'llama3' as requested. Change to 'phi3' or 'tinyllama' for faster CPU performance.
MODEL=${AI_MODEL:-"llama3"}
echo "Pulling model: $MODEL"
ollama pull $MODEL

# Start FastAPI
echo "Starting FastAPI..."
uvicorn server:app --host 0.0.0.0 --port $PORT
