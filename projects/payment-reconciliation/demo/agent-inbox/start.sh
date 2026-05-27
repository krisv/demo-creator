#!/bin/bash
# Start agent inbox service: payment-reconciliation-instance

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTANCE_NAME="payment-reconciliation-instance"
INBOX_DB_CONTAINER="postgres-inbox-${INSTANCE_NAME}"
INBOX_CONTAINER="agent-inbox-${INSTANCE_NAME}"
INBOX_DB_VOLUME="postgres-inbox-data-${INSTANCE_NAME}"
INBOX_DB_PORT="15442"
INBOX_PORT="3402"
INBOX_DB_USER="inboxuser"
INBOX_DB_PASSWORD="V3sWmpd7foK79OvycAiagg"
API_KEY="fgPx4Jom7_m35Zb6MwFYE2SbDxB0UDInlTxIfgPILo8"
SCHEMA_FILE="$SCRIPT_DIR/schema.sql"

echo "========================================="
echo "Starting Agent Inbox: $INSTANCE_NAME"
echo "========================================="
echo ""

# Check if this is first run
FIRST_RUN=false
if ! docker volume inspect "$INBOX_DB_VOLUME" > /dev/null 2>&1; then
    FIRST_RUN=true
    echo "Creating Docker volume: $INBOX_DB_VOLUME"
    docker volume create "$INBOX_DB_VOLUME"
fi

# Stop existing containers
if docker ps -a --format '{{.Names}}' | grep -q "^${INBOX_DB_CONTAINER}$"; then
    echo "Stopping existing inbox database container..."
    docker stop "$INBOX_DB_CONTAINER" 2>/dev/null || true
    docker rm "$INBOX_DB_CONTAINER" 2>/dev/null || true
fi

if docker ps -a --format '{{.Names}}' | grep -q "^${INBOX_CONTAINER}$"; then
    echo "Stopping existing inbox service container..."
    docker stop "$INBOX_CONTAINER" 2>/dev/null || true
    docker rm "$INBOX_CONTAINER" 2>/dev/null || true
fi

# Start PostgreSQL for Agent Inbox
echo "Starting PostgreSQL container for Agent Inbox..."
docker run -d \
    --name "$INBOX_DB_CONTAINER" \
    -p "$INBOX_DB_PORT:5432" \
    -v "$INBOX_DB_VOLUME:/var/lib/postgresql/data" \
    -e POSTGRES_USER="$INBOX_DB_USER" \
    -e POSTGRES_PASSWORD="$INBOX_DB_PASSWORD" \
    -e POSTGRES_DB="agent_inbox" \
    postgres:16-alpine

echo "✓ PostgreSQL started on port $INBOX_DB_PORT"
echo ""

# Wait for PostgreSQL
echo "Waiting for PostgreSQL..."
for i in {1..30}; do
    if docker exec "$INBOX_DB_CONTAINER" pg_isready -U "$INBOX_DB_USER" > /dev/null 2>&1; then
        echo "✓ PostgreSQL is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Error: PostgreSQL failed to start"
        docker logs "$INBOX_DB_CONTAINER"
        exit 1
    fi
    sleep 1
done
echo ""

# Initialize schema on first run
if [ "$FIRST_RUN" = true ]; then
    echo "Initializing database schema..."
    docker exec -i "$INBOX_DB_CONTAINER" psql -U "$INBOX_DB_USER" -d "agent_inbox" < "$SCHEMA_FILE"
    echo "✓ Schema initialized"
else
    echo "Using existing database data"
fi
echo ""

# Start agent inbox service
echo "Starting agent inbox service..."
docker run -d \
    --name "$INBOX_CONTAINER" \
    --add-host host.docker.internal:host-gateway \
    -p "$INBOX_PORT:8080" \
    -v "$SCRIPT_DIR/config.yaml:/app/config.yaml:ro" \
    -e API_KEY="$API_KEY" \
    quay.io/krisv/agent-inbox:latest

echo "✓ Agent Inbox started on port $INBOX_PORT"
echo ""

echo "========================================="
echo "Agent Inbox Started Successfully!"
echo "========================================="
echo ""
echo "Service URL:  http://localhost:$INBOX_PORT"
echo "Database:     localhost:$INBOX_DB_PORT"
echo "API Key:      $API_KEY"
echo ""
