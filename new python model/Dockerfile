FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libglib2.0-0 \
    libgl1 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD gunicorn main:app --bind 0.0.0.0:$PORT --workers 1 --threads 2 --timeout 120
