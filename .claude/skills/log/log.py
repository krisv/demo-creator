#!/usr/bin/env python3
"""
Generic Agent Logging Utility

Provides session-based logging for agents via CLI or Python API.

CLI Usage:
    python log.py --init "Full agent instruction..." --agent-name task-news
    python log.py --session-id SESSION_ID --phase "Fetch News"
    python log.py --session-id SESSION_ID --tool-call "GET /api/news" --result "Retrieved 5 articles"
    python log.py --session-id SESSION_ID --thinking "Analyzing results..."
    python log.py --session-id SESSION_ID --output "Found 5 new articles"

Python API Usage:
    from log import initialize, log_tool_call, log_thinking, log_output, log_phase

    session_id = initialize("Full agent instruction...", agent_name="task-news")
    log_phase(session_id, "Fetch News")
    log_tool_call(session_id, "GET /api/news", result="Retrieved 5 articles")
    log_thinking(session_id, "Analyzing results...")
    log_output(session_id, "Found 5 new articles")
"""

import argparse
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

# Module-level log directory
_LOGS_DIR = Path.cwd() / "logs"


def set_logs_dir(logs_dir: Path):
    """
    Set the global logs directory

    Args:
        logs_dir: Directory for log files
    """
    global _LOGS_DIR
    _LOGS_DIR = logs_dir


def _get_log_file_path(session_id: str, agent_name: str) -> Path:
    """Get the log file path for a session"""
    _LOGS_DIR.mkdir(parents=True, exist_ok=True)
    return _LOGS_DIR / f"{agent_name}-{session_id}.log"


def _append_to_log(log_file: Path, content: str):
    """Append content to log file"""
    with open(log_file, 'a') as f:
        f.write(content)


def _get_relative_time(session_id: str) -> str:
    """
    Calculate relative time from session start

    Args:
        session_id: Session ID in format YYYYMMDD-HHMMSS

    Returns:
        Formatted string like "[+00:00:05] " for 5 seconds after session start
        (includes trailing space), or empty string if session ID invalid
    """
    try:
        # Parse session ID to get start time
        start_time = datetime.strptime(session_id, "%Y%m%d-%H%M%S")

        # Calculate time difference
        now = datetime.now()
        delta = now - start_time

        # Convert to total seconds
        total_seconds = int(delta.total_seconds())

        # Handle negative times (clock skew)
        if total_seconds < 0:
            total_seconds = 0

        # Format as HH:MM:SS with trailing space
        hours = total_seconds // 3600
        minutes = (total_seconds % 3600) // 60
        seconds = total_seconds % 60

        return f"[+{hours:02d}:{minutes:02d}:{seconds:02d}] "
    except (ValueError, Exception):
        # If session ID doesn't match format, return empty string
        return ""


def initialize(instruction: str, agent_name: str = "agent", session_id: Optional[str] = None) -> str:
    """
    Initialize a new logging session

    Creates a log file and writes the agent instruction. The instruction should be
    the full prompt given to the agent, including what it should do, workflow steps,
    context, etc.

    Args:
        instruction: Full agent prompt/instruction (can be multi-line)
        agent_name: Name of the agent (for log file naming)
        session_id: Optional session ID (auto-generated if not provided)

    Returns:
        Session ID for use in subsequent logging calls
    """
    if session_id is None:
        session_id = datetime.now().strftime("%Y%m%d-%H%M%S")

    log_file = _get_log_file_path(session_id, agent_name)

    # Write instruction
    content = f"Agent Instruction:\n{instruction}\n\n"
    _append_to_log(log_file, content)

    return session_id


def log_tool_call(session_id: str, tool_call: str, result: Optional[str] = None, agent_name: str = "agent"):
    """
    Log a tool call and optionally its result

    Args:
        session_id: Session ID from initialize()
        tool_call: Description of the tool call (e.g., "GET /api/news", "Read file: data.json")
        result: Optional result of the tool call
        agent_name: Name of the agent (must match initialize())
    """
    log_file = _get_log_file_path(session_id, agent_name)
    timestamp = _get_relative_time(session_id)

    content = f"{timestamp}TOOL CALL: {tool_call}\n"
    if result:
        content += f"{timestamp}TOOL RESULT: {result}\n"

    _append_to_log(log_file, content)


def log_thinking(session_id: str, thinking: str, agent_name: str = "agent"):
    """
    Log agent thinking/reasoning

    Args:
        session_id: Session ID from initialize()
        thinking: Agent's reasoning or thought process
        agent_name: Name of the agent (must match initialize())
    """
    log_file = _get_log_file_path(session_id, agent_name)
    timestamp = _get_relative_time(session_id)
    content = f"{timestamp}THINKING: {thinking}\n"
    _append_to_log(log_file, content)


def log_output(session_id: str, output: str, agent_name: str = "agent"):
    """
    Log agent output

    Args:
        session_id: Session ID from initialize()
        output: Output or result to log
        agent_name: Name of the agent (must match initialize())
    """
    log_file = _get_log_file_path(session_id, agent_name)
    timestamp = _get_relative_time(session_id)
    content = f"{timestamp}OUTPUT: {output}\n"
    _append_to_log(log_file, content)


def log_error(session_id: str, error: str, agent_name: str = "agent"):
    """
    Log an error

    Args:
        session_id: Session ID from initialize()
        error: Error message or description
        agent_name: Name of the agent (must match initialize())
    """
    log_file = _get_log_file_path(session_id, agent_name)
    timestamp = _get_relative_time(session_id)
    content = f"{timestamp}ERROR: {error}\n"
    _append_to_log(log_file, content)


def log_phase(session_id: str, phase: str, agent_name: str = "agent"):
    """
    Log a phase transition

    Args:
        session_id: Session ID from initialize()
        phase: Name of the phase being entered
        agent_name: Name of the agent (must match initialize())
    """
    log_file = _get_log_file_path(session_id, agent_name)
    timestamp = _get_relative_time(session_id)
    content = f"\n{timestamp}PHASE: {phase}\n"
    _append_to_log(log_file, content)


def main():
    """CLI entry point"""
    parser = argparse.ArgumentParser(
        description="Agent logging utility",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Initialize new session
  python log.py --init "Monitor news and post comments" --agent-name task-news

  # Log steps
  python log.py --session-id 20260417-120000 --phase "Fetch News"
  python log.py --session-id 20260417-120000 --tool-call "GET /api/news" --result "Retrieved 5 articles"
  python log.py --session-id 20260417-120000 --thinking "Analyzing results..."
  python log.py --session-id 20260417-120000 --output "Found 5 new articles"
  python log.py --session-id 20260417-120000 --error "Failed to connect"
        """
    )

    parser.add_argument(
        '--init',
        metavar='INSTRUCTION',
        help='Initialize new session with instruction (returns session ID)'
    )

    parser.add_argument(
        '--agent-name',
        default='agent',
        metavar='NAME',
        help='Agent name for log file naming (default: agent)'
    )

    parser.add_argument(
        '--session-id',
        metavar='SESSION_ID',
        help='Session ID for logging'
    )

    parser.add_argument(
        '--tool-call',
        metavar='DESCRIPTION',
        help='Log a tool call'
    )

    parser.add_argument(
        '--result',
        metavar='RESULT',
        help='Tool call result (use with --tool-call)'
    )

    parser.add_argument(
        '--thinking',
        metavar='MESSAGE',
        help='Log thinking/reasoning'
    )

    parser.add_argument(
        '--output',
        metavar='MESSAGE',
        help='Log output'
    )

    parser.add_argument(
        '--error',
        metavar='MESSAGE',
        help='Log error'
    )

    parser.add_argument(
        '--phase',
        metavar='NAME',
        help='Log a phase transition'
    )

    args = parser.parse_args()

    try:
        # Initialize new session
        if args.init:
            session_id = initialize(args.init, agent_name=args.agent_name)
            print(session_id)
            return 0

        # Require session_id for all other operations
        if not args.session_id:
            parser.error("--session-id is required for logging operations")

        # Log phase first if specified (allows combining with other operations)
        if args.phase:
            log_phase(args.session_id, args.phase, agent_name=args.agent_name)

        # Log tool call
        if args.tool_call:
            log_tool_call(args.session_id, args.tool_call, result=args.result, agent_name=args.agent_name)
            return 0

        # Log thinking
        if args.thinking:
            log_thinking(args.session_id, args.thinking, agent_name=args.agent_name)
            return 0

        # Log output
        if args.output:
            log_output(args.session_id, args.output, agent_name=args.agent_name)
            return 0

        # Log error
        if args.error:
            log_error(args.session_id, args.error, agent_name=args.agent_name)
            return 0

        # Phase-only (if no other operation was specified)
        if args.phase:
            return 0

        parser.error("No logging operation specified")

    except Exception as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
