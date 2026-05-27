---
name: log
description: Session-based agent logging - track instructions and execution steps
---

# Agent Logger

CLI tool for session-based logging. Writes execution steps to log files immediately.

## Usage

### Initialize Session

Returns a session ID:

```bash
python .claude/skills/log/log.py --init "Full agent instruction with workflow..." --agent-name task-news
# Output: 20260417-120000
```

### Log Execution Steps

Use the session ID from initialization:

```bash
# Phase transition (use to mark major workflow stages)
python .claude/skills/log/log.py --session-id 20260417-120000 \
  --phase "Fetch News"

# Tool call with result
python .claude/skills/log/log.py --session-id 20260417-120000 \
  --tool-call "GET /api/news" --result "Retrieved 5 articles"

# Thinking
python .claude/skills/log/log.py --session-id 20260417-120000 \
  --thinking "Analyzing results..."

# Output
python .claude/skills/log/log.py --session-id 20260417-120000 \
  --output "Found 5 new articles"

# Error
python .claude/skills/log/log.py --session-id 20260417-120000 \
  --error "Connection failed"
```

## Log Format

Plain text with structured prefixes:

```
Agent Instruction:
Monitor News Service for news updates and post comments.

Workflow:
...

PHASE: Fetch News
TOOL CALL: GET /api/news
TOOL RESULT: Retrieved 2 news updates
THINKING: Processing news updates since last seen
OUTPUT: Processed 2 new updates
```

## Log Files

- **Location**: `./logs/`
- **Naming**: `{agent-name}-{session-id}.log`
- **Example**: `logs/my-agent-20260417-120000.log`

## Options

- `--init INSTRUCTION` - Initialize new session, returns session ID
- `--agent-name NAME` - Agent name for log file (default: "agent")
- `--session-id ID` - Session ID (required for logging operations)
- `--phase NAME` - Log a phase transition (marks major workflow stages)
- `--tool-call DESCRIPTION` - Log tool invocation
- `--result RESULT` - Tool result (use with --tool-call)
- `--thinking MESSAGE` - Log reasoning
- `--output MESSAGE` - Log output
- `--error MESSAGE` - Log error

## Notes

- The instruction should include the full agent prompt (what to do, workflow, context)
- All log operations write immediately to file
- Multiple operations with same session ID append to same log file
- Agent name must match across all operations in a session

See README.md for Python API usage and additional details.
