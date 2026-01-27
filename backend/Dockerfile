FROM python:3.11-slim

# Install system dependencies (curl for Ollama)
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Set working directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy logic
COPY server.py .

# Startup script to handle Ollama + FastAPI
COPY start.sh .
RUN chmod +x start.sh

# Environment variables
ENV PORT=8000
ENV OLLAMA_HOST=0.0.0.0

CMD ["./start.sh"]
