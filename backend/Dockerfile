# --- BUILD STAGE ---
# Use the official slim Python base image to assemble dependencies
FROM python:3.11-slim as builder

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /backend

# Install minimal compiler dependencies (required for some compiled extensions like cryptography)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Create a virtual environment to isolate and cleanly bundle all dependencies
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install and build packages inside the virtual environment
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt


# --- RUNTIME STAGE ---
# Use a fresh slim image for the runner to keep image sizes extremely lightweight
FROM python:3.11-slim as runner

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /backend

# Install curl, create PostgreSQL certificates folder, and download CockroachDB CA root certificate
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /root/.postgresql \
    && curl -o /root/.postgresql/root.crt 'https://cockroachlabs.cloud/clusters/b91c0eaf-6468-4852-9873-98c8dfeaa5db/cert'

# Copy the entire isolated virtual environment from the builder stage
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application layers, configurations, and migration paths
COPY app/ app/
COPY alembic/ alembic/
COPY alembic.ini .
COPY start.sh .

# Configure permissions for the entrypoint shell script
RUN chmod +x start.sh

# Expose FastAPI production port
EXPOSE 8000

# Execute migrations and boot FastAPI
ENTRYPOINT ["./start.sh"]
