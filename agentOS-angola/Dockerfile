# ── Build stage ───────────────────────────────────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /app

# System deps for compiling native extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Runtime stage ─────────────────────────────────────────────────────────────
FROM python:3.12-slim AS runtime

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application source
COPY . .

# Cloud Run injects PORT; default to 8080
ENV APP_PORT=8080
EXPOSE 8080

# Non-root user for security
RUN useradd --no-create-home --shell /bin/false appuser
USER appuser

# Gunicorn + uvicorn workers — Cloud Run recommends 1 worker per vCPU
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${APP_PORT} --workers 2 --log-level info"]
