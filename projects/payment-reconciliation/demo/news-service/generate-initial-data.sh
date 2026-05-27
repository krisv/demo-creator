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

# Week 1 - Initial invoices issued
post_news \
    "Invoice INV-001 Issued to Acme Corp" \
    "Invoice INV-001 issued to Acme Corp for \$5,000.00. Services rendered for Q1 consulting. Due date: 2026-06-15." \
    "\"type:invoice\", \"customer:acme\"" \
    "2026-05-20T09:00:00Z"

post_news \
    "Invoice INV-002 Issued to TechStart Inc" \
    "Invoice INV-002 issued to TechStart Inc for \$12,500.00. Software development services. Due date: 2026-06-20." \
    "\"type:invoice\", \"customer:techstart\"" \
    "2026-05-20T10:30:00Z"

post_news \
    "Invoice INV-003 Issued to Global Solutions" \
    "Invoice INV-003 issued to Global Solutions for \$8,750.00. Infrastructure setup and maintenance. Due date: 2026-06-18." \
    "\"type:invoice\", \"customer:global\"" \
    "2026-05-21T14:00:00Z"

post_news \
    "Invoice INV-004 Issued to DataCo" \
    "Invoice INV-004 issued to DataCo for \$3,200.00. Database optimization services. Due date: 2026-06-22." \
    "\"type:invoice\", \"customer:dataco\"" \
    "2026-05-22T11:00:00Z"

# Week 2 - First payments arriving
post_news \
    "Payment PAY-001 Received from Acme Corp" \
    "Payment PAY-001 received from Acme Corp for \$5,000.00. Reference: Invoice INV-001. Payment date: 2026-05-25." \
    "\"type:payment\", \"customer:acme\"" \
    "2026-05-25T15:30:00Z"

post_news \
    "Payment PAY-002 Received from TechStart Inc" \
    "Payment PAY-002 received from TechStart Inc for \$6,250.00. Reference: Invoice INV-002. Payment date: 2026-05-26." \
    "\"type:payment\", \"customer:techstart\"" \
    "2026-05-26T10:15:00Z"

post_news \
    "Payment PAY-003 Received from Global Solutions" \
    "Payment PAY-003 received from Global Solutions for \$8,750.00. Reference: Invoice INV-003. Payment date: 2026-05-26." \
    "\"type:payment\", \"customer:global\"" \
    "2026-05-26T16:45:00Z"

# Week 3 - More invoices
post_news \
    "Invoice INV-005 Issued to Acme Corp" \
    "Invoice INV-005 issued to Acme Corp for \$7,500.00. Additional consulting services. Due date: 2026-06-25." \
    "\"type:invoice\", \"customer:acme\"" \
    "2026-05-27T09:30:00Z"

post_news \
    "Payment PAY-004 Received" \
    "Payment PAY-004 received for \$3,200.00. Customer name: DataCorp. Payment date: 2026-05-27." \
    "\"type:payment\", \"customer:datacorp\"" \
    "2026-05-27T14:20:00Z"

echo ""
echo "✓ Initial demo data generated (9 transactions)"
echo "  - 5 invoices issued"
echo "  - 4 payments received"
echo ""
