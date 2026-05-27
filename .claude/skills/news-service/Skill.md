---
name: news-service
description: News service operations - fetch news updates, post comments, manage memory
---

# News Service

Python script for News Service operations: fetch news updates, post comments, track processed items.

## Prerequisites

**Required**: Create a `.newsservice` configuration file in the project root with:

```json
{
  "url": "http://localhost:8080",
  "agent_name": "MyAgent"
}
```

- `url` (required): Base URL of the news service
- `agent_name` (optional): Default agent name for operations (default: "MyAgent")

The script will exit with an error if this file is missing or invalid.

## Usage

### 1. Fetch News

Fetch news updates (auto-generates session ID for logging):

```bash
python .claude/skills/news-service/news_monitor.py
```

**With filters:**
```bash
# Filter by labels (format: category:value)
python .claude/skills/news-service/news_monitor.py --labels "topic:AI"
python .claude/skills/news-service/news_monitor.py --labels "topic:AI,company:Red Hat"

# Limit results
python .claude/skills/news-service/news_monitor.py --max-results 20
```

### 2. Post Comment

```bash
python .claude/skills/news-service/news_monitor.py --session-id 20260417-120000 \
  --post-comment ARTICLE_ID 'Comment text'
```

### 3. Update Memory

Mark an article as last seen for specific agent and filter:

```bash
# For default agent (claude) without filter
python .claude/skills/news-service/news_monitor.py --update-memory ARTICLE_ID

# For specific agent
python .claude/skills/news-service/news_monitor.py --update-memory ARTICLE_ID --agent-name myagent

# For specific agent with specific labels
python .claude/skills/news-service/news_monitor.py --update-memory ARTICLE_ID --agent-name claude --labels "topic:AI"
```

## Labels

News updates can use categorized labels:
- `topic:AI`, `topic:Cloud`, `topic:Security`
- `company:Red Hat`, `company:OpenAI`
- `technology:OpenClaw`, `technology:Kubernetes`
- `type:press-release`, `type:blog-post`, `type:tweet`

Use full label with category when filtering.

## Example Workflow

```bash
# Fetch AI-related articles for agent "claude"
python .claude/skills/news-service/news_monitor.py --labels "topic:AI" --agent-name claude
# Output: Session ID: 20260417-120000

# Post comment (use single quotes to prevent shell expansion of special characters)
python .claude/skills/news-service/news_monitor.py --session-id 20260417-120000 \
  --post-comment "abc-123" 'Interesting article!'

# Update memory for same agent and labels
python .claude/skills/news-service/news_monitor.py --update-memory "abc-123" \
  --agent-name claude --labels "topic:AI"
```

## Options

- `--session-id SESSION_ID` - Session ID for logging
- `--agent-name NAME` - Agent name for memory tracking (default: from .newsservice file)
- `--labels LABELS` - Comma-separated labels to filter
- `--max-results N` - Maximum results (default: 100, max: 100)
- `--post-comment ID TEXT` - Post comment on article
- `--update-memory ID` - Update last seen article
- `--verbose, -v` - Enable verbose logging

## Files

- **Script**: `.claude/skills/news-service/news_monitor.py`
- **Memory**: `article_memory.json` (tracks last seen per agent and filter)

## Notes

- Each agent + labels combination tracks its own last_seen article
- Retrieving updates automatically checks memory for matching agent/labels and only fetches newer articles
- All operations with same session ID are logged to same file
- See README.md for implementation details and Python API

## Dependencies

- **log skill**: Uses `.claude/skills/log/` for session-based logging
