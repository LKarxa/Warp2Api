FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# System deps for building some wheels (httptools, etc.) and healthchecks
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential curl \
 && rm -rf /var/lib/apt/lists/*

# App dependencies
COPY requirements.txt ./
RUN pip install --upgrade pip \
 && pip install -r requirements.txt

# App source
COPY . .

# Entrypoint to select service: bridge | openai | all
COPY --chmod=755 entrypoint.sh /entrypoint.sh

# Default network-exposed ports
EXPOSE 8000 8010

# Reasonable defaults for container runtime
ENV HOST=0.0.0.0 \
    PORT=8010 \
    WARP_BRIDGE_URL=http://localhost:8000

ENTRYPOINT ["/entrypoint.sh"]

