#!/bin/bash
# Restore agent inbox database

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTANCE_NAME="{{INSTANCE_NAME}}"
INBOX_DB_CONTAINER="postgres-inbox-${INSTANCE_NAME}"
BACKUP_DIR="$SCRIPT_DIR/backups"

if [ -z "$1" ]; then
    echo "Usage: $0 <backup-file>"
    echo ""
    echo "Available backups:"
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR"/*.sql.gz 2>/dev/null)" ]; then
        ls -lh "$BACKUP_DIR"/*.sql.gz | awk '{print "  " $9 " (" $5 ")"}'
    else
        echo "  No backups found"
    fi
    exit 1
fi

BACKUP_FILE="$1"

# If just filename given, look in backups directory
if [ ! -f "$BACKUP_FILE" ]; then
    BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE"
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "========================================="
echo "Restore Agent Inbox: $INSTANCE_NAME"
echo "========================================="
echo ""
echo "⚠️  WARNING: This will REPLACE ALL CURRENT DATA!"
echo ""
echo "Backup file: $BACKUP_FILE"
echo ""

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${INBOX_DB_CONTAINER}$"; then
    echo "Error: Database container is not running"
    echo "Start it with: ./start.sh"
    exit 1
fi

read -p "Are you sure? Type 'yes' to continue: " -r
echo ""

if [ "$REPLY" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

# Drop and recreate database
echo "Dropping existing database..."
docker exec "$INBOX_DB_CONTAINER" psql -U {{INBOX_DB_USER}} -d postgres -c "DROP DATABASE IF EXISTS agent_inbox;"
docker exec "$INBOX_DB_CONTAINER" psql -U {{INBOX_DB_USER}} -d postgres -c "CREATE DATABASE agent_inbox;"

# Restore backup
echo "Restoring backup..."
gunzip < "$BACKUP_FILE" | docker exec -i "$INBOX_DB_CONTAINER" psql -U {{INBOX_DB_USER}} -d agent_inbox

echo ""
echo "✓ Restore completed successfully!"
echo ""
