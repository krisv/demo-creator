#!/bin/bash
# Start news service instance: {{INSTANCE_NAME}}

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTANCE_NAME="{{INSTANCE_NAME}}"
DB_CONTAINER="postgres-${INSTANCE_NAME}"
SERVICE_CONTAINER="news-service-${INSTANCE_NAME}"
DB_VOLUME="postgres-data-${INSTANCE_NAME}"
DB_PORT="{{NEWS_DB_PORT}}"
SERVICE_PORT="{{NEWS_SERVICE_PORT}}"
DB_USER="{{DB_USER}}"
DB_PASSWORD="{{DB_PASSWORD}}"
SCHEMA_FILE="$SCRIPT_DIR/schema.sql"

echo "========================================="
echo "Starting News Service: $INSTANCE_NAME"
echo "========================================="
echo ""

# Check if this is first run
FIRST_RUN=false
if ! docker volume inspect "$DB_VOLUME" > /dev/null 2>&1; then
    FIRST_RUN=true
    echo "Creating Docker volume: $DB_VOLUME"
    docker volume create "$DB_VOLUME"
fi

# Stop existing containers
if docker ps -a --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
    echo "Stopping existing database container..."
    docker stop "$DB_CONTAINER" 2>/dev/null || true
    docker rm "$DB_CONTAINER" 2>/dev/null || true
fi

if docker ps -a --format '{{.Names}}' | grep -q "^${SERVICE_CONTAINER}$"; then
    echo "Stopping existing service container..."
    docker stop "$SERVICE_CONTAINER" 2>/dev/null || true
    docker rm "$SERVICE_CONTAINER" 2>/dev/null || true
fi

# Start PostgreSQL
echo "Starting PostgreSQL container..."
docker run -d \
    --name "$DB_CONTAINER" \
    -p "$DB_PORT:5432" \
    -v "$DB_VOLUME:/var/lib/postgresql/data" \
    -e POSTGRES_USER="$DB_USER" \
    -e POSTGRES_PASSWORD="$DB_PASSWORD" \
    -e POSTGRES_DB="$INSTANCE_NAME" \
    postgres:16-alpine

echo "✓ PostgreSQL started on port $DB_PORT"
echo ""

# Wait for PostgreSQL
echo "Waiting for PostgreSQL..."
for i in {1..30}; do
    if docker exec "$DB_CONTAINER" pg_isready -U "$DB_USER" > /dev/null 2>&1; then
        echo "✓ PostgreSQL is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Error: PostgreSQL failed to start"
        docker logs "$DB_CONTAINER"
        exit 1
    fi
    sleep 1
done
echo ""

# Initialize schema on first run
if [ "$FIRST_RUN" = true ]; then
    echo "Initializing database schema..."
    docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" -d "$INSTANCE_NAME" < "$SCHEMA_FILE"
    echo "✓ Schema initialized"
else
    echo "Using existing database data"
fi
echo ""

# Start news service
echo "Starting news service..."
docker run -d \
    --name "$SERVICE_CONTAINER" \
    --add-host host.docker.internal:host-gateway \
    -p "$SERVICE_PORT:8080" \
    -v "$SCRIPT_DIR/config.yaml:/app/config.yaml:ro" \
    -e API_KEY="$(<"$SCRIPT_DIR/config.yaml" grep 'api_key:' | awk '{print $2}' | tr -d '"')" \
    quay.io/krisv/news-service:latest

echo "✓ Service started on port $SERVICE_PORT"
echo ""

echo "========================================="
echo "Instance Started Successfully!"
echo "========================================="
echo ""
echo "Service URL:  http://localhost:$SERVICE_PORT"
echo "Database:     localhost:$DB_PORT"
echo "API Key:      $(<"$SCRIPT_DIR/config.yaml" grep 'api_key:' | awk '{print $2}' | tr -d '"')"
echo ""
