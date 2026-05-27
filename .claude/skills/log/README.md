# Agent Logger

Session-based logging utility for agents. Provides both CLI and Python API for tracking agent instructions and execution steps.

> **For CLI usage**, see [Skill.md](Skill.md) - this document focuses on the Python API, design, and integration patterns.

## Python API Usage

### Basic Usage

```python
import sys
from pathlib import Path

# Add log skill to path
sys.path.insert(0, str(Path(__file__).parent.parent / "log"))
from log import initialize, log_phase, log_tool_call, log_thinking, log_output, log_error

# Initialize session
instruction = """Monitor Red Hat News Service for new articles and post comments.

Workflow:
..."""

session_id = initialize(instruction, agent_name="my-agent")
print(f"Session ID: {session_id}")

# Log execution steps
log_phase(session_id, "Fetch News", agent_name="my-agent")
log_tool_call(session_id, "GET /api/news", result="Retrieved 5 articles", agent_name="my-agent")
log_thinking(session_id, "Identifying new articles since last seen", agent_name="my-agent")
log_output(session_id, "Found 2 new articles", agent_name="my-agent")
```

## Python API Reference

#### initialize()

```python
initialize(
    instruction: str,
    agent_name: str = "agent",
    session_id: Optional[str] = None
) -> str
```

Create new logging session and write instruction. Returns session ID.

**Args:**
- `instruction`: Full agent prompt (what to do, workflow, context)
- `agent_name`: Agent name for log file naming (default: "agent")
- `session_id`: Custom session ID (default: auto-generated YYYYMMDD-HHMMSS)

**Returns:** Session ID

#### log_tool_call()

```python
log_tool_call(
    session_id: str,
    tool_call: str,
    result: Optional[str] = None,
    agent_name: str = "agent"
)
```

Log a tool invocation and optionally its result.

**Args:**
- `session_id`: Session ID from initialize()
- `tool_call`: Description (e.g., "GET /api/news", "Read file: data.json")
- `result`: Optional result
- `agent_name`: Agent name (must match initialize())

#### log_thinking()

```python
log_thinking(session_id: str, thinking: str, agent_name: str = "agent")
```

Log agent reasoning or thought process.

#### log_output()

```python
log_output(session_id: str, output: str, agent_name: str = "agent")
```

Log agent output or result.

#### log_error()

```python
log_error(session_id: str, error: str, agent_name: str = "agent")
```

Log an error.

#### log_phase()

```python
log_phase(session_id: str, phase: str, agent_name: str = "agent")
```

Log a phase transition (major workflow stage).

**Args:**
- `session_id`: Session ID from initialize()
- `phase`: Name of the phase being entered
- `agent_name`: Agent name (must match initialize())

#### set_logs_dir()

```python
set_logs_dir(logs_dir: Path)
```

Set the global logs directory (optional).

## Design Philosophy

### Ownership

The log skill completely owns:
- Where logs are stored
- How logs are formatted
- When logs are written

Callers just specify:
- What to log (instruction, tool calls, thinking, outputs)
- Session context (session ID, agent name)

### Simplicity

**CLI-first design:**
- Works from command line without Python knowledge
- Can be invoked from any script or tool
- Simple, predictable behavior

**Immediate writes:**
- No buffering or batching
- No `save()` or `flush()` needed
- What you log is immediately on disk

**Function-based API:**
- No classes or instances to manage
- Just call functions with the data
- Stateless and simple

## Integration

### With Other Skills

```python
# In your skill's Python script
import sys
from pathlib import Path

# Add log skill to path
SCRIPT_DIR = Path(__file__).parent
LOG_SKILL_DIR = SCRIPT_DIR.parent / "log"
sys.path.insert(0, str(LOG_SKILL_DIR))

from log import initialize, log_phase, log_tool_call, log_output

# Use it
session_id = initialize("My task", agent_name="my-agent")
log_phase(session_id, "Execute Task", agent_name="my-agent")
log_tool_call(session_id, "Some operation", result="Success", agent_name="my-agent")
```

### With Shell Scripts

```bash
#!/bin/bash

# Initialize logging
SESSION_ID=$(python .claude/skills/log/log.py \
  --init "Automated deployment" \
  --agent-name deploy-agent)

echo "Starting deployment (session: $SESSION_ID)"

# Log steps
python .claude/skills/log/log.py --session-id $SESSION_ID \
  --output "Building application..." --agent-name deploy-agent

# Your deployment commands here
./build.sh

python .claude/skills/log/log.py --session-id $SESSION_ID \
  --output "Deployment complete" --agent-name deploy-agent
```

## Advanced Features

### Custom Session ID

```python
from log import initialize

session_id = initialize(
    instruction="Process data pipeline",
    agent_name="data-processor",
    session_id="custom-session-123"
)
# Uses "custom-session-123" instead of auto-generated timestamp
```

### Custom Log Directory

```python
from pathlib import Path
from log import set_logs_dir, initialize

# Set global log directory (affects all subsequent calls)
set_logs_dir(Path("/var/log/agents"))

session_id = initialize("Process data", agent_name="processor")
# Logs now written to /var/log/agents/processor-{session-id}.log
```

## Example: Data Processing Pipeline

```python
from log import initialize, log_phase, log_tool_call, log_thinking, log_output

session_id = initialize("Process customer data", agent_name="data-pipeline")

log_phase(session_id, "Load Data", agent_name="data-pipeline")
log_tool_call(session_id, "Read data/customers.csv", result="1000 records", agent_name="data-pipeline")

log_phase(session_id, "Process Data", agent_name="data-pipeline")
log_thinking(session_id, "Filtering active customers", agent_name="data-pipeline")
log_output(session_id, "Found 850 active customers", agent_name="data-pipeline")

log_phase(session_id, "Save Results", agent_name="data-pipeline")
log_tool_call(session_id, "Write output/active.csv", result="Success", agent_name="data-pipeline")
```

## Notes

- **Agent name consistency**: The `agent_name` parameter must match across all operations in a session (initialize, log_phase, log_tool_call, etc.). Mismatched names will write to different log files.
- **Log location**: Default is `./logs/` relative to current working directory. Use `set_logs_dir()` to change.
- **Immediate writes**: All log operations write to disk immediately - no buffering or flushing needed.
- **Relative timestamps**: The log file shows relative timestamps (`[+00:00:05]`) calculated from the session ID start time.
