FROM python:3.11-slim

# Install system dependencies for compiling packages (if needed, e.g., for numpy/pandas)
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
# Copy the local utils package into the container
COPY utils/ /app/utils

# Copy requirements first for caching
COPY collector/requirements.txt ./requirements.txt

# Upgrade pip and install deps
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Default command (overridden by docker-compose.yml)
CMD ["python", "strategy_engine.py"]