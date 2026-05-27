#!/bin/bash
set -e
INSTANCE_NAME="payment-reconciliation-instance"
docker stop "postgres-${INSTANCE_NAME}" "news-service-${INSTANCE_NAME}" 2>/dev/null || true
docker rm "postgres-${INSTANCE_NAME}" "news-service-${INSTANCE_NAME}" 2>/dev/null || true
echo "✓ Instance stopped"
