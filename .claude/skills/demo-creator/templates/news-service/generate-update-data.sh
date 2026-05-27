#!/bin/bash
# Generate update data (Week 3+)
# CUSTOMIZE THIS to show progression and new scenarios!

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Read configuration
API_KEY=$(grep 'api_key:' "$SCRIPT_DIR/config.yaml" | awk '{print $2}' | tr -d '"')
SERVICE_PORT=$(grep 'SERVICE_PORT=' "$SCRIPT_DIR/start.sh" | head -1 | cut -d'=' -f2 | tr -d '"')
API_URL="http://localhost:$SERVICE_PORT/api/news"

echo "========================================="
echo "Generating Update Data"
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

echo "Creating update data..."
echo ""

# TODO: Customize with your scenario-specific updates!
# Show progression from initial data:
# - Progress on existing items
# - New issues/scenarios
# - Opportunities for agent to demonstrate value

post_news \
    "Update: Demo Progression" \
    "This is a template. Customize generate-update-data.sh to show how your scenario evolves over time.

Ideas:
- Show progress on existing items
- Introduce new scenarios
- Create opportunities for agent recommendations" \
    "\"type:demo-update\"" \
    "$TODAY"

echo ""
echo "✓ Update data generated"
echo "Remember to customize this script!"
