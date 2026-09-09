# ==============================================================================
# MandiSync AI — Backend Dockerfile
# FastAPI + XGBoost ML Engine + MongoDB Atlas
# ==============================================================================

# Stage 1: Dependency Installation
FROM python:3.11-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /build

# Install build dependencies (needed for numpy/xgboost C extensions)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies first (Docker layer caching)
COPY backend_api/requirements.txt requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt


# Stage 2: Final Slim Runtime Image
FROM python:3.11-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

# Install runtime-only system libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy installed packages from builder stage
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application source code
COPY backend_api /app/backend_api
COPY ml_engine /app/ml_engine

# Create non-root user for security
RUN addgroup --system mandisync && \
    adduser --system --ingroup mandisync mandisync && \
    chown -R mandisync:mandisync /app

USER mandisync

# Health check so Docker and load balancers know if the service is healthy
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

# Run Uvicorn with dynamic cloud PORT support (defaults to 8000 locally)
CMD ["sh", "-c", "uvicorn backend_api.app.main:app --host 0.0.0.0 --port ${PORT:-8000} --workers 2"]
