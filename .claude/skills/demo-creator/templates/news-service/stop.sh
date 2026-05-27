#!/bin/bash
set -e
INSTANCE_NAME="{{INSTANCE_NAME}}"
docker stop "postgres-${INSTANCE_NAME}" "news-service-${INSTANCE_NAME}" 2>/dev/null || true
docker rm "postgres-${INSTANCE_NAME}" "news-service-${INSTANCE_NAME}" 2>/dev/null || true
echo "✓ Instance stopped"
