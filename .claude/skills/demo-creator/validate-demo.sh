#!/bin/bash
# Validate that a demo was created successfully
# Usage: ./validate-demo.sh <project-name>

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <project-name>"
    echo "Example: $0 invoice-payment-reconciliation"
    exit 1
fi

PROJECT_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DEMO_DIR="$WORKSPACE_ROOT/projects/$PROJECT_NAME/demo"

echo "========================================="
echo "Validating Demo: $PROJECT_NAME"
echo "========================================="
echo ""

if [ ! -d "$DEMO_DIR" ]; then
    echo "❌ Demo directory not found: $DEMO_DIR"
    exit 1
fi

ERRORS=0
WARNINGS=0

# Check news-service files
echo "Checking news-service files..."
NEWS_SERVICE_DIR="$DEMO_DIR/news-service"

check_file() {
    local file="$1"
    local required="$2"

    if [ -f "$file" ]; then
        echo "  ✓ $(basename "$file")"
    else
        if [ "$required" = "required" ]; then
            echo "  ❌ $(basename "$file") - MISSING (required)"
            ERRORS=$((ERRORS + 1))
        else
            echo "  ⚠ $(basename "$file") - MISSING (optional)"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
}

check_file "$NEWS_SERVICE_DIR/config.yaml" "required"
check_file "$NEWS_SERVICE_DIR/schema.sql" "required"
check_file "$NEWS_SERVICE_DIR/start.sh" "required"
check_file "$NEWS_SERVICE_DIR/stop.sh" "required"
check_file "$NEWS_SERVICE_DIR/status.sh" "required"
check_file "$NEWS_SERVICE_DIR/backup.sh" "required"
check_file "$NEWS_SERVICE_DIR/restore.sh" "required"
check_file "$NEWS_SERVICE_DIR/clean.sh" "required"
check_file "$NEWS_SERVICE_DIR/generate-initial-data.sh" "required"
check_file "$NEWS_SERVICE_DIR/generate-update-data.sh" "required"

# Check agent-inbox files
echo ""
echo "Checking agent-inbox files..."
AGENT_INBOX_DIR="$DEMO_DIR/agent-inbox"

check_file "$AGENT_INBOX_DIR/schema.sql" "required"
check_file "$AGENT_INBOX_DIR/start.sh" "required"
check_file "$AGENT_INBOX_DIR/stop.sh" "required"
check_file "$AGENT_INBOX_DIR/status.sh" "required"
check_file "$AGENT_INBOX_DIR/backup.sh" "required"
check_file "$AGENT_INBOX_DIR/restore.sh" "required"
check_file "$AGENT_INBOX_DIR/clean.sh" "required"

# Check agent files
echo ""
echo "Checking agent files..."
AGENT_DIR="$DEMO_DIR/agent"

check_file "$AGENT_DIR/CLAUDE.md" "required"
check_file "$AGENT_DIR/AGENTS.md" "required"
check_file "$AGENT_DIR/.gitignore" "required"
check_file "$AGENT_DIR/.newsservice" "required"
check_file "$AGENT_DIR/.agentinbox" "required"
check_file "$AGENT_DIR/news_retriever.py" "optional"
check_file "$AGENT_DIR/preferences.md" "optional"
check_file "$AGENT_DIR/dashboard.html" "required"
check_file "$AGENT_DIR/serve-dashboard.sh" "required"
check_file "$AGENT_DIR/.claude/settings.local.json" "required"

# Check agent directories
echo ""
echo "Checking agent directories..."

check_dir() {
    local dir="$1"
    local required="$2"

    if [ -d "$dir" ]; then
        echo "  ✓ $(basename "$dir")/"
    else
        if [ "$required" = "required" ]; then
            echo "  ❌ $(basename "$dir")/ - MISSING (required)"
            ERRORS=$((ERRORS + 1))
        else
            echo "  ⚠ $(basename "$dir")/ - MISSING (optional)"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
}

check_dir "$AGENT_DIR/data" "required"
check_dir "$AGENT_DIR/logs" "required"
check_dir "$AGENT_DIR/.claude" "required"
check_dir "$AGENT_DIR/.claude/skills" "required"
check_dir "$AGENT_DIR/.claude/skills/log" "required"
check_dir "$AGENT_DIR/.claude/skills/news-service" "required"

# Check README
echo ""
echo "Checking documentation..."
check_file "$DEMO_DIR/README.md" "required"

# Validate configuration
echo ""
echo "Validating configuration..."

if [ -f "$INSTANCE_DIR/config.yaml" ]; then
    if grep -q "api_key:" "$INSTANCE_DIR/config.yaml"; then
        echo "  ✓ API key in config.yaml"
    else
        echo "  ❌ API key missing in config.yaml"
        ERRORS=$((ERRORS + 1))
    fi
fi

if [ -f "$AGENT_DIR/.apikey" ]; then
    if [ -s "$AGENT_DIR/.apikey" ]; then
        echo "  ✓ .apikey file has content"
    else
        echo "  ❌ .apikey file is empty"
        ERRORS=$((ERRORS + 1))
    fi
fi

if [ -f "$AGENT_DIR/.newsservice" ]; then
    if [ -s "$AGENT_DIR/.newsservice" ]; then
        echo "  ✓ .newsservice file has content"
    else
        echo "  ❌ .newsservice file is empty"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check if scripts are executable
echo ""
echo "Checking script permissions..."

check_executable() {
    local file="$1"

    if [ -f "$file" ]; then
        if [ -x "$file" ]; then
            echo "  ✓ $(basename "$file") is executable"
        else
            echo "  ⚠ $(basename "$file") is not executable (run: chmod +x $file)"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
}

check_executable "$INSTANCE_DIR/start.sh"
check_executable "$INSTANCE_DIR/stop.sh"
check_executable "$INSTANCE_DIR/status.sh"
check_executable "$INSTANCE_DIR/clean.sh"
check_executable "$INSTANCE_DIR/generate-initial-data.sh"
check_executable "$INSTANCE_DIR/generate-update-data.sh"
check_executable "$AGENT_DIR/serve-dashboard.sh"

# Summary
echo ""
echo "========================================="
echo "Validation Summary"
echo "========================================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ Demo is complete and ready to use!"
    echo ""
    echo "Next steps:"
    echo "  1. cd $INSTANCE_DIR"
    echo "  2. ./start.sh"
    echo "  3. ./generate-initial-data.sh"
    echo "  4. cd ../agent && code ."
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  Demo is usable but has $WARNINGS warning(s)"
    echo ""
    echo "Consider fixing the warnings above for best experience."
    exit 0
else
    echo "❌ Demo has $ERRORS error(s) and $WARNINGS warning(s)"
    echo ""
    echo "Fix the errors above before using the demo."
    echo ""
    echo "To repair, you can:"
    echo "  1. Run create-demo.sh again"
    echo "  2. Manually create missing files"
    echo "  3. Delete and start over: rm -rf $DEMO_DIR"
    exit 1
fi
