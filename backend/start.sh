#!/bin/bash

# Force Ollama to only listen on localhost (Internal)
export OLLAMA_HOST=127.0.0.1:11434
echo "DEBUG: Starting Ollama internally on 127.0.0.1:11434..."
ollama serve &

# Start Ollama in the background
echo "DEBUG: Starting Ollama internally..."
ollama serve &

# Pull models in the background (Wait a bit for Ollama to be responsive)
(
  sleep 10
  MODEL=${AI_MODEL:-"phi3:mini"}
  EMBED_MODEL=${AI_EMBED_MODEL:-"nomic-embed-text"}
  echo "DEBUG: Background: Pulling model $MODEL..."
  ollama pull $MODEL
  echo "DEBUG: Background: Pulling model $EMBED_MODEL..."
  ollama pull $EMBED_MODEL
  echo "DEBUG: Background: Models ready!"
) &

# Start FastAPI IMMEDIATELY so Render detects the open port
# The app handles lazy-loading of AI components, so it's fine if Ollama isn't ready yet.
echo "DEBUG: Starting FastAPI gateway on port ${PORT:-8000}..."
exec uvicorn server:app --host 0.0.0.0 --port ${PORT:-8000}
