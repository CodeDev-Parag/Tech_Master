#!/bin/bash

# Force Ollama to only listen on localhost (Internal)
export OLLAMA_HOST=127.0.0.1:11434
echo "DEBUG: Starting Ollama internally on 127.0.0.1:11434..."
ollama serve &

# Wait for Ollama to initialize
echo "DEBUG: Waiting for Ollama to be ready..."
MAX_RETRIES=90
RETRY_COUNT=0
while ! curl -s http://127.0.0.1:11434/api/tags > /dev/null; do
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "ERROR: Ollama failed to start after $MAX_RETRIES seconds."
        # We don't exit 1 here, let FastAPI start so Render doesn't kill the container immediately
        break
    fi
    sleep 1
done

if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
    echo "DEBUG: Ollama is ready!"
fi

# Pull models in the background
(
  MODEL=${AI_MODEL:-"phi3:mini"}
  EMBED_MODEL=${AI_EMBED_MODEL:-"nomic-embed-text"}
  echo "DEBUG: Background: Pulling model $MODEL..."
  ollama pull $MODEL
  echo "DEBUG: Background: Pulling model $EMBED_MODEL..."
  ollama pull $EMBED_MODEL
  echo "DEBUG: Background: Models ready!"
) &

# Start FastAPI on the public port
echo "DEBUG: Starting FastAPI gateway on port ${PORT:-8000}..."
# Use exec to ensure signals are passed to uvicorn
exec uvicorn server:app --host 0.0.0.0 --port ${PORT:-8000}
