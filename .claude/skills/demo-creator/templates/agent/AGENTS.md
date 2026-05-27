# {AGENT_NAME} Agent

{AGENT_DESCRIPTION}

## Agent Name

**{AGENT_NAME}** - Use this exact name for logging and memory operations.

## Scenario

{SCENARIO_DESCRIPTION}

## Core Context Files

The agent maintains context files in the `data/` folder:

{DATA_STRUCTURE}

## Session-Based Logging

**CRITICAL:** All operations MUST use session-based logging.

### Capture Session ID

When you run `news_retriever.py`, capture the session_id from the JSON output:

```json
{
  "status": "success",
  "session_id": "20260422-144502",
  ...
}
```

**Use this session_id for ALL subsequent logging in that interaction.**

### Log Your Work

Use the log.py command-line tool with the session_id from news retrieval.

**IMPORTANT:** Always include `--phase` with the current workflow phase when logging operations.

**Log phases with thinking:**
```bash
python .claude/skills/log/log.py --session-id SESSION_ID --phase "Phase Name" --thinking "Details..." --agent-name "{AGENT_NAME}"
```

**Log file updates:**
```bash
python .claude/skills/log/log.py --session-id SESSION_ID --tool-call "Write data/..." --result "Updated X" --agent-name "{AGENT_NAME}"
```

**Log final output:**
```bash
python .claude/skills/log/log.py --session-id SESSION_ID --output "Summary of work completed" --agent-name "{AGENT_NAME}"
```

## Instructions

### When Asked: "Process new updates" or "Get latest updates"

**Workflow:**

1. **Fetch updates** using news_retriever.py
   ```bash
   python news_retriever.py
   ```
   **CRITICAL:** Capture the `session_id` from JSON output - use it for ALL logging.

2. **Read current context** (Phase: Read Context)
   ```bash
   python .claude/skills/log/log.py --session-id SESSION_ID --phase "Read Context" --thinking "Reading current context files" --agent-name "{AGENT_NAME}"
   ```
   {CONTEXT_FILES_TO_READ}

3. **Analyze updates** (Phase: Analyze)
   ```bash
   python .claude/skills/log/log.py --session-id SESSION_ID --phase "Analyze" --thinking "Analyzing new updates for: {ANALYSIS_FOCUS}" --agent-name "{AGENT_NAME}"
   ```

   For each news item:
   {UPDATE_PROCESSING_RULES}

4. **Update context files as needed** (Phase: Update Files)
   ```bash
   python .claude/skills/log/log.py --session-id SESSION_ID --phase "Update Files" --thinking "Updating context files with new information" --agent-name "{AGENT_NAME}"
   ```

   {UPDATE_RULES}
   
   Log each file update:
   ```bash
   python .claude/skills/log/log.py --session-id SESSION_ID --tool-call "Write data/filename" --result "Description of changes" --agent-name "{AGENT_NAME}"
   ```

5. **Generate overview and identify recommended actions**

   After processing updates, create a summary showing:
   {OVERVIEW_CONTENT}

   Present this overview to the user in a clear, structured format.
   
   Based on the updates and current context, suggest:
   {ACTION_RECOMMENDATIONS}

6. **Update memory** with latest article ID (starts Finalize phase)
   ```bash
   python news_retriever.py --update-memory MOST_RECENT_ARTICLE_ID --session-id SESSION_ID
   ```

7. **Log final output**
   ```bash
   python .claude/skills/log/log.py --session-id SESSION_ID --output "Summary of work completed" --agent-name "{AGENT_NAME}"
   ```

8. **Ask about uploading to Agent Inbox**

   Ask the user: "Would you like to upload the log to the Agent Inbox for review?"
   
   If yes:
   ```bash
   python .claude/skills/agent-inbox/log_task.py --log-file logs/{AGENT_NAME}-SESSION_ID.log --title "Brief description of work completed"
   ```

### Optional: Post Comments on Updates

```bash
python news_retriever.py --post-comment ARTICLE_ID 'Comment text' --session-id SESSION_ID
```

## Processing Guidelines

{PROCESSING_GUIDELINES}

## Notes

- **Structured updates:** Extract meaningful information from news items
- **Stay grounded:** Only update context files when warranted
- **Always log:** Use session_id from news retrieval for all operations
- **Always update memory:** End every update session by saving latest article ID
- **Show progress:** Always generate overview after processing updates
