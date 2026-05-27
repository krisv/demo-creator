#!/bin/bash
# Clean/reset agent inbox database
# WARNING: This will delete all data!

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTANCE_NAME="{{INSTANCE_NAME}}"
INBOX_DB_CONTAINER="postgres-inbox-${INSTANCE_NAME}"
INBOX_CONTAINER="agent-inbox-${INSTANCE_NAME}"
INBOX_DB_VOLUME="postgres-inbox-data-${INSTANCE_NAME}"

echo "========================================="
echo "Clean Agent Inbox: $INSTANCE_NAME"
echo "========================================="
echo ""
echo "⚠️  WARNING: This will DELETE ALL DATA!"
echo ""
echo "Docker volume: $INBOX_DB_VOLUME"
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
if docker volume inspect "$INBOX_DB_VOLUME" > /dev/null 2>&1; then
    echo "Deleting Docker volume..."
    docker volume rm "$INBOX_DB_VOLUME"
    echo "✓ Data deleted"
else
    echo "⚠ Docker volume not found"
fi

echo ""
echo "✓ Agent Inbox cleaned"
echo ""
echo "The instance has been reset to initial state."
echo "Run start.sh to create a fresh database."
