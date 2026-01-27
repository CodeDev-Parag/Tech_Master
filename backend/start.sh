#!/bin/bash

# Start Ollama only on localhost
export OLLAMA_HOST=127.0.0.1:11434
ollama serve &

# Wait for Ollama to start
echo "Waiting for Ollama to start..."
sleep 5

# Pull models in the background so the server can start immediately
# This prevents Render from timing out the deployment during download
(
  MODEL=${AI_MODEL:-"llama3"}
  EMBED_MODEL=${AI_EMBED_MODEL:-"nomic-embed-text"}
  echo "Background: Pulling model: $MODEL"
  ollama pull $MODEL
  echo "Background: Pulling embedding model: $EMBED_MODEL"
  ollama pull $EMBED_MODEL
  echo "Background: Models ready!"
) &

# Start FastAPI immediately
echo "Starting FastAPI on port $PORT..."
exec uvicorn server:app --host 0.0.0.0 --port $PORT
