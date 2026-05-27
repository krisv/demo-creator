# Payment Reconciliation Agent

Two specialized agents working together to reconcile payments and invoices.

## Agent Names

- **Payment Agent** - Reconciles open payments against invoices
- **Update Agent** - Processes news updates to add new payments and invoices

Use these exact names for logging and memory operations.

## Scenario

A finance department receives payments and issues invoices daily. The system needs to:
1. Match incoming payments to their corresponding invoices
2. Track which payments are fully matched, partially matched, or unknown
3. Process updates from external systems (news service) to add new transactions

## Core Context Files

The agent maintains CSV files in the `data/` folder:

- **`payments.csv`** - All payment records
  - Columns: payment_id, invoice_id, customer_name, amount, payment_date, status, notes
  - Status values: OPEN, MATCHED, PARTIAL, UNKNOWN
  
- **`invoices.csv`** - All invoice records
  - Columns: invoice_id, customer_name, amount, issue_date, due_date, status, notes
  - Status values: UNPAID, PAID, PARTIAL

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

### When Asked: "Process new updates" - Update Agent

**Workflow:**

1. **Fetch updates** using news_retriever.py
   ```bash
   python news_retriever.py
   ```
   **CRITICAL:** Capture the `session_id` from JSON output - use it for ALL logging.

2. **Read current context** (Phase: Read Context)
   ```bash
   python .claude/skills/log/log.py --session-id SESSION_ID --phase "Read Context" --thinking "Reading current payments and invoices" --agent-name "Update Agent"
   ```
   - Read `data/payments.csv`
   - Read `data/invoices.csv`

3. **Analyze updates** (Phase: Analyze)
   ```bash
   python .claude/skills/log/log.py --session-id SESSION_ID --phase "Analyze" --thinking "Analyzing news updates for new transactions" --agent-name "Update Agent"
   ```

   For each news item, determine:
   - Is this a new payment? (look for payment references, amounts paid, payment dates)
   - Is this a new invoice? (look for invoice numbers, amounts billed, due dates)
   - Extract: payment_id/invoice_id, customer_name, amount, dates

4. **Update CSV files** (Phase: Update Files)
   ```bash
   python .claude/skills/log/log.py --session-id SESSION_ID --phase "Update Files" --thinking "Adding new transactions to CSV files" --agent-name "Update Agent"
   ```

   - For new payments: Append to `payments.csv` with status=OPEN
   - For new invoices: Append to `invoices.csv` with status=UNPAID
   - Log each file update:
   ```bash
   python .claude/skills/log/log.py --session-id SESSION_ID --tool-call "Write data/payments.csv" --result "Added N payments" --agent-name "Update Agent"
   python .claude/skills/log/log.py --session-id SESSION_ID --tool-call "Write data/invoices.csv" --result "Added N invoices" --agent-name "Update Agent"
   ```

5. **Generate overview**

   Show to user:
   - Number of new payments added
   - Number of new invoices added
   - List of new payment IDs and invoice IDs

6. **Update memory** with latest article ID (starts Finalize phase)
   ```bash
   python news_retriever.py --update-memory MOST_RECENT_ARTICLE_ID --session-id SESSION_ID
   ```

7. **Log final output**
   ```bash
   python .claude/skills/log/log.py --session-id SESSION_ID --output "Added N payments and M invoices: [details]" --agent-name "Update Agent"
   ```

8. **Ask about uploading to Agent Inbox**

   Ask the user: "Would you like to upload the log to the Agent Inbox for review?"
   
   If yes:
   ```bash
   python .claude/skills/agent-inbox/log_task.py --log-file logs/Update\ Agent-SESSION_ID.log --title "Brief description of work completed" --agent-id UpdateAgent
   ```
   
   Note: The agent-id "UpdateAgent" will automatically use the name "Update Agent" and description from .agentinbox

### When Asked: "Reconcile payments" - Payment Agent

**Workflow:**

1. **Start new session** (Phase: Initialize)
   ```bash
   python .claude/skills/log/log.py --phase "Initialize" --thinking "Starting payment reconciliation" --agent-name "Payment Agent"
   ```
   Capture the session_id from output.

2. **Read current data** (Phase: Read Context)
   ```bash
   python .claude/skills/log/log.py --session-id SESSION_ID --phase "Read Context" --thinking "Reading payments and invoices for reconciliation" --agent-name "Payment Agent"
   ```
   - Read `data/payments.csv`
   - Read `data/invoices.csv`

3. **Process each OPEN payment** (Phase: Reconcile)
   ```bash
   python .claude/skills/log/log.py --session-id SESSION_ID --phase "Reconcile" --thinking "Processing OPEN payments" --agent-name "Payment Agent"
   ```

   For each payment with status=OPEN:
   
   a. **Find matching invoice:**
      - Primary match: payment.invoice_id == invoice.invoice_id
      - Verify: payment.customer_name matches invoice.customer_name (case-insensitive)
      - Verify: invoice.status == UNPAID (or PARTIAL for partial matches)
   
   b. **Compare amounts:**
      - If payment.amount == invoice.amount → MATCHED (full match)
      - If payment.amount < invoice.amount → PARTIAL (partial payment)
      - If payment.amount > invoice.amount → Log warning, mark UNKNOWN
   
   c. **If no invoice found or customer name mismatch:**
      - Status → UNKNOWN
      - Note the reason in payment.notes
   
   d. **Log each decision:**
      ```bash
      python .claude/skills/log/log.py --session-id SESSION_ID --thinking "Payment [ID]: [MATCHED/PARTIAL/UNKNOWN] - Reason: [why]" --agent-name "Payment Agent"
      ```

4. **Update payments.csv** (Phase: Update Files)
   ```bash
   python .claude/skills/log/log.py --session-id SESSION_ID --phase "Update Files" --thinking "Updating payment and invoice statuses" --agent-name "Payment Agent"
   ```
   - Update status column for processed payments
   - Add notes explaining the reconciliation result
   - Log the update:
   ```bash
   python .claude/skills/log/log.py --session-id SESSION_ID --tool-call "Write data/payments.csv" --result "Updated N payment statuses" --agent-name "Payment Agent"
   ```

5. **Update invoices.csv**
   - For MATCHED payments: Update invoice.status to PAID
   - For PARTIAL payments: Update invoice.status to PARTIAL, add note with remaining amount
   - Log the update:
   ```bash
   python .claude/skills/log/log.py --session-id SESSION_ID --tool-call "Write data/invoices.csv" --result "Updated N invoice statuses" --agent-name "Payment Agent"
   ```

6. **Generate overview and identify recommended actions**

   Show to user:
   - Total payments processed
   - Breakdown: X matched, Y partial, Z unknown
   - List of matched payment-invoice pairs
   - List of unknown payments requiring manual review
   
   Recommended actions:
   - Flag UNKNOWN payments for manual review
   - Suggest contacting customers for PARTIAL payments
   - Highlight any suspicious patterns (amount mismatches, missing invoices)

7. **Log output**
   ```bash
   python .claude/skills/log/log.py --session-id SESSION_ID --output "Reconciliation complete: X matched, Y partial, Z unknown" --agent-name "Payment Agent"
   ```

8. **Ask about uploading to Agent Inbox**

   Ask the user: "Would you like to upload the log to the Agent Inbox for review?"
   
   If yes:
   ```bash
   python .claude/skills/agent-inbox/log_task.py --log-file logs/Payment\ Agent-SESSION_ID.log --title "Brief description of reconciliation results" --agent-id PaymentAgent
   ```
   
   Note: The agent-id "PaymentAgent" will automatically use the name "Payment Agent" and description from .agentinbox

### Optional: Post Comments on Updates

```bash
python news_retriever.py --post-comment ARTICLE_ID 'Comment text' --session-id SESSION_ID
```

## Processing Guidelines

**Update Agent:**
- Extract transaction details carefully from news text
- Use reasonable defaults if dates not specified
- Always set initial status (OPEN for payments, UNPAID for invoices)
- Generate unique IDs if not provided (e.g., PAY-001, INV-001)

**Payment Agent:**
- ALWAYS log your reasoning for each payment status decision
- Check invoice_id first, then verify customer_name and amount
- Be strict about matches - if anything doesn't align, mark as UNKNOWN
- Amount comparisons should be exact decimal matches
- Document all assumptions in the notes field

## Notes

- **Structured updates:** Extract meaningful information from news items
- **Stay grounded:** Only update context files when warranted
- **Always log:** Use session_id from news retrieval for all operations
- **Always update memory:** End every update session by saving latest article ID
- **Show progress:** Always generate overview after processing updates
