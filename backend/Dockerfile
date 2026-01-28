FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y curl build-essential && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy everything from the backend folder
COPY . .

# Environment variables
ENV PORT=10000

# Start FastAPI using the shell form to allow PORT substitution
CMD uvicorn server:app --host 0.0.0.0 --port $PORT
