#!/bin/bash
# Clean/reset news service instance: {{INSTANCE_NAME}}
# WARNING: This will delete all database data!

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTANCE_NAME="{{INSTANCE_NAME}}"
DB_CONTAINER="postgres-${INSTANCE_NAME}"
SERVICE_CONTAINER="news-service-${INSTANCE_NAME}"
DB_VOLUME="postgres-data-${INSTANCE_NAME}"

echo "========================================="
echo "Clean Instance: $INSTANCE_NAME"
echo "========================================="
echo ""
echo "⚠️  WARNING: This will DELETE ALL DATA!"
echo ""
echo "Docker volume: $DB_VOLUME"
echo ""
read -p "Are you sure? Type 'yes' to continue: " -r
echo ""

if [ "$REPLY" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

# Stop containers first
echo "Stopping containers..."
"$SCRIPT_DIR/stop.sh"
echo ""

# Remove Docker volume
if docker volume inspect "$DB_VOLUME" > /dev/null 2>&1; then
    echo "Deleting Docker volume..."
    docker volume rm "$DB_VOLUME"
    echo "✓ Data deleted"
else
    echo "⚠ Docker volume not found"
fi

echo ""
echo "✓ Instance cleaned"
echo ""
echo "The instance has been reset to initial state."
echo "Run start.sh to create a fresh database."
