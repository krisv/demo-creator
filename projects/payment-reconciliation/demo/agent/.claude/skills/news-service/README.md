# Red Hat News Service Integration

Python script for interacting with the Red Hat News Service API. Provides operations for fetching articles, posting comments, and tracking processed items.

## Overview

This skill integrates with the Red Hat News Service to:
- Fetch news articles with optional filtering
- Post comments on articles
- Track which articles have been processed (memory management)
- Log all operations for audit and debugging

## API Integration

### News Service Endpoints

**Base URL:** `https://news-service-kverlaen-dev.apps.rm2.thpm.p1.openshiftapps.com`

**Endpoints:**
- `GET /api/news` - Fetch articles
- `POST /api/news/{id}/comments` - Post comment on article

### Fetch Articles

**Endpoint:** `GET /api/news`

**Query Parameters:**
- `labels` - Comma-separated list of labels to filter by
- `max_results` - Maximum number of results (default: 10, max: 100)
- `last_seen` - Last seen article ID (returns only newer articles)

**Example Requests:**
```bash
# All articles
GET /api/news?max_results=10

# Filter by labels
GET /api/news?labels=topic:AI,company:Red%20Hat

# Only new articles since last seen
GET /api/news?last_seen=abc-123&max_results=10
```

**Response:**
```json
[
  {
    "id": "xyz-456",
    "title": "Article Title",
    "content": "Article content...",
    "timestamp": "2026-04-17T12:00:00Z",
    "labels": ["topic:AI", "company:Red Hat"],
    "comments": [
      {
        "id": "comment-001",
        "name": "Claude",
        "content": "Great article!",
        "timestamp": "2026-04-17T13:00:00Z"
      }
    ]
  }
]
```

### Post Comment

**Endpoint:** `POST /api/news/{article_id}/comments`

**Request Body:**
```json
{
  "name": "Claude",
  "content": "Comment text"
}
```

**Response:**
```json
{
  "id": "comment-001",
  "name": "Claude",
  "content": "Comment text",
  "timestamp": "2026-04-17T13:00:00Z"
}
```

## Label System

Articles are tagged with categorized labels using the format `category:value`:

### Categories

- **topic:** - Subject areas
  - Examples: `topic:AI`, `topic:Cloud`, `topic:Security`, `topic:DevOps`
  
- **company:** - Organizations
  - Examples: `company:Red Hat`, `company:OpenAI`, `company:IBM`
  
- **technology:** - Specific tools/projects
  - Examples: `technology:OpenClaw`, `technology:Kubernetes`, `technology:Ansible`
  
- **type:** - Content types
  - Examples: `type:press-release`, `type:blog-post`, `type:tweet`, `type:video`

### Filtering

When filtering, use the full label including category:

```bash
# Correct
python news_monitor.py --labels "topic:AI,company:Red Hat"

# Incorrect
python news_monitor.py --labels "AI,Red Hat"
```

## Memory Management

### File: `article_memory.json`

Stores multiple last seen article IDs, one per agent and filter combination.

**Format:**
```json
{
  "last_seen": {
    "claude:": "xyz-789",
    "claude:topic:AI": "abc-123",
    "claude:company:Red Hat,topic:Cloud": "def-456",
    "bot:topic:Security": "ghi-999"
  }
}
```

**Memory Keys:**
- Format: `{agent-name}:{sorted-labels}`
- Labels are comma-separated and alphabetically sorted
- No labels: `{agent-name}:`
- Examples:
  - `claude:` - Agent "claude" with no filter
  - `claude:topic:AI` - Agent "claude" filtering by "topic:AI"
  - `claude:company:Red Hat,topic:AI` - Agent "claude" filtering by two labels (sorted)

### Behavior

1. **Fetch News:**
   - Generates memory key from agent name and labels
   - Reads `article_memory.json` to get last seen for that key
   - Passes `last_seen` to API (server-side filtering)
   - API returns only articles newer than last seen

2. **Update Memory:**
   - Generates memory key from agent name and labels
   - Updates specific key in `article_memory.json`
   - Other agent/filter combinations are preserved

### Example

```bash
# First fetch for agent "claude" with no filter
python news_monitor.py --agent-name claude
# Returns: Articles 1-10
# Memory key: "claude:"

# Update memory for this agent and filter
python news_monitor.py --update-memory "article-10" --agent-name claude
# Sets: {"last_seen": {"claude:": "article-10"}}

# Fetch for same agent with AI filter
python news_monitor.py --agent-name claude --labels "topic:AI"
# Returns: All AI articles (different memory key)
# Memory key: "claude:topic:AI"

# Update memory for AI filter
python news_monitor.py --update-memory "ai-article-5" --agent-name claude --labels "topic:AI"
# Sets: {"last_seen": {"claude:": "article-10", "claude:topic:AI": "ai-article-5"}}

# Second fetch without filter uses its own memory
python news_monitor.py --agent-name claude
# Returns: Only articles newer than article-10 (uses "claude:" key)

# Second fetch with AI filter uses its own memory
python news_monitor.py --agent-name claude --labels "topic:AI"
# Returns: Only AI articles newer than ai-article-5 (uses "claude:topic:AI" key)
```

### Multiple Agents

Different agents can track different queries:

```bash
# Agent "claude" tracking AI news
python news_monitor.py --agent-name claude --labels "topic:AI"
python news_monitor.py --update-memory "ai-123" --agent-name claude --labels "topic:AI"

# Agent "bot" tracking security news
python news_monitor.py --agent-name bot --labels "topic:Security"
python news_monitor.py --update-memory "sec-456" --agent-name bot --labels "topic:Security"

# Memory file:
# {
#   "last_seen": {
#     "claude:topic:AI": "ai-123",
#     "bot:topic:Security": "sec-456"
#   }
# }
```

## Logging

All operations are logged using the `log` skill.

### Log Files

**Location:** `logs/task-news-{SESSION_ID}.log`

**Format:**
```
Agent Instruction:
Monitor Red Hat News Service for new articles and post comments.

TOOL CALL: GET /api/news?labels=topic:AI&max_results=10&last_seen=abc-123
TOOL RESULT: Retrieved 2 articles
[
  {"id": "xyz-456", "title": "AI developments"},
  {"id": "xyz-789", "title": "AI in enterprise"}
]
THINKING: Requesting articles newer than: abc-123
OUTPUT: Articles retrieved: 2

TOOL CALL: POST /api/news/xyz-456/comments
Payload:
{
  "name": "Claude",
  "content": "Interesting article!"
}
TOOL RESULT: Comment posted successfully
Comment ID: comment-001
```

### Session Management

All operations with the same session ID append to the same log file:

```bash
# First operation - creates log file
python news_monitor.py --session-id 20260417-120000
# Creates: logs/task-news-20260417-120000.log

# Second operation - appends to existing log
python news_monitor.py --session-id 20260417-120000 --post-comment "xyz" "Comment"
# Appends to: logs/task-news-20260417-120000.log
```

## CLI Usage

### Fetch News

```bash
# Basic fetch
python .claude/skills/redhat-news/news_monitor.py

# With filters and limits
python .claude/skills/redhat-news/news_monitor.py \
  --labels "topic:AI,company:Red Hat" \
  --max-results 20

# With custom session ID
python .claude/skills/redhat-news/news_monitor.py \
  --session-id my-custom-session
```

### Post Comment

```bash
python .claude/skills/redhat-news/news_monitor.py \
  --session-id 20260417-120000 \
  --post-comment "article-id-123" "Great article about AI!"
```

### Update Memory

```bash
python .claude/skills/redhat-news/news_monitor.py \
  --update-memory "article-id-123"
```

### Verbose Mode

```bash
python .claude/skills/redhat-news/news_monitor.py --verbose
```

## Output Format

### Article Summary

```
================================================================================
Articles retrieved: 2

ARTICLES:
================================================================================

[1] New AI developments in enterprise
    ID: xyz-456
    Published: 2026-04-17T12:00:00Z
    Content: This article discusses the latest AI developments...
    Comments: None

[2] AI technology adoption
    ID: xyz-789
    Published: 2026-04-17T11:00:00Z
    Content: Many enterprises are adopting AI technologies...
    Comments (2):
      - John: Interesting perspective on adoption rates
      - Sarah: Would love to see more case studies

================================================================================

[INFO] Session ID: 20260417-120000
```

## Python API

### Internal Usage

The script can be imported and used programmatically:

```python
from news_monitor import NewsMonitor

# Create monitor
monitor = NewsMonitor(session_id="my-session")

# Fetch news
result = monitor.run_monitoring(labels=["topic:AI"], max_results=10)
print(result['summary'])

# Post comment
comment = monitor.post_comment("article-id", "Great article!")
print(f"Comment ID: {comment['id']}")

# Update memory
monitor.save_memory("article-id")
```

### Log Integration

The script uses the `log` skill for all logging:

```python
from log import log_tool_call, log_thinking, log_output

# Logs are written immediately
log_tool_call(session_id, "GET /api/news", result="Retrieved 5 articles", agent_name="task-news")
log_thinking(session_id, "Processing articles...", agent_name="task-news")
log_output(session_id, "Found 2 new articles", agent_name="task-news")
```

## Error Handling

### Network Errors

```bash
[ERROR] Failed to fetch news: <urlopen error [Errno 111] Connection refused>
```

### Invalid JSON

```bash
[ERROR] Invalid JSON response: Expecting value: line 1 column 1 (char 0)
```

### HTTP Errors

```bash
[ERROR] Failed to post comment: 404 - Article not found
```

## Architecture

### Class: NewsMonitor

**Purpose:** Manages news operations and logging

**Key Methods:**
- `fetch_news()` - Fetch articles from API
- `post_comment()` - Post comment on article
- `load_memory()` - Read last seen article from file
- `save_memory()` - Write last seen article to file
- `run_monitoring()` - Run full fetch workflow
- `log_step()` - Log execution steps

### Dependencies

**External:**
- Red Hat News Service API
- Log skill (`.claude/skills/log/`)

**Python Standard Library:**
- `argparse` - CLI argument parsing
- `json` - JSON serialization
- `logging` - Console logging
- `urllib.request` - HTTP requests
- `pathlib` - File path handling

## Design Decisions

### Server-Side Filtering

The script leverages server-side filtering via the `last_seen` parameter rather than fetching all articles and filtering client-side. This:
- Reduces network bandwidth
- Improves performance
- Scales better with large article counts
- Single source of truth (server)

### Session-Based Logging

All operations within a session (fetch, comment, update) are logged to the same file. This:
- Groups related operations
- Provides complete audit trail
- Easier to debug multi-step workflows

### Memory File

Uses simple JSON file for memory rather than database. This:
- No external dependencies
- Easy to inspect and modify
- Sufficient for single-value storage
- Portable across systems

### Immediate Logging

Logs are written immediately via the `log` skill rather than buffered. This:
- Easier to debug failures
- No data loss on crashes
- Real-time monitoring

## Integration with AGENTS.md

The workflow is defined in `AGENTS.md`, not in the skill. The skill provides primitives:

**Skill provides:**
- Fetch articles
- Post comments
- Update memory

**AGENTS.md defines:**
- When to fetch
- Which articles to comment on
- What comments to post
- When to update memory

This separation allows the skill to be reusable across different workflows.

## Troubleshooting

### Memory file not found

This is normal on first run. The script will return all articles and you can set the memory after processing:

```bash
python news_monitor.py --update-memory "first-article-id"
```

### No new articles

If memory is set and no new articles exist, you'll see:

```
Articles retrieved: 0

No new articles found.
```

### Session ID mismatch

If you use different session IDs, logs will be in separate files:

```bash
# Creates logs/task-news-session-1.log
python news_monitor.py --session-id session-1

# Creates logs/task-news-session-2.log  
python news_monitor.py --session-id session-2
```

Use the same session ID to group operations.

### Label filtering not working

Make sure to include the category prefix:

```bash
# Wrong
--labels "AI,Red Hat"

# Correct
--labels "topic:AI,company:Red Hat"
```

## Examples

### Monitor AI News Daily

```bash
#!/bin/bash

# Fetch AI news
SESSION_ID=$(date +%Y%m%d)-ai-news

python news_monitor.py \
  --session-id $SESSION_ID \
  --labels "topic:AI" \
  --max-results 20

# Post comment on first article
# (After manual review)
python news_monitor.py \
  --session-id $SESSION_ID \
  --post-comment "article-id" "Insightful analysis!"

# Update memory
python news_monitor.py --update-memory "article-id"
```

### Check for Company Mentions

```bash
python news_monitor.py \
  --labels "company:Red Hat,type:press-release" \
  --max-results 50
```

### Automated Workflow

```python
from news_monitor import NewsMonitor

monitor = NewsMonitor(session_id="auto-2026-04-17")

# Fetch
result = monitor.run_monitoring(labels=["topic:AI"], max_results=10)

# Process each article
for article in result['articles']:
    # Your logic to decide if comment is needed
    if should_comment(article):
        comment_text = generate_comment(article)
        monitor.post_comment(article['id'], comment_text)

# Update memory with latest
if result['articles']:
    latest_id = result['articles'][0]['id']
    monitor.save_memory(latest_id)
```
