#!/bin/bash
# Create a complete demo with project structure using templates
# Usage: ./create-demo.sh <project-name> [service-port] [db-port]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Check arguments
if [ -z "$1" ]; then
    echo "Usage: $0 <project-name> [service-port] [db-port]"
    echo ""
    echo "Example: $0 budget-assistant 8090 15440"
    echo ""
    echo "This will create:"
    echo "  projects/<project-name>/demo/news-service/    - News service instance"
    echo "  projects/<project-name>/demo/agent/           - Agent project"
    echo "  projects/<project-name>/demo/README.md        - Demo documentation"
    exit 1
fi

PROJECT_NAME="$1"
NEWS_SERVICE_PORT="${2:-$((8080 + RANDOM % 920))}"
NEWS_DB_PORT="${3:-$((15432 + RANDOM % 568))}"
INBOX_PORT="${4:-$((3000 + RANDOM % 1000))}"
INBOX_DB_PORT="${5:-$((15432 + RANDOM % 568))}"

DEMO_DIR="$WORKSPACE_ROOT/projects/$PROJECT_NAME/demo"
INSTANCE_NAME="${PROJECT_NAME}-instance"
AGENT_NAME="${PROJECT_NAME}-agent"

echo "========================================="
echo "Creating Complete Demo Project"
echo "========================================="
echo "Project: $PROJECT_NAME"
echo "Demo directory: $DEMO_DIR"
echo "News Service port: $NEWS_SERVICE_PORT"
echo "News Database port: $NEWS_DB_PORT"
echo "Agent Inbox port: $INBOX_PORT"
echo "Agent Inbox Database port: $INBOX_DB_PORT"
echo ""

# Check if demo directory already exists
if [ -d "$DEMO_DIR" ]; then
    echo "Error: Demo directory already exists at $DEMO_DIR"
    exit 1
fi

# Create demo directory structure
echo "Creating demo directory structure..."
mkdir -p "$DEMO_DIR/news-service"
mkdir -p "$DEMO_DIR/agent-inbox"
mkdir -p "$DEMO_DIR/agent/.claude/skills"
mkdir -p "$DEMO_DIR/agent/data"
mkdir -p "$DEMO_DIR/agent/logs"
echo "✓ Created directory structure"
echo ""

NEWS_SERVICE_DIR="$DEMO_DIR/news-service"
AGENT_INBOX_DIR="$DEMO_DIR/agent-inbox"
AGENT_DIR="$DEMO_DIR/agent"

# Generate secrets
DB_USER="newsuser"
DB_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(16))" 2>/dev/null || openssl rand -base64 16 | tr -d '\n')
INBOX_DB_USER="inboxuser"
INBOX_DB_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(16))" 2>/dev/null || openssl rand -base64 16 | tr -d '\n')
API_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))" 2>/dev/null || openssl rand -base64 32 | tr -d '\n')
TIMESTAMP=$(date)

# Function to replace placeholders in a file
replace_placeholders() {
    local file="$1"
    sed -i "s|{{INSTANCE_NAME}}|$INSTANCE_NAME|g" "$file"
    sed -i "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" "$file"
    sed -i "s|{{NEWS_SERVICE_PORT}}|$NEWS_SERVICE_PORT|g" "$file"
    sed -i "s|{{NEWS_DB_PORT}}|$NEWS_DB_PORT|g" "$file"
    sed -i "s|{{INBOX_PORT}}|$INBOX_PORT|g" "$file"
    sed -i "s|{{INBOX_DB_PORT}}|$INBOX_DB_PORT|g" "$file"
    sed -i "s|{{DB_USER}}|$DB_USER|g" "$file"
    sed -i "s|{{DB_PASSWORD}}|$DB_PASSWORD|g" "$file"
    sed -i "s|{{INBOX_DB_USER}}|$INBOX_DB_USER|g" "$file"
    sed -i "s|{{INBOX_DB_PASSWORD}}|$INBOX_DB_PASSWORD|g" "$file"
    sed -i "s|{{API_KEY}}|$API_KEY|g" "$file"
    sed -i "s|{{TIMESTAMP}}|$TIMESTAMP|g" "$file"
}

echo "Creating news service files from templates..."

# Copy news-service templates
cp "$TEMPLATES_DIR/news-service/config.yaml" "$NEWS_SERVICE_DIR/config.yaml"
cp "$TEMPLATES_DIR/news-service/schema.sql" "$NEWS_SERVICE_DIR/schema.sql"
cp "$TEMPLATES_DIR/news-service/start.sh" "$NEWS_SERVICE_DIR/start.sh"
cp "$TEMPLATES_DIR/news-service/stop.sh" "$NEWS_SERVICE_DIR/stop.sh"
cp "$TEMPLATES_DIR/news-service/status.sh" "$NEWS_SERVICE_DIR/status.sh"
cp "$TEMPLATES_DIR/news-service/clean.sh" "$NEWS_SERVICE_DIR/clean.sh"
cp "$TEMPLATES_DIR/news-service/backup.sh" "$NEWS_SERVICE_DIR/backup.sh"
cp "$TEMPLATES_DIR/news-service/restore.sh" "$NEWS_SERVICE_DIR/restore.sh"
cp "$TEMPLATES_DIR/news-service/generate-initial-data.sh" "$NEWS_SERVICE_DIR/generate-initial-data.sh"
cp "$TEMPLATES_DIR/news-service/generate-update-data.sh" "$NEWS_SERVICE_DIR/generate-update-data.sh"

# Replace placeholders in news-service files
for file in "$NEWS_SERVICE_DIR"/*; do
    if [ -f "$file" ]; then
        replace_placeholders "$file"
    fi
done

# Make scripts executable
chmod +x "$NEWS_SERVICE_DIR"/*.sh

echo "✓ News service files created"
echo ""

echo "Creating agent inbox files from templates..."

# Copy agent-inbox templates
cp "$TEMPLATES_DIR/agent-inbox/config.yaml" "$AGENT_INBOX_DIR/config.yaml"
cp "$TEMPLATES_DIR/agent-inbox/schema.sql" "$AGENT_INBOX_DIR/schema.sql"
cp "$TEMPLATES_DIR/agent-inbox/start.sh" "$AGENT_INBOX_DIR/start.sh"
cp "$TEMPLATES_DIR/agent-inbox/stop.sh" "$AGENT_INBOX_DIR/stop.sh"
cp "$TEMPLATES_DIR/agent-inbox/status.sh" "$AGENT_INBOX_DIR/status.sh"
cp "$TEMPLATES_DIR/agent-inbox/backup.sh" "$AGENT_INBOX_DIR/backup.sh"
cp "$TEMPLATES_DIR/agent-inbox/restore.sh" "$AGENT_INBOX_DIR/restore.sh"
cp "$TEMPLATES_DIR/agent-inbox/clean.sh" "$AGENT_INBOX_DIR/clean.sh"

# Replace placeholders in agent-inbox files
for file in "$AGENT_INBOX_DIR"/*; do
    if [ -f "$file" ]; then
        replace_placeholders "$file"
    fi
done

# Make scripts executable
chmod +x "$AGENT_INBOX_DIR"/*.sh

echo "✓ Agent inbox files created"
echo ""

echo "Creating agent project from templates..."

# Copy agent templates
cp "$TEMPLATES_DIR/agent/CLAUDE.md" "$AGENT_DIR/CLAUDE.md"
cp "$TEMPLATES_DIR/agent/AGENTS.md" "$AGENT_DIR/AGENTS.md"
cp "$TEMPLATES_DIR/agent/.gitignore" "$AGENT_DIR/.gitignore"
cp "$TEMPLATES_DIR/agent/.agentname" "$AGENT_DIR/.agentname"
cp "$TEMPLATES_DIR/agent/dashboard.html" "$AGENT_DIR/dashboard.html"
cp "$TEMPLATES_DIR/agent/serve-dashboard.sh" "$AGENT_DIR/serve-dashboard.sh"
cp "$TEMPLATES_DIR/agent/.claude/settings.local.json" "$AGENT_DIR/.claude/settings.local.json"

chmod +x "$AGENT_DIR/serve-dashboard.sh"

# Copy skills
cp -r "$WORKSPACE_ROOT/.claude/skills/log" "$AGENT_DIR/.claude/skills/"
cp -r "$WORKSPACE_ROOT/.claude/skills/news-service" "$AGENT_DIR/.claude/skills/"
cp -r "$WORKSPACE_ROOT/.claude/skills/agent-inbox" "$AGENT_DIR/.claude/skills/"
echo "✓ Copied skills"

# Copy core files if they exist
[ -f "$WORKSPACE_ROOT/news_retriever.py" ] && cp "$WORKSPACE_ROOT/news_retriever.py" "$AGENT_DIR/"
[ -f "$WORKSPACE_ROOT/preferences.md" ] && cp "$WORKSPACE_ROOT/preferences.md" "$AGENT_DIR/"

# Create config files
cat > "$AGENT_DIR/.newsservice" <<EOF
{
  "url": "http://localhost:$NEWS_SERVICE_PORT",
  "agent_name": "Demo Agent"
}
EOF

cat > "$AGENT_DIR/.agentinbox" <<EOF
{
  "url": "http://localhost:$INBOX_PORT",
  "api_key": "$API_KEY",
  "agents": {
    "DemoAgent": {
      "name": "Demo Agent",
      "description": "TODO: Customize agent descriptions in .agentinbox"
    }
  }
}
EOF

echo "✓ Agent project created"
echo ""

# Create demo README
cp "$TEMPLATES_DIR/README.md" "$DEMO_DIR/README.md"
replace_placeholders "$DEMO_DIR/README.md"
echo "✓ README.md created"
echo ""

echo "========================================="
echo "Demo Project Created Successfully!"
echo "========================================="
echo ""
echo "Location: $DEMO_DIR"
echo ""
echo "Structure:"
echo "  news-service/          - News service instance"
echo "  agent-inbox/           - Agent inbox instance"
echo "  agent/                 - Agent project"
echo "  README.md              - Documentation"
echo ""
echo "Next steps:"
echo "  1. Customize agent/AGENTS.md"
echo "  2. Customize agent/dashboard.html (optional)"
echo "  3. Customize news-service/generate-initial-data.sh"
echo "  4. cd $DEMO_DIR/news-service && ./start.sh"
echo "  5. cd $DEMO_DIR/agent-inbox && ./start.sh"
echo "  6. cd $DEMO_DIR/agent && code ."
echo ""
