#!/bin/bash
# Backup news service instance database: personal-coach

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTANCE_NAME="personal-coach"
DB_CONTAINER="postgres-${INSTANCE_NAME}"
DB_VOLUME="postgres-data-${INSTANCE_NAME}"
DB_USER="newsuser"
BACKUP_DIR="$SCRIPT_DIR/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/${INSTANCE_NAME}_${TIMESTAMP}.tar.gz"

echo "========================================="
echo "Backup Instance: $INSTANCE_NAME"
echo "========================================="
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
    echo "Error: Database container is not running"
    echo "Start it with: $SCRIPT_DIR/start.sh"
    exit 1
fi

# Check if volume exists
if ! docker volume inspect "$DB_VOLUME" > /dev/null 2>&1; then
    echo "Error: Docker volume $DB_VOLUME not found"
    exit 1
fi

echo "Backing up Docker volume: $DB_VOLUME"
echo "Backup file: $BACKUP_FILE"
echo ""

# Backup using a temporary container to tar the volume
docker run --rm \
    -v "$DB_VOLUME:/data:ro" \
    -v "$BACKUP_DIR:/backup" \
    alpine \
    tar -czf "/backup/$(basename "$BACKUP_FILE")" -C /data .

echo ""
echo "✓ Backup completed successfully!"
echo ""
echo "Backup file: $BACKUP_FILE"
echo "Size: $(du -h "$BACKUP_FILE" | cut -f1)"
echo ""
echo "To restore this backup:"
echo "  1. Stop the instance: $SCRIPT_DIR/stop.sh"
echo "  2. Clean the data: $SCRIPT_DIR/clean.sh"
echo "  3. Restore: $SCRIPT_DIR/restore.sh $(basename "$BACKUP_FILE")"
