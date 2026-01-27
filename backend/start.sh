#!/bin/bash

# Force Ollama to only listen on localhost (Internal)
# This prevents it from taking the public port defined by Render in $PORT
export OLLAMA_HOST=127.0.0.1:11434
echo "Starting Ollama internally on 127.0.0.1:11434..."
ollama serve &

# Wait for Ollama to initialize
sleep 5

# Pull models in the background
(
  MODEL=${AI_MODEL:-"llama3"}
  EMBED_MODEL=${AI_EMBED_MODEL:-"nomic-embed-text"}
  echo "Background: Pulling models..."
  ollama pull $MODEL
  ollama pull $EMBED_MODEL
  echo "Background: Models ready!"
) &

# Start FastAPI on the public port
# We use 'exec' to make it the primary process so Render routes traffic here correctly
echo "Starting FastAPI gateway on port $PORT..."
exec uvicorn server:app --host 0.0.0.0 --port $PORT
