#!/usr/bin/env python3
"""
News Retriever Agent

Retrieves new articles from Red Hat News Service based on user preferences.

Usage:
    python news_retriever.py --session-id SESSION_ID
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Dict, Any, List, Optional

# Add log skill to path
SCRIPT_DIR = Path(__file__).parent
LOG_SKILL_DIR = SCRIPT_DIR / ".claude" / "skills" / "log"
NEWS_SKILL_DIR = SCRIPT_DIR / ".claude" / "skills" / "news-service"
sys.path.insert(0, str(LOG_SKILL_DIR))
sys.path.insert(0, str(NEWS_SKILL_DIR))

from log import initialize, log_tool_call, log_thinking, log_error, log_output, log_phase
from news_monitor import NewsMonitor

# File paths
PREFERENCES_FILE = SCRIPT_DIR / "preferences.md"
NEWS_MONITOR_SCRIPT = SCRIPT_DIR / ".claude" / "skills" / "news-service" / "news_monitor.py"

# Agent name - read from .agentname file if exists, otherwise use default
_agentname_file = SCRIPT_DIR / ".agentname"
if _agentname_file.exists():
    AGENT_NAME = _agentname_file.read_text().strip()
else:
    AGENT_NAME = "Personal Coach"


def read_preferences(session_id: str) -> Dict[str, Any]:
    """Read preferences from preferences.md"""
    if not PREFERENCES_FILE.exists():
        result = "Preferences file does not exist. Using defaults: no label filters, no exclusions."
        log_tool_call(
            session_id,
            f"Read preferences file: {PREFERENCES_FILE.name}",
            result=result,
            agent_name=AGENT_NAME
        )
        return {
            "labels": None,
            "exclude_description": None
        }

    try:
        with open(PREFERENCES_FILE, 'r') as f:
            content = f.read()

        # Parse preferences
        labels = None
        exclude_description = None

        # Extract labels (look for "Labels:" section)
        if "Labels:" in content:
            lines = content.split('\n')
            for i, line in enumerate(lines):
                if line.strip().startswith("Labels:"):
                    # Get the value after "Labels:"
                    label_line = line.split("Labels:", 1)[1].strip()
                    if label_line and label_line.lower() != "none":
                        labels = [l.strip() for l in label_line.split(',')]
                    break

        # Extract exclude description (look for "Exclude:" section)
        if "Exclude:" in content:
            lines = content.split('\n')
            exclude_lines = []
            in_exclude = False
            for line in lines:
                if line.strip().startswith("Exclude:"):
                    in_exclude = True
                    # Get text after "Exclude:" on same line
                    exclude_text = line.split("Exclude:", 1)[1].strip()
                    if exclude_text:
                        exclude_lines.append(exclude_text)
                elif in_exclude:
                    # Continue until we hit another section or empty line
                    if line.strip() and not line.strip().endswith(':'):
                        exclude_lines.append(line.strip())
                    elif line.strip().endswith(':'):
                        break

            if exclude_lines:
                exclude_description = ' '.join(exclude_lines)

        result = f"Labels: {labels or 'none'}\nExclude: {exclude_description or 'none'}"
        log_tool_call(
            session_id,
            f"Read preferences file: {PREFERENCES_FILE.name}",
            result=result,
            agent_name=AGENT_NAME
        )

        return {
            "labels": labels,
            "exclude_description": exclude_description
        }

    except Exception as e:
        log_error(session_id, f"Failed to read preferences: {e}", agent_name=AGENT_NAME)
        return {
            "labels": None,
            "exclude_description": None
        }


def fetch_articles(session_id: str, labels: Optional[List[str]]) -> List[Dict[str, Any]]:
    """Fetch articles from news service using news_monitor.py"""
    cmd = [
        sys.executable,
        str(NEWS_MONITOR_SCRIPT),
        "--session-id", session_id,
        "--agent-name", AGENT_NAME
    ]

    if labels:
        cmd.extend(["--labels", ",".join(labels)])

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)

        # Parse the output to extract articles
        # The script prints a summary, we need to capture it
        # For now, we'll just indicate success
        # In a real implementation, we'd parse the actual article data

        # Note: news_monitor.py already logs, so we don't log here
        # We just need to parse its output

        # For this implementation, we'll call it again with a Python import
        # This is a simplification - in production, you'd parse the CLI output
        # or refactor news_monitor to be importable

        return []  # Placeholder - would parse from output or import NewsMonitor class

    except subprocess.CalledProcessError as e:
        log_error(session_id, f"Failed to fetch articles: {e.stderr}", agent_name=AGENT_NAME)
        return []


def exclude_articles(session_id: str, articles: List[Dict[str, Any]],
                     exclude_description: Optional[str]) -> List[Dict[str, Any]]:
    """Filter out articles based on exclude preferences (logged as thinking)"""
    if not exclude_description or not articles:
        return articles

    log_thinking(
        session_id,
        f"Applying exclusion criteria: {exclude_description}",
        agent_name=AGENT_NAME
    )

    # Note: Actual exclusion will be done by the LLM
    # This function just logs that exclusion should happen
    # The LLM will receive the exclude_description and filter accordingly

    log_thinking(
        session_id,
        f"Exclusion criteria will be applied by the model based on: {exclude_description}",
        agent_name=AGENT_NAME
    )

    return articles


def format_output(articles: List[Dict[str, Any]], exclude_description: Optional[str]) -> Dict[str, Any]:
    """Format output for the agent"""
    output = {
        "articles": articles,
        "has_new_articles": len(articles) > 0
    }

    if articles and exclude_description:
        output["exclude_preferences"] = exclude_description

    return output


def update_preferences(session_id: str,
                       labels: Optional[str] = None,
                       exclude: Optional[str] = None) -> bool:
    """Update preferences.md file"""
    try:
        # Read existing content
        existing_content = ""
        if PREFERENCES_FILE.exists():
            with open(PREFERENCES_FILE, 'r') as f:
                existing_content = f.read()

        # Build new content
        lines = []
        lines.append("# News Preferences")
        lines.append("")
        lines.append("## Labels")
        lines.append("")
        if labels is not None:
            lines.append(f"Labels: {labels}")
        else:
            # Keep existing labels if not updating
            if "Labels:" in existing_content:
                for line in existing_content.split('\n'):
                    if line.strip().startswith("Labels:"):
                        lines.append(line)
                        break
            else:
                lines.append("Labels: none")

        lines.append("")
        lines.append("## Exclude")
        lines.append("")
        if exclude is not None:
            lines.append(f"Exclude: {exclude}")
        else:
            # Keep existing exclude if not updating
            if "Exclude:" in existing_content:
                exclude_lines = []
                in_exclude = False
                for line in existing_content.split('\n'):
                    if line.strip().startswith("Exclude:"):
                        in_exclude = True
                        exclude_lines.append(line)
                    elif in_exclude:
                        if line.strip() and not line.strip().endswith(':'):
                            exclude_lines.append(line)
                        else:
                            break
                lines.extend(exclude_lines)
            else:
                lines.append("Exclude: none")

        content = '\n'.join(lines)

        # Write to file
        PREFERENCES_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(PREFERENCES_FILE, 'w') as f:
            f.write(content)

        log_tool_call(
            session_id,
            f"Write preferences file: {PREFERENCES_FILE.name}",
            result=f"Updated preferences\nLabels: {labels or 'unchanged'}\nExclude: {exclude or 'unchanged'}",
            agent_name=AGENT_NAME
        )

        return True

    except Exception as e:
        log_error(session_id, f"Failed to update preferences: {e}", agent_name=AGENT_NAME)
        return False


def post_comment(session_id: str, article_id: str, comment_text: str) -> Dict[str, Any]:
    """Post a comment on an article by delegating to news_monitor.py"""
    log_thinking(
        session_id,
        f"Posting comment on article {article_id}: {comment_text}",
        agent_name=AGENT_NAME
    )

    cmd = [
        sys.executable,
        str(NEWS_MONITOR_SCRIPT),
        "--session-id", session_id,
        "--agent-name", AGENT_NAME,
        "--post-comment", article_id, comment_text
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)

        # Pass through the output from news_monitor.py
        if result.stdout:
            print(result.stdout, end='')

        return {"success": True}

    except subprocess.CalledProcessError as e:
        log_error(session_id, f"Failed to post comment: {e.stderr}", agent_name=AGENT_NAME)
        if e.stderr:
            print(e.stderr, file=sys.stderr)
        return {"success": False, "error": str(e)}


def update_memory(session_id: str, article_id: str, summary: Optional[str] = None) -> bool:
    """Update memory with the most recent article ID and log final summary"""
    try:
        log_thinking(
            session_id,
            f"Updating memory with most recent article {article_id}",
            agent_name=AGENT_NAME
        )

        # Update memory using NewsMonitor
        monitor = NewsMonitor(session_id=session_id, agent_name=AGENT_NAME)
        monitor.save_memory(article_id, agent_name=AGENT_NAME, labels=None)

        # Log final summary if provided
        if summary:
            log_output(session_id, summary, agent_name=AGENT_NAME)

        return True

    except Exception as e:
        log_error(session_id, f"Failed to update memory: {e}", agent_name=AGENT_NAME)
        return False


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="News Retriever Agent",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Retrieve new articles
  python news_retriever.py --session-id SESSION_ID

  # Update preferences
  python news_retriever.py --session-id SESSION_ID \
    --update-labels "topic:AI,company:Red Hat"

  python news_retriever.py --session-id SESSION_ID \
    --update-exclude "Articles about quarterly earnings or stock prices"

  # Post a comment
  python news_retriever.py --session-id SESSION_ID \
    --post-comment ARTICLE_ID "Great article!"
        """
    )

    parser.add_argument(
        '--session-id',
        metavar='SESSION_ID',
        help='Session ID for logging (auto-generated if not provided)'
    )

    parser.add_argument(
        '--update-labels',
        metavar='LABELS',
        help='Update label preferences (comma-separated or "none")'
    )

    parser.add_argument(
        '--update-exclude',
        metavar='DESCRIPTION',
        help='Update exclusion preferences'
    )

    parser.add_argument(
        '--post-comment',
        nargs=2,
        metavar=('ARTICLE_ID', 'COMMENT_TEXT'),
        help='Post a comment on an article'
    )

    parser.add_argument(
        '--update-memory',
        metavar='ARTICLE_ID',
        help='Update memory with the most recent article ID'
    )

    parser.add_argument(
        '--summary',
        metavar='SUMMARY',
        help='Summary to log as final OUTPUT (use with --update-memory)'
    )

    args = parser.parse_args()

    # Initialize session if not provided
    if not args.session_id:
        # Load first 15 lines of AGENTS.md as instruction
        agents_md_path = SCRIPT_DIR / "AGENTS.md"
        with open(agents_md_path, 'r', encoding='utf-8') as f:
            lines = [next(f) for _ in range(15)]
        instruction = ''.join(lines).rstrip()
        instruction += "\n\n... (rest of instructions truncated, see AGENTS.md for full details)"

        session_id = initialize(instruction, agent_name=AGENT_NAME)
    else:
        session_id = args.session_id

    try:
        # Handle memory update
        if args.update_memory:
            # Log Finalize phase before updating memory
            log_phase(session_id, "Finalize", agent_name=AGENT_NAME)

            article_id = args.update_memory
            summary = args.summary if args.summary else None
            success = update_memory(session_id, article_id, summary=summary)

            if success:
                print(json.dumps({"status": "memory_updated", "article_id": article_id}))
                return 0
            else:
                print(json.dumps({"status": "error", "message": "Failed to update memory"}))
                return 1

        # Handle comment posting
        if args.post_comment:
            article_id, comment_text = args.post_comment
            result = post_comment(session_id, article_id, comment_text)

            if result["success"]:
                print(json.dumps({"status": "comment_posted", "article_id": article_id}))
                return 0
            else:
                print(json.dumps({"status": "error", "message": result.get("error", "Failed to post comment")}))
                return 1

        # Handle preference updates
        if args.update_labels is not None or args.update_exclude is not None:
            labels_value = args.update_labels if args.update_labels else None
            if labels_value == "none":
                labels_value = ""

            exclude_value = args.update_exclude if args.update_exclude else None
            if exclude_value == "none":
                exclude_value = ""

            success = update_preferences(
                session_id,
                labels=labels_value,
                exclude=exclude_value
            )

            if success:
                print(json.dumps({"status": "preferences_updated"}))
                return 0
            else:
                print(json.dumps({"status": "error", "message": "Failed to update preferences"}))
                return 1

        # Retrieve articles
        # Log phase: Fetch News (only when actually fetching, not for update-memory/post-comment/update-preferences)
        log_phase(session_id, "Fetch News", agent_name=AGENT_NAME)

        # 1. Read preferences
        prefs = read_preferences(session_id)

        # 2. Fetch articles using NewsMonitor
        monitor = NewsMonitor(session_id=session_id, agent_name=AGENT_NAME)
        result = monitor.run_monitoring(
            labels=prefs["labels"],
            max_results=100,  # Increased for demos with initial data loads
            agent_name=AGENT_NAME
        )

        # 3. Build output
        output_data = {
            "status": "success",
            "session_id": session_id,
            "articles": result["articles"],
            "count": len(result["articles"])
        }

        if prefs["exclude_description"]:
            output_data["exclude_preferences"] = prefs["exclude_description"]
            log_thinking(
                session_id,
                f"Exclusion criteria to apply: {prefs['exclude_description']}",
                agent_name=AGENT_NAME
            )

        print(json.dumps(output_data, indent=2))
        return 0

    except Exception as e:
        log_error(session_id, f"Unexpected error: {e}", agent_name=AGENT_NAME)
        print(json.dumps({"status": "error", "message": str(e)}))
        return 1


if __name__ == "__main__":
    sys.exit(main())
