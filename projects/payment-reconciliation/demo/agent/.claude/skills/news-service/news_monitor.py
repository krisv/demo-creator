#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Red Hat News Monitoring Script

Usage:
    python news_monitor.py --session-id SESSION_ID
    python news_monitor.py --session-id SESSION_ID --post-comment ARTICLE_ID "Comment"
    python news_monitor.py --update-memory ARTICLE_ID
"""

import argparse
import json
import logging
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Any, Optional
import urllib.request
import urllib.error
from urllib.parse import urljoin

# Set UTF-8 encoding for stdout/stderr on Windows
if sys.platform == 'win32':
    import codecs
    if hasattr(sys.stdout, 'buffer'):
        sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')
    if hasattr(sys.stderr, 'buffer'):
        sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, 'strict')

# Add log skill to path
SCRIPT_DIR = Path(__file__).parent
LOG_SKILL_DIR = SCRIPT_DIR.parent / "log"
sys.path.insert(0, str(LOG_SKILL_DIR))

from log import log_tool_call, log_thinking, log_output, log_error


# Configuration
# File paths (relative to project root)
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent
MEMORY_FILE = PROJECT_ROOT / "article_memory.json"

# Read news service configuration from .newsservice file
# This allows demos to use different URLs/ports and agent names
_newsservice_file = PROJECT_ROOT / ".newsservice"
if not _newsservice_file.exists():
    print(f"[ERROR] Missing required .newsservice configuration file at: {_newsservice_file}", file=sys.stderr)
    print(f"[ERROR] Create a .newsservice file with the following JSON format:", file=sys.stderr)
    print(f'[ERROR]   {{"url": "http://localhost:8080", "agent_name": "MyAgent"}}', file=sys.stderr)
    sys.exit(1)

try:
    _config = json.loads(_newsservice_file.read_text())
    NEWS_SERVICE_BASE_URL = _config.get("url")
    DEFAULT_AGENT_NAME = _config.get("agent_name", "MyAgent")

    if not NEWS_SERVICE_BASE_URL:
        print(f"[ERROR] Missing required 'url' field in .newsservice file", file=sys.stderr)
        sys.exit(1)

    if not NEWS_SERVICE_BASE_URL.endswith("/"):
        NEWS_SERVICE_BASE_URL += "/"
except json.JSONDecodeError as e:
    print(f"[ERROR] Invalid JSON in .newsservice file: {e}", file=sys.stderr)
    print(f"[ERROR] Expected format: {{'url': 'http://localhost:8080', 'agent_name': 'MyAgent'}}", file=sys.stderr)
    sys.exit(1)


class NewsMonitor:
    """News monitoring and commenting system"""

    def __init__(self, verbose: bool = False, session_id: Optional[str] = None, agent_name: Optional[str] = None):
        """Initialize the news monitor"""
        self.verbose = verbose
        self.session_id = session_id or datetime.now().strftime("%Y%m%d-%H%M%S")
        self.agent_name = agent_name or DEFAULT_AGENT_NAME
        self.setup_logging()

    def setup_logging(self):
        """Configure logging"""
        level = logging.DEBUG if self.verbose else logging.INFO
        logging.basicConfig(
            level=level,
            format='%(levelname)s: %(message)s'
        )
        self.logger = logging.getLogger(__name__)

    def log_step(self, step_type: str, message: str, result: Optional[str] = None):
        """Log an execution step to both console and log file"""
        # Map step types to appropriate log functions
        if step_type == "TOOL CALL":
            log_tool_call(self.session_id, message, result=result, agent_name=self.agent_name)
        elif step_type == "THINKING":
            log_thinking(self.session_id, message, agent_name=self.agent_name)
        elif step_type == "OUTPUT":
            log_output(self.session_id, message, agent_name=self.agent_name)
        elif step_type == "ERROR":
            log_error(self.session_id, message, agent_name=self.agent_name)

        if self.verbose:
            self.logger.debug(f"{step_type}: {message}")

    def fetch_news(self, labels: Optional[List[str]] = None, max_results: int = 100, last_seen: Optional[str] = None) -> List[Dict[str, Any]]:
        """Fetch news articles from the service with optional filtering"""
        url = f"{NEWS_SERVICE_BASE_URL}/api/news"

        # Build query parameters
        params = []
        if labels:
            params.append(f"labels={','.join(labels)}")
        if max_results:
            params.append(f"max_results={max_results}")
        if last_seen:
            params.append(f"last_seen={last_seen}")

        if params:
            url += "?" + "&".join(params)

        try:
            with urllib.request.urlopen(url, timeout=10) as response:
                articles = json.loads(response.read().decode())

                # Log result with truncated response
                result_preview = json.dumps(articles, indent=2)
                result_lines = result_preview.split('\n')
                if len(result_lines) > 10:
                    result_preview = '\n'.join(result_lines[:10]) + f"\n... ({len(result_lines) - 10} more lines)"

                self.log_step("TOOL CALL", f"GET {url}", result=f"Retrieved {len(articles)} articles\n{result_preview}")
                return articles
        except urllib.error.URLError as e:
            self.log_step("ERROR", f"Failed to fetch news: {e}")
            raise
        except json.JSONDecodeError as e:
            self.log_step("ERROR", f"Invalid JSON response: {e}")
            raise

    def load_memory(self) -> Optional[str]:
        """Load last seen article ID from memory file"""
        if not MEMORY_FILE.exists():
            self.log_step("TOOL CALL", f"Read memory file: article_memory.json", result="Memory file does not exist, no last seen article")
            return None

        try:
            with open(MEMORY_FILE, 'r') as f:
                memory = json.load(f)
                last_seen = memory.get('last_seen_article_id')
                self.log_step("TOOL CALL", f"Read memory file: article_memory.json", result=f"Last seen article: {last_seen or 'none'}")
                return last_seen
        except (json.JSONDecodeError, IOError) as e:
            self.log_step("ERROR", f"Failed to read memory file: {e}")
            return None

    def save_memory(self, last_article_id: str, agent_name: Optional[str] = None, labels: Optional[List[str]] = None):
        """Save last seen article ID to memory file"""
        try:
            MEMORY_FILE.parent.mkdir(parents=True, exist_ok=True)
            memory = {"last_seen_article_id": last_article_id}
            if labels:
                memory["labels"] = labels
            with open(MEMORY_FILE, 'w') as f:
                json.dump(memory, f, indent=2)
            self.log_step("TOOL CALL", f"Write memory file: article_memory.json", result=f"Saved last seen article ID: {last_article_id}")
        except IOError as e:
            self.log_step("ERROR", f"Failed to write memory file: {e}")
            raise


    def post_comment(self, article_id: str, comment_content: str, commenter_name: str = "Claude") -> Dict[str, Any]:
        """Post a comment on a news article"""
        url = f"{NEWS_SERVICE_BASE_URL}/api/news/{article_id}/comments"

        comment_data = {
            "name": commenter_name,
            "content": comment_content
        }

        try:
            # Log the full request
            request_data = json.dumps(comment_data, indent=2)

            data = json.dumps(comment_data).encode('utf-8')
            req = urllib.request.Request(
                url,
                data=data,
                headers={'Content-Type': 'application/json'},
                method='POST'
            )

            with urllib.request.urlopen(req, timeout=10) as response:
                result = json.loads(response.read().decode())

                # Log result with truncated response
                result_preview = json.dumps(result, indent=2)
                result_lines = result_preview.split('\n')
                if len(result_lines) > 10:
                    result_preview = '\n'.join(result_lines[:10]) + f"\n... ({len(result_lines) - 10} more lines)"

                comment_id = result.get('id')
                self.log_step("TOOL CALL", f"POST {url}\nPayload:\n{request_data}",
                             result=f"Comment posted successfully\nComment ID: {comment_id}\nResponse:\n{result_preview}")
                return result
        except urllib.error.HTTPError as e:
            error_msg = e.read().decode() if e.fp else str(e)
            self.log_step("ERROR", f"Failed to post comment: {e.code} - {error_msg}")
            raise
        except urllib.error.URLError as e:
            self.log_step("ERROR", f"Network error posting comment: {e}")
            raise

    def format_article_summary(self, articles: List[Dict[str, Any]]) -> str:
        """Format articles as a readable summary"""
        lines = []
        lines.append(f"Articles retrieved: {len(articles)}")
        lines.append("")

        if not articles:
            lines.append("No new articles found.")
            return "\n".join(lines)

        lines.append("ARTICLES:")
        lines.append("=" * 80)

        for i, article in enumerate(articles, 1):
            lines.append(f"\n[{i}] {article.get('title', 'Untitled')}")
            lines.append(f"    ID: {article.get('id')}")
            lines.append(f"    Published: {article.get('timestamp', 'Unknown')}")

            # Show content preview (first 200 chars)
            content = article.get('content', '')
            if len(content) > 200:
                content = content[:200] + "..."
            lines.append(f"    Content: {content}")

            # Show existing comments
            comments = article.get('comments', [])
            if comments:
                lines.append(f"    Comments ({len(comments)}):")
                for comment in comments[:3]:  # Show max 3 comments
                    lines.append(f"      - {comment.get('name')}: {comment.get('content')[:100]}")
            else:
                lines.append("    Comments: None")

            lines.append("")

        return "\n".join(lines)

    def run_monitoring(self, labels: Optional[List[str]] = None, max_results: int = 100, agent_name: Optional[str] = None) -> Dict[str, Any]:
        """Run the news monitoring workflow"""
        if agent_name:
            self.agent_name = agent_name
        self.log_step("INPUT", "Automated news monitoring execution")

        # Load memory to get last seen article
        self.log_step("THINKING", "Loading last seen article from memory")
        last_seen = self.load_memory()

        # Fetch news (server-side filtering with last_seen)
        if labels:
            self.log_step("THINKING", f"Fetching latest news articles filtered by labels: {', '.join(labels)}")
        else:
            self.log_step("THINKING", "Fetching latest news articles")

        if last_seen:
            self.log_step("THINKING", f"Requesting articles newer than: {last_seen}")

        articles = self.fetch_news(labels=labels, max_results=max_results, last_seen=last_seen)

        # Generate summary (all returned articles are new)
        summary = self.format_article_summary(articles)

        return {
            "articles": articles,
            "summary": summary
        }

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Red Hat News Monitoring Script",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Example workflow:
  python news_monitor.py --session-id my-session
  python news_monitor.py --session-id my-session --post-comment ARTICLE_ID "Comment"
  python news_monitor.py --update-memory ARTICLE_ID
        """
    )

    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Enable verbose logging'
    )

    parser.add_argument(
        '--session-id',
        metavar='SESSION_ID',
        help='Session ID to group operations into one log file'
    )

    parser.add_argument(
        '--agent-name',
        metavar='AGENT_NAME',
        help=f'Agent name for logging (default: from .newsservice file or "MyAgent")'
    )

    parser.add_argument(
        '--update-memory',
        metavar='ARTICLE_ID',
        help='Update memory with most recent article ID'
    )

    parser.add_argument(
        '--post-comment',
        nargs=2,
        metavar=('ARTICLE_ID', 'COMMENT'),
        help='Post a comment on a specific article'
    )

    parser.add_argument(
        '--labels',
        metavar='LABELS',
        help='Comma-separated list of labels to filter by (e.g., "AI,Red Hat")'
    )

    parser.add_argument(
        '--max-results',
        type=int,
        default=100,
        metavar='N',
        help='Maximum number of results to return (default: 100, max: 100)'
    )

    args = parser.parse_args()

    # Handle update-memory separately (simple operation)
    if args.update_memory:
        last_seen_id = args.update_memory
        try:
            print(f"Updating memory with last seen article: {last_seen_id}")
            MEMORY_FILE.parent.mkdir(parents=True, exist_ok=True)
            memory = {"last_seen_article_id": last_seen_id}
            with open(MEMORY_FILE, 'w') as f:
                json.dump(memory, f, indent=2)
            print(f"[OK] Updated last seen article ID: {last_seen_id}")
            return 0
        except Exception as e:
            print(f"[ERROR] Failed to update memory: {e}", file=sys.stderr)
            return 1

    # Initialize monitor
    monitor = NewsMonitor(verbose=args.verbose, session_id=args.session_id, agent_name=args.agent_name)

    try:
        # Handle comment posting
        if args.post_comment:
            article_id, comment = args.post_comment
            monitor.log_step("INPUT", f"Post comment on article {article_id}")
            print(f"Posting comment on article {article_id}...")

            result = monitor.post_comment(article_id, comment, commenter_name=monitor.agent_name)
            print(f"[OK] Comment posted successfully!")
            print(f"  Comment ID: {result.get('id')}")
            print(f"  Timestamp: {result.get('timestamp')}")

            # Log output
            monitor.log_step("OUTPUT", f"Posted comment on article {article_id}, Comment ID: {result.get('id')}")

            print(f"[OK] Comment posted successfully")
            print(f"[INFO] Session ID: {monitor.session_id}")

            return 0

        # Run monitoring
        # Parse labels
        labels = None
        if args.labels:
            labels = [label.strip() for label in args.labels.split(',')]

        # Validate max_results
        max_results = args.max_results
        if max_results < 1:
            max_results = 100
        if max_results > 100:
            max_results = 100

        print("Fetching Red Hat news...")
        result = monitor.run_monitoring(labels=labels, max_results=max_results)

        # Display summary
        print("\n" + "=" * 80)
        print(result['summary'])
        print("=" * 80)
        print(f"\n[INFO] Session ID: {monitor.session_id}")

        return 0

    except Exception as e:
        print(f"\n[ERROR] {e}", file=sys.stderr)
        if args.verbose:
            import traceback
            traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
