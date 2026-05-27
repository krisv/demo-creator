#!/bin/bash
INSTANCE_NAME="{{INSTANCE_NAME}}"
echo "Instance Status: $INSTANCE_NAME"
echo "Database: $(docker ps --filter "name=postgres-$INSTANCE_NAME" --format '{{.Status}}' || echo 'Not running')"
echo "Service: $(docker ps --filter "name=news-service-$INSTANCE_NAME" --format '{{.Status}}' || echo 'Not running')"
