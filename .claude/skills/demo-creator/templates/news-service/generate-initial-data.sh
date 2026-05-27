#!/bin/bash
# Generate initial demo data
# CUSTOMIZE THIS with your scenario-specific data!

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Read configuration
API_KEY=$(grep 'api_key:' "$SCRIPT_DIR/config.yaml" | awk '{print $2}' | tr -d '"')
SERVICE_PORT=$(grep 'SERVICE_PORT=' "$SCRIPT_DIR/start.sh" | head -1 | cut -d'=' -f2 | tr -d '"')
API_URL="http://localhost:$SERVICE_PORT/api/news"

echo "========================================="
echo "Generating Demo Data"
echo "========================================="
echo "API URL: $API_URL"
echo ""

# Helper function
post_news() {
    local title="$1"
    local content="$2"
    local labels="$3"
    local timestamp="$4"

    local response=$(curl -s -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -H "X-API-Key: $API_KEY" \
        -d @- <<EOF
{
    "title": "$title",
    "content": "$content",
    "labels": [$labels],
    "timestamp": "$timestamp"
}
EOF
    )

    if echo "$response" | grep -q '"id"'; then
        echo "✓ Posted: $title"
    else
        echo "✗ Failed: $title"
    fi
}

TODAY=$(date -u +"%Y-%m-%dT12:00:00Z")

echo "Creating demo data..."
echo ""

# NOTE: Use $TODAY for all timestamps for cross-platform compatibility
# Avoid date arithmetic (e.g., 'date -d "2 hours ago"') - it fails on Windows Git Bash
# If you need different timestamps, use ISO format strings directly

# TODO: Customize with your demo data!

post_news \
    "Demo Data Ready" \
    "This is a template. Customize generate-initial-data.sh with your scenario-specific news items." \
    "\"type:demo\"" \
    "$TODAY"

echo ""
echo "✓ Demo data generated"
echo "Remember to customize this script!"
