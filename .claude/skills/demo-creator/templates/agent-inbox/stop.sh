#!/bin/bash
set -e
INSTANCE_NAME="{{INSTANCE_NAME}}"
docker stop "postgres-inbox-${INSTANCE_NAME}" "agent-inbox-${INSTANCE_NAME}" 2>/dev/null || true
docker rm "postgres-inbox-${INSTANCE_NAME}" "agent-inbox-${INSTANCE_NAME}" 2>/dev/null || true
echo "✓ Agent Inbox stopped"
