#!/bin/bash
INSTANCE_NAME="{{INSTANCE_NAME}}"
echo "Agent Inbox Status: $INSTANCE_NAME"
echo "Database: $(docker ps --filter "name=postgres-inbox-$INSTANCE_NAME" --format '{{.Status}}' || echo 'Not running')"
echo "Service: $(docker ps --filter "name=agent-inbox-$INSTANCE_NAME" --format '{{.Status}}' || echo 'Not running')"
