#!/usr/bin/env python3
"""
Agent Inbox Task Logger - Upload existing log files

Usage:
    python log_task.py --log-file path/to/logfile.log --title "Task title"
    python log_task.py --log-file task.log --title "Deploy model" --priority high
"""

import argparse
import json
import re
import sys
import uuid
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional
import urllib.request
import urllib.error

# Configuration
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent

# Read agent inbox configuration from .agentinbox file
# This allows demos to use different URLs and agent configurations
_agentinbox_file = PROJECT_ROOT / ".agentinbox"
if not _agentinbox_file.exists():
    print(f"[ERROR] Missing required .agentinbox configuration file at: {_agentinbox_file}", file=sys.stderr)
    print(f"[ERROR] Create a .agentinbox file with the following JSON format:", file=sys.stderr)
    print(f'[ERROR]   {{"url": "http://localhost:8080", "api_key": "optional-key", "agents": {{"AgentID": {{"name": "Agent Name", "description": "Description"}}}}}}', file=sys.stderr)
    sys.exit(1)

try:
    _config = json.loads(_agentinbox_file.read_text())
    AGENT_INBOX_BASE_URL = _config.get("url")
    API_KEY = _config.get("api_key", "")
    AGENTS_MAP = _config.get("agents", {})

    # Legacy support: if agent_id/agent_name exist at root, use those as defaults
    if "agent_id" in _config:
        DEFAULT_AGENT_ID = _config.get("agent_id", "MyAgent")
        DEFAULT_AGENT_NAME = _config.get("agent_name", "MyAgent")
        DEFAULT_AGENT_DESCRIPTION = _config.get("agent_description", "MyAgent")
    elif AGENTS_MAP:
        # Use first agent from map as default
        first_agent_id = next(iter(AGENTS_MAP))
        DEFAULT_AGENT_ID = first_agent_id
        DEFAULT_AGENT_NAME = AGENTS_MAP[first_agent_id].get("name", first_agent_id)
        DEFAULT_AGENT_DESCRIPTION = AGENTS_MAP[first_agent_id].get("description", "")
    else:
        DEFAULT_AGENT_ID = "MyAgent"
        DEFAULT_AGENT_NAME = "MyAgent"
        DEFAULT_AGENT_DESCRIPTION = "MyAgent"

    if not AGENT_INBOX_BASE_URL:
        print(f"[ERROR] Missing required 'url' field in .agentinbox file", file=sys.stderr)
        sys.exit(1)

    if not AGENT_INBOX_BASE_URL.endswith("/"):
        AGENT_INBOX_BASE_URL += "/"
    # Remove trailing slash since we add it in url construction
    AGENT_INBOX_BASE_URL = AGENT_INBOX_BASE_URL.rstrip("/")
except json.JSONDecodeError as e:
    print(f"[ERROR] Invalid JSON in .agentinbox file: {e}", file=sys.stderr)
    print(f'[ERROR] Expected format: {{"url": "http://localhost:8080", "agent_id": "MyAgent", "agent_name": "MyAgent", "agent_description": "Description"}}', file=sys.stderr)
    sys.exit(1)


def parse_timestamp_from_filename(filename: str) -> Optional[str]:
    """
    Parse timestamp from log filename in format: {agent_name}-{YYYYMMDD}-{HHMMSS}.log
    Returns ISO 8601 timestamp string or None if pattern doesn't match
    """
    # Pattern: anything-YYYYMMDD-HHMMSS.log
    pattern = r'.*-(\d{8})-(\d{6})\.log$'
    match = re.match(pattern, filename)

    if match:
        date_str = match.group(1)  # YYYYMMDD
        time_str = match.group(2)  # HHMMSS

        try:
            # Parse into datetime object
            dt = datetime.strptime(f"{date_str}{time_str}", "%Y%m%d%H%M%S")
            # Return as ISO 8601 string
            return dt.isoformat()
        except ValueError:
            return None

    return None


def extract_output_from_log(log_content: str) -> Optional[str]:
    """
    Extract the OUTPUT: line from a log file for use as description
    Returns the text after "OUTPUT:" or None if not found
    Matches OUTPUT: either at the start of a line or preceded by a timestamp like [+00:05:14]
    """
    # Pattern matches:
    # - Optional timestamp prefix: [+HH:MM:SS] with optional whitespace
    # - Followed by OUTPUT:
    # - Captures the rest of the line
    pattern = r'(?:\[\+\d{2}:\d{2}:\d{2}\]\s+)?OUTPUT:\s*(.+)'

    lines = log_content.split('\n')
    for line in lines:
        stripped = line.strip()
        match = re.match(pattern, stripped)
        if match:
            output_text = match.group(1).strip()
            if output_text:
                return output_text
    return None


def upload_log_file(log_file_path: Path,
                   title: str,
                   agent_id: str,
                   agent_name: str,
                   agent_description: str,
                   description: str = "",
                   priority: str = "medium",
                   status: str = "completed",
                   created_at: Optional[str] = None,
                   metadata: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """Upload a log file to the Agent Inbox system as a task"""

    # Read log file
    if not log_file_path.exists():
        raise FileNotFoundError(f"Log file not found: {log_file_path}")

    with open(log_file_path, 'r', encoding='utf-8') as f:
        log_content = f.read()

    # Generate task ID
    task_id = f"task-{uuid.uuid4()}"

    url = f"{AGENT_INBOX_BASE_URL}/api/tasks"

    # Try to parse timestamp from filename if not provided
    if not created_at:
        created_at = parse_timestamp_from_filename(log_file_path.name)

    # Extract OUTPUT: line from log if no description provided
    if not description:
        extracted_output = extract_output_from_log(log_content)
        if extracted_output:
            description = extracted_output

    # Build task data - put log content in reasoning field
    task_data = {
        "id": task_id,
        "title": title,
        "agent_id": agent_id,
        "agent_name": agent_name,
        "agent_description": agent_description,
        "description": description,
        "priority": priority,
        "status": status,
        "reasoning": log_content,  # Log file content goes here
        "metadata": metadata or {}
    }

    # Add created_at if we have it
    if created_at:
        task_data["created_at"] = created_at

    # Add log file info to metadata
    task_data["metadata"]["log_file"] = str(log_file_path.name)
    task_data["metadata"]["log_file_size"] = len(log_content)

    try:
        data = json.dumps(task_data).encode('utf-8')
        headers = {'Content-Type': 'application/json'}

        # Add API key if configured
        if API_KEY:
            headers['X-API-Key'] = API_KEY

        req = urllib.request.Request(
            url,
            data=data,
            headers=headers,
            method='POST'
        )

        with urllib.request.urlopen(req, timeout=30) as response:
            result = json.loads(response.read().decode())
            return result

    except urllib.error.HTTPError as e:
        error_msg = e.read().decode() if e.fp else str(e)
        raise Exception(f"HTTP {e.code}: {error_msg}")
    except urllib.error.URLError as e:
        raise Exception(f"Network error: {e}")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Agent Inbox Task Logger - Upload existing log files for human review",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Upload a log file
  python log_task.py --log-file logs/session-123.log --title "Task execution log"

  # With full details
  python log_task.py \\
    --log-file logs/deployment.log \\
    --title "Deploy ML model v2.3" \\
    --description "Deployment execution log" \\
    --priority high \\
    --metadata '{"model_version": "v2.3"}'

  # With custom agent
  python log_task.py \\
    --log-file logs/infra-change.log \\
    --title "Scale database" \\
    --agent-id infrastructure \\
    --agent-name "Infrastructure Agent"
        """
    )

    parser.add_argument(
        '--log-file',
        metavar='PATH',
        required=True,
        help='Path to log file to upload (required)'
    )

    parser.add_argument(
        '--title',
        metavar='TITLE',
        required=True,
        help='Task title (required)'
    )

    parser.add_argument(
        '--agent-id',
        metavar='AGENT_ID',
        default=DEFAULT_AGENT_ID,
        help=f'Agent ID for the task (default: {DEFAULT_AGENT_ID})'
    )

    parser.add_argument(
        '--agent-name',
        metavar='AGENT_NAME',
        default=DEFAULT_AGENT_NAME,
        help=f'Agent name for display (default: {DEFAULT_AGENT_NAME})'
    )

    parser.add_argument(
        '--agent-description',
        metavar='DESC',
        default=DEFAULT_AGENT_DESCRIPTION,
        help=f'Agent description (default: {DEFAULT_AGENT_DESCRIPTION})'
    )

    parser.add_argument(
        '--description',
        metavar='DESC',
        default='',
        help='Task description'
    )

    parser.add_argument(
        '--priority',
        choices=['high', 'medium', 'low'],
        default='medium',
        help='Task priority (default: medium)'
    )

    parser.add_argument(
        '--status',
        choices=['completed', 'waiting_for_action', 'partial'],
        default='completed',
        help='Task status (default: completed - for informational logs)'
    )

    parser.add_argument(
        '--created-at',
        metavar='TIMESTAMP',
        help='Task creation timestamp (ISO 8601 format, e.g. "2026-05-07T15:08:23"). Auto-parsed from filename if not provided.'
    )

    parser.add_argument(
        '--metadata',
        metavar='JSON',
        help='Additional metadata as JSON string (e.g. \'{"key": "value"}\')'
    )

    args = parser.parse_args()

    # Look up agent info from map if agent_id is provided
    agent_id = args.agent_id
    agent_name = args.agent_name
    agent_description = args.agent_description

    # If agent_id was provided and exists in map, use map values (unless overridden by args)
    if AGENTS_MAP and agent_id in AGENTS_MAP:
        agent_config = AGENTS_MAP[agent_id]
        # Only use map values if they weren't explicitly provided via command-line args
        if agent_name == DEFAULT_AGENT_NAME:  # Not overridden
            agent_name = agent_config.get("name", agent_id)
        if agent_description == DEFAULT_AGENT_DESCRIPTION:  # Not overridden
            agent_description = agent_config.get("description", "")

    # Parse metadata if provided
    metadata = None
    if args.metadata:
        try:
            metadata = json.loads(args.metadata)
        except json.JSONDecodeError as e:
            print(f"Error: Invalid JSON in --metadata: {e}", file=sys.stderr)
            return 1

    # Convert to Path
    log_file_path = Path(args.log_file)

    try:
        print(f"Uploading log file to Agent Inbox...")
        print(f"  Log file: {log_file_path}")
        print(f"  Agent: {agent_name} ({agent_id})")
        print(f"  Title: {args.title}")
        print(f"  Priority: {args.priority}")

        # Check file exists and get size
        if not log_file_path.exists():
            print(f"\nError: Log file not found: {log_file_path}", file=sys.stderr)
            return 1

        file_size = log_file_path.stat().st_size
        print(f"  File size: {file_size:,} bytes")

        # Show timestamp info
        created_at = args.created_at
        if not created_at:
            # Try to parse from filename
            created_at = parse_timestamp_from_filename(log_file_path.name)
            if created_at:
                print(f"  Timestamp: {created_at} (parsed from filename)")
            else:
                print(f"  Timestamp: (current time - filename doesn't match pattern)")
        else:
            print(f"  Timestamp: {created_at} (manual override)")

        result = upload_log_file(
            log_file_path=log_file_path,
            title=args.title,
            agent_id=agent_id,
            agent_name=agent_name,
            agent_description=agent_description,
            description=args.description,
            priority=args.priority,
            status=args.status,
            created_at=created_at,
            metadata=metadata
        )

        task = result.get('task', {})
        print(f"\n[OK] Log file uploaded successfully!")
        print(f"  Task ID: {task.get('id')}")
        print(f"  Status: {task.get('status')}")
        print(f"  Created: {task.get('created_at')}")
        print(f"\n[INFO] View at: {AGENT_INBOX_BASE_URL}")

        return 0

    except FileNotFoundError as e:
        print(f"\n[ERROR] {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"\n[ERROR] Failed to upload log: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
