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

# Week 4 - More payments and new scenarios

# Test: Second partial payment completing INV-002
post_news \
    "Payment PAY-005 Received from TechStart Inc" \
    "Payment PAY-005 received from TechStart Inc for \$6,250.00. Reference: Invoice INV-002. Payment date: 2026-06-01." \
    "\"type:payment\", \"customer:techstart\"" \
    "2026-06-01T14:00:00Z"

# Test: Simple matched payment
post_news \
    "Payment PAY-006 Received from Acme Corp" \
    "Payment PAY-006 received from Acme Corp for \$7,500.00. Reference: Invoice INV-005. Payment date: 2026-06-02." \
    "\"type:payment\", \"customer:acme\"" \
    "2026-06-02T11:30:00Z"

# New invoice for future reconciliation
post_news \
    "Invoice INV-006 Issued to NewClient LLC" \
    "Invoice INV-006 issued to NewClient LLC for \$15,000.00. Enterprise software license. Due date: 2026-06-30." \
    "\"type:invoice\", \"customer:newclient\"" \
    "2026-06-03T09:00:00Z"

# Test: Overpayment scenario (INV-004 is $3,200, this payment is $3,500)
post_news \
    "Payment PAY-007 Received from DataCo" \
    "Payment PAY-007 received for \$3,500.00. Reference: Invoice INV-004. Customer: DataCo. Payment date: 2026-06-03." \
    "\"type:payment\", \"customer:dataco\"" \
    "2026-06-03T16:20:00Z"

# Test: Payment with no invoice reference
post_news \
    "Payment PAY-008 Received" \
    "Payment PAY-008 received for \$1,200.00. Customer name: Tech Solutions Group. Payment date: 2026-06-04." \
    "\"type:payment\", \"customer:techsolutions\"" \
    "2026-06-04T10:15:00Z"

# New invoice from DataCo
post_news \
    "Invoice INV-007 Issued to DataCo" \
    "Invoice INV-007 issued to DataCo for \$4,800.00. Additional database services for Q2. Due date: 2026-06-28." \
    "\"type:invoice\", \"customer:dataco\"" \
    "2026-06-05T13:45:00Z"

echo ""
echo "✓ Update data generated (6 new transactions)"
echo "  - 4 new payments (including edge cases)"
echo "  - 2 new invoices"
echo ""
echo "Test scenarios added:"
echo "  - Second partial payment completing an invoice"
echo "  - Payment exceeding invoice amount (error case)"
echo "  - Payment with no matching invoice"
echo ""
