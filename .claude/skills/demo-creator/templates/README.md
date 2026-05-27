# {{PROJECT_NAME}} Demo

Demo created on {{TIMESTAMP}}

## Structure

```
demo/
  news-service/           # News service instance
    config.yaml
    start.sh
    stop.sh
    status.sh
    backup.sh
    restore.sh
    clean.sh
    generate-initial-data.sh
    generate-update-data.sh
  agent-inbox/            # Agent inbox instance
    schema.sql
    start.sh
    stop.sh
    status.sh
    backup.sh
    restore.sh
    clean.sh
  agent/                  # Agent project
    CLAUDE.md
    AGENTS.md
    dashboard.html        # Web dashboard (customize!)
    data/
  README.md               # This file
```

## Setup

1. **Customize the scenario**
   - Edit `agent/AGENTS.md` with agent behavior
   - Edit `news-service/generate-initial-data.sh` with demo data
   - Create data structure in `agent/data/`
   - Edit `agent/dashboard.html` to display your data (optional but recommended!)

2. **Start services**
   ```bash
   cd news-service
   ./start.sh
   ./generate-initial-data.sh
   cd ../agent-inbox
   ./start.sh
   ```

3. **Run the agent**
   ```bash
   cd ../agent
   code .  # Open in Claude Code
   # Say: "Process new updates"
   ```

## Quick Start

```bash
# From demo directory
cd news-service && ./start.sh && cd ..
cd agent-inbox && ./start.sh && cd ..
# Customize: nano news-service/generate-initial-data.sh
cd news-service && ./generate-initial-data.sh && cd ..
cd agent && code .
```

## Service Info

**News Service:**
- Service URL: http://localhost:{{NEWS_SERVICE_PORT}}
- Database Port: {{NEWS_DB_PORT}}
- API Key: See news-service/config.yaml

**Agent Inbox:**
- Service URL: http://localhost:{{INBOX_PORT}}
- Database Port: {{INBOX_DB_PORT}}
- API Key: (same as news service)

## Next Steps

1. **Customize the scenario:**
   - Edit agent/AGENTS.md with agent behavior
   - Define data structure in agent/data/
   - Customize agent/dashboard.html if needed

2. **Customize demo data:**
   - Edit news-service/generate-initial-data.sh (initial baseline data)
   - Edit news-service/generate-update-data.sh (follow-up updates to show progression)

3. **Run the demo:**
   - Start services (news-service and agent-inbox) and generate initial data
   - Run agent in Claude Code to process updates
   - View dashboard: `./serve-dashboard.sh` then open http://localhost:8000/dashboard.html
   - View agent inbox: http://localhost:{{INBOX_PORT}}
   - Generate update data to show progression
   - Process updates again and watch dashboard update in real-time
