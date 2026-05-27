---
name: agent-inbox
description: Upload log files to Agent Inbox for human review and approval
---

# Agent Inbox - Upload Log Files

Upload existing log files to the Agent Inbox system for human review and approval.

## Prerequisites

**Required**: Create a `.agentinbox` configuration file in the project root with:

```json
{
  "url": "http://localhost:8080",
  "agent_id": "MyAgent",
  "agent_name": "MyAgent",
  "agent_description": "MyAgent",
  "api_key": "optional-api-key"
}
```

- `url` (required): Base URL of the agent inbox service
- `agent_id` (optional): Default agent ID (default: "MyAgent")
- `agent_name` (optional): Default agent display name (default: "MyAgent")
- `agent_description` (optional): Default agent description (default: "MyAgent")
- `api_key` (optional): API key for authentication (default: "")

The script will exit with an error if this file is missing or invalid.

## Quick Start

```bash
python .claude/skills/agent-inbox/log_task.py \
  --log-file logs/session-20260507-143022.log \
  --title "Daily news monitoring execution"
```

## Usage

### Basic Upload

```bash
python .claude/skills/agent-inbox/log_task.py \
  --log-file path/to/logfile.log \
  --title "Task title"
```

### With Full Details

```bash
python .claude/skills/agent-inbox/log_task.py \
  --log-file logs/deployment.log \
  --title "Deploy ML model v2.3" \
  --description "Model deployment execution log" \
  --priority high \
  --metadata '{"model_version": "v2.3", "accuracy": 94.2}'
```

### With Custom Agent

```bash
python .claude/skills/agent-inbox/log_task.py \
  --log-file logs/infra-change.log \
  --title "Scale database replicas" \
  --agent-id infrastructure \
  --agent-name "Infrastructure Agent" \
  --agent-description "Handles infrastructure scaling and provisioning"
```

## Options

| Option | Required | Description | Default |
|--------|----------|-------------|---------|
| `--log-file PATH` | Yes | Path to log file to upload | - |
| `--title TITLE` | Yes | Task title | - |
| `--agent-id ID` | No | Agent identifier | From .agentinbox file |
| `--agent-name NAME` | No | Agent display name | From .agentinbox file |
| `--agent-description DESC` | No | Agent description | From .agentinbox file |
| `--description DESC` | No | Task description | Empty string |
| `--priority LEVEL` | No | `high`, `medium`, or `low` | `medium` |
| `--status STATUS` | No | `completed`, `waiting_for_action`, or `partial` | `completed` |
| `--created-at TIMESTAMP` | No | ISO 8601 timestamp | Auto-parsed from filename |
| `--metadata JSON` | No | Additional metadata as JSON | `{}` |

## Configuration Override

You can override the `.agentinbox` defaults using command-line arguments:
- `--agent-id ID` - Override agent ID
- `--agent-name NAME` - Override agent name
- `--agent-description DESC` - Override agent description

## How It Works

1. **Reads the log file** from the specified path
2. **Parses timestamp** from filename (format: `Agent Name-YYYYMMDD-HHMMSS.log`)
   - Example: `Personal Coach-20260507-150823.log` → `2026-05-07T15:08:23`
   - Falls back to current time if filename doesn't match pattern
3. **Extracts description** (if not provided via `--description`):
   - Looks for `OUTPUT:` line in the log file
   - Uses the text after `OUTPUT:` as the task description
   - This becomes the activity overview in the feed
4. **Creates a task** in Agent Inbox with:
   - Task title and description (auto-extracted or manual)
   - Log file content in the `reasoning` field
   - Log file metadata (filename, size)
   - Timestamp from filename (or current time)
   - Status: `completed` (default) - shows as green in activity feed
5. **Returns task ID** for tracking

## Timestamp Parsing

The script automatically parses timestamps from log filenames in the format:
```
{agent-name}-{YYYYMMDD}-{HHMMSS}.log
```

Examples:
- `Personal Coach-20260507-150823.log` → `2026-05-07T15:08:23`
- `News Monitor-20260501-093045.log` → `2026-05-01T09:30:45`
- `random-name.log` → Uses current time (no match)

You can override with `--created-at`:
```bash
python .claude/skills/agent-inbox/log_task.py \
  --log-file my-log.txt \
  --title "Custom task" \
  --created-at "2026-05-07T15:08:23"
```

## Status Options

- **`completed`** (default) - Shows as green "Completed" badge - use for informational logs
- **`waiting_for_action`** - Shows as orange "Flagged" badge - use for logs requiring review
- **`partial`** - Shows as blue "Running" badge - use for in-progress operations

## Example Workflows

### 1. After Agent Execution

```bash
# Agent runs and logs to file
python some_agent.py > logs/session-123.log 2>&1

# Upload the log for review
python .claude/skills/agent-inbox/log_task.py \
  --log-file logs/session-123.log \
  --title "Agent execution completed" \
  --priority medium
```

### 2. With the Log Skill

```bash
# Agent logs using log skill (creates logs/task-YYYYMMDD-HHMMSS.log)
python .claude/skills/redhat-news/news_monitor.py --session-id 20260507-143022

# Upload the session log
python .claude/skills/agent-inbox/log_task.py \
  --log-file logs/task-20260507-143022.log \
  --title "News monitoring session" \
  --agent-id news-agent \
  --agent-name "News Monitor"
```

### 3. Deployment Logs

```bash
python .claude/skills/agent-inbox/log_task.py \
  --log-file logs/deploy-model-v2.3.log \
  --title "ML model v2.3 deployment" \
  --description "Production deployment of recommendation model" \
  --priority high \
  --metadata '{"model_version": "v2.3", "environment": "production", "accuracy": 94.2}'
```

### 4. Infrastructure Changes

```bash
python .claude/skills/agent-inbox/log_task.py \
  --log-file logs/scale-db-replicas.log \
  --title "Database scaling operation" \
  --agent-id infrastructure \
  --agent-name "Infrastructure Agent" \
  --priority medium \
  --metadata '{"replicas_before": 3, "replicas_after": 5}'
```

## Output

**Success:**
```
Uploading log file to Agent Inbox...
  Log file: logs/session-123.log
  Agent: Personal Coach (claude)
  Title: News monitoring session
  Priority: medium
  File size: 3,456 bytes

[OK] Log file uploaded successfully!
  Task ID: task-a1b2c3d4-e5f6-7890-abcd-ef1234567890
  Status: waiting_for_action
  Created: 2026-05-07T14:30:22

[INFO] View at: http://localhost:8080
```

**Error (file not found):**
```
Uploading log file to Agent Inbox...
  Log file: logs/missing.log
  Agent: Personal Coach (claude)
  Title: Test
  Priority: medium

Error: Log file not found: logs/missing.log

[ERROR] Log file not found: logs/missing.log
```

## What Happens After Upload?

1. **Log file content** is stored in the task's `reasoning` field
2. **Task appears** in the Agent Inbox web dashboard
3. **Human reviews** the log file and task details
4. **Human accepts or rejects** the task
5. **Task status** updates to `completed` with outcome

## Files

- **Script**: `.claude/skills/agent-inbox/log_task.py`
- **Config**: `.agentinbox` (required, in project root)
- **Logs**: Your existing log files (any location)

## Dependencies

- Python 3.6+
- No other dependencies (uses only stdlib)

## API Endpoint

The script POSTs to:
```
POST {base_url}/api/tasks
```

With payload:
```json
{
  "id": "task-{uuid}",
  "title": "Task title",
  "agent_id": "agent_id",
  "agent_name": "Agent Name",
  "description": "Description",
  "priority": "medium",
  "status": "waiting_for_action",
  "reasoning": "... (log file content) ...",
  "metadata": {
    "log_file": "filename.log",
    "log_file_size": 3456,
    ... custom metadata ...
  }
}
```

## Best Practices

### 1. Use Descriptive Titles
```bash
# Good - clear what happened
--title "Deploy recommendation model v2.3 to production"

# Bad - too vague
--title "Task completed"
```

### 2. Include Context in Metadata
```bash
--metadata '{"model_version": "v2.3", "environment": "prod", "success": true}'
```

### 3. Set Appropriate Priority
- **high**: Urgent operations, failed deployments, security issues
- **medium**: Normal operations, successful deployments
- **low**: Background tasks, informational logs

### 4. Use Consistent Agent IDs
```bash
# Keep agent IDs consistent across uploads
--agent-id news-monitor
--agent-id ml-deployer
--agent-id infrastructure
```

## Troubleshooting

**File not found:**
- Check the file path is correct
- Use absolute paths or paths relative to current directory
- Verify file exists: `ls -l path/to/logfile.log`

**Connection refused:**
- Check Agent Inbox service is running
- Verify base URL in .agentinbox file
- Test with: `curl {base_url}/api/status`

**Missing .agentinbox file:**
- Create the file in the project root
- Use the JSON format shown in Prerequisites section
- Ensure the `url` field is present

**Upload timeout:**
- Large log files may take longer (30s timeout)
- Consider splitting very large logs (>10MB)
- Check network connectivity

## Summary

Upload existing log files to Agent Inbox for human review:

```bash
python .claude/skills/agent-inbox/log_task.py \
  --log-file path/to/logfile.log \
  --title "Task title" \
  [--priority high|medium|low] \
  [--metadata '{"key": "value"}']
```

The log file content is sent to Agent Inbox where humans can review and approve/reject the task.
