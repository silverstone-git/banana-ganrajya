#!/bin/sh
set -e

# 1. Run database migrations to ensure the relational schema is up-to-date
echo "Applying database migrations..."
alembic upgrade head

# 2. Run the seeding engine to populate the database with mock data if it's a clean boot
echo "Checking and seeding default tables..."
python -m app.seed

# 3. Start the production FastAPI server using Uvicorn
echo "Launching FastAPI production server..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000
