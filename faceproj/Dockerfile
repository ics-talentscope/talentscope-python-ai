# TalentScope FaceNet Identity Service
# Build context: the python-ai repository root.

FROM python:3.11-slim

# System deps for OpenCV headless and general build
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libgl1 libglib2.0-0 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install PyTorch CPU first (small wheels), then the rest
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir -r requirements.txt

# Copy faceproj source
COPY faceproj/ ./faceproj/

WORKDIR /app/faceproj

ENV PYTHONUNBUFFERED=1

EXPOSE 10000

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "10000"]
