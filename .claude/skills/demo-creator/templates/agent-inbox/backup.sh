#!/bin/bash
# Backup agent inbox database
# Creates a compressed backup in backups/ directory

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTANCE_NAME="{{INSTANCE_NAME}}"
INBOX_DB_CONTAINER="postgres-inbox-${INSTANCE_NAME}"
BACKUP_DIR="$SCRIPT_DIR/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/agent-inbox-${INSTANCE_NAME}_${TIMESTAMP}.sql.gz"

echo "========================================="
echo "Backup Agent Inbox Database"
echo "========================================="
echo ""

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${INBOX_DB_CONTAINER}$"; then
    echo "Error: Database container is not running"
    echo "Start it with: ./start.sh"
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Perform backup
echo "Backing up database..."
docker exec "$INBOX_DB_CONTAINER" pg_dump -U {{INBOX_DB_USER}} agent_inbox | gzip > "$BACKUP_FILE"

# Get backup size
BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

echo ""
echo "========================================="
echo "Backup Complete!"
echo "========================================="
echo ""
echo "Backup file: $BACKUP_FILE"
echo "Size: $BACKUP_SIZE"
echo ""
echo "To restore this backup:"
echo "  ./restore.sh $BACKUP_FILE"
echo ""
