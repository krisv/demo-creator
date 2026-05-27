#!/bin/bash
# Restore news service database

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTANCE_NAME="{{INSTANCE_NAME}}"
DB_VOLUME="postgres-data-${INSTANCE_NAME}"
BACKUP_DIR="$SCRIPT_DIR/backups"

if [ -z "$1" ]; then
    echo "Usage: $0 <backup-file>"
    echo ""
    echo "Available backups:"
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR"/*.tar.gz 2>/dev/null)" ]; then
        ls -lh "$BACKUP_DIR"/*.tar.gz | awk '{print "  " $9 " (" $5 ")"}'
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
echo "Restore News Service: $INSTANCE_NAME"
echo "========================================="
echo ""
echo "⚠️  WARNING: This will REPLACE ALL CURRENT DATA!"
echo ""
echo "Backup file: $BACKUP_FILE"
echo ""
read -p "Are you sure? Type 'yes' to continue: " -r
echo ""

if [ "$REPLY" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

# Ensure containers are stopped
echo "Stopping containers..."
"$SCRIPT_DIR/stop.sh" 2>/dev/null || true
echo ""

# Remove existing volume if it exists
if docker volume inspect "$DB_VOLUME" > /dev/null 2>&1; then
    echo "Removing existing volume..."
    docker volume rm "$DB_VOLUME"
fi

# Create new volume
echo "Creating new volume..."
docker volume create "$DB_VOLUME"

# Restore backup to volume
echo "Restoring backup..."
docker run --rm \
    -v "$DB_VOLUME:/data" \
    -v "$(dirname "$BACKUP_FILE"):/backup:ro" \
    alpine \
    tar -xzf "/backup/$(basename "$BACKUP_FILE")" -C /data

echo ""
echo "✓ Restore completed successfully!"
echo ""
echo "Start the instance: $SCRIPT_DIR/start.sh"
