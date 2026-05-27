---
name: demo-creator
description: Create complete end-to-end demo environments for news service instances
---

# Demo Creator

Create complete demos with news service, agent, and dashboard.

## When to Use

User asks to:
- Create a new demo
- Set up a demo environment
- Build a complete demo project

## Guided Process

### Phase 1: Understanding

**Ask the user:**
1. What's the scenario/use case?
2. What kind of information will the agent track?
3. What should the agent do with updates?

**Examples:**
- Budget approval agent
- Feature tracking for product team
- Invoice reconciliation
- Customer feedback analysis

### Phase 2: Design

Based on their answer, design:

**1. Data structure** - What files in `data/`?
```
data/
  main_tracking.md       # Primary tracking file
  categories.md          # Categorized items
  context.md             # Background info
  subdirs/               # Per-item tracking if needed
```

**2. News content** - What types of updates?
- What labels make sense?
- How much initial data (1-2 weeks)?
- What progression to show?

**3. Agent behavior** - What should agent do?
- How to process updates?
- What to track/update?
- What recommendations to make?

### Phase 3: Create Scaffolding

```bash
cd .claude/skills/demo-creator
./create-demo.sh <project-name>
```

Ports are auto-generated randomly to avoid conflicts. You can optionally specify ports: `./create-demo.sh <project-name> [news-service-port] [news-db-port] [inbox-port] [inbox-db-port]`

This creates:
```
projects/<project-name>/demo/
  news-service/          # News service instance
    config.yaml, schema.sql
    start.sh, stop.sh, status.sh
    backup.sh, clean.sh
    generate-initial-data.sh
    generate-update-data.sh
  agent-inbox/           # Agent inbox instance
    schema.sql
    start.sh, stop.sh, status.sh
    backup.sh, clean.sh
  agent/                 # Agent project
    CLAUDE.md
    AGENTS.md            # ← Customize this
    dashboard.html       # ← Customize this
    data/                # ← Create structure
    .newsservice         # ← Points to news-service
    .agentinbox          # ← Points to agent-inbox
  README.md
```

### Phase 4: Customize Templates

**1. Set agent name:**

Edit `agent/.agentname` with an appropriate name for the scenario (e.g., "Payment Reconciliation Agent", "Budget Tracker", etc.)

**2. Edit `agent/AGENTS.md`:**

Read the template file - it has placeholders like `{AGENT_NAME}`, `{SCENARIO_DESCRIPTION}`, etc.

Replace all `{PLACEHOLDERS}` with scenario-specific content:
- Agent name and description
- What data files will exist
- How to process updates
- What to show in overview
- What actions to recommend

**3. Create data structure:**

Based on what you defined in AGENTS.md, create the actual files in `agent/data/`:

```bash
cd agent/data
touch main_tracking.md
mkdir subdirs  # if needed
```

Initialize files with headers/structure so agent knows the format.

**4. Customize `agent/dashboard.html`:**

Read the template - it shows a basic layout with placeholder metrics.

Add JavaScript to:
- Load data from `data/` files using fetch()
- Parse CSV/JSON/Markdown
- Display metrics in stat cards
- Auto-refresh every 10 seconds

Example:
```javascript
async function loadPayments() {
    const response = await fetch('data/payments.csv');
    const text = await response.text();
    const lines = text.trim().split('\n');
    const openCount = lines.filter(l => l.includes(',OPEN,')).length;
    document.querySelector('.value').textContent = openCount;
}
setInterval(loadPayments, 10000);
loadPayments();
```

**5. Edit `news-service/generate-initial-data.sh`:**

Read the template - it has a `post_news` helper function ready to use.

Add 10-20 realistic news items using the helper. Create a story showing progression over 1-2 weeks (initial baseline data).

**6. Edit `news-service/generate-update-data.sh`:**

Read the template - it has the same `post_news` helper function.

Add follow-up news items (Week 3+) that show progression:
- Updates on existing items
- New transactions/events
- Scenarios requiring agent action

This script will be run later to demonstrate the agent handling new updates.

**7. Validate the setup:**

```bash
cd .claude/skills/demo-creator
./validate-demo.sh <project-name>
```

This checks:
- ✓ All required files exist
- ✓ Configuration files are valid
- ✓ Scripts are executable
- ⚠ Optional files (warns if missing)

Fix any errors before proceeding.

**8. Initialize git repository:**

```bash
cd <demo-directory>/agent
git init
git add .
git commit -m "Initial demo setup - customized templates and data structure"
```

This captures the baseline before running the agent.

### Phase 5: Run the Demo

**1. Start services and populate:**
```bash
cd news-service
./start.sh
./generate-initial-data.sh

cd ../agent-inbox
./start.sh
```

**2. Process initial data:**
```bash
cd ../agent
code .  # Open in Claude Code
```

In Claude Code: "Process new updates"

**3. Verify state:**
- Check `data/` files were created/updated
- View dashboard if customized
- Review session log in `logs/`

**4. Commit agent's work:**

```bash
git add .
git commit -m "Agent processed initial data - baseline state"
```

This captures what the agent created from the initial news updates.

**5. Generate follow-up updates:**

Run the update data script you customized earlier:
```bash
cd ../news-service
./generate-update-data.sh
```

**6. Reprocess:**

In Claude Code: "Process new updates"

Agent should:
- Update existing context files
- Show what changed
- Make recommendations

**7. Commit progression:**

```bash
cd ../agent
git add .
git commit -m "Agent processed update data - showed progression and handled edge cases"
```

This captures how the agent handled new scenarios.

### Phase 6: Polish

1. **Verify dashboard** updates automatically
2. **Clean up** context files for clarity
3. **Test end-to-end** - does story make sense?
4. **Document** in demo README.md

## Common Patterns

### Budget/Approval Agent
- Track: Per-person budgets, pending requests
- Updates: Approval requests with amounts
- Agent: Check limits, recommend approve/deny

### Feature Tracking
- Track: Features, customer feedback, team status
- Updates: Sprint progress, feedback, decisions
- Agent: Update roadmap, identify themes

### Reconciliation
- Track: Expected items, actual items, discrepancies
- Updates: New records to match
- Agent: Match items, flag mismatches

## Management Commands

**News Service:**
```bash
cd news-service
./status.sh        # Check containers
./stop.sh          # Stop (data preserved)
./start.sh         # Restart
./backup.sh        # Backup database
./restore.sh FILE  # Restore from backup
./clean.sh         # Reset (deletes data)
```

**Agent Inbox:**
```bash
cd agent-inbox
./status.sh        # Check containers
./stop.sh          # Stop
./start.sh         # Restart
./backup.sh        # Backup database
./restore.sh FILE  # Restore from backup
./clean.sh         # Reset (deletes data)
```

**Dashboard:**
```bash
cd agent
./serve-dashboard.sh  # Start HTTP server
# Open: http://localhost:8000/dashboard.html
```

## Troubleshooting

**Validation:**
```bash
cd .claude/skills/demo-creator
./validate-demo.sh <project-name>
```

**Service not accessible:**
```bash
cd news-service
./status.sh
curl http://localhost:<port>/api/news
```

**Agent can't connect:**
```bash
cd agent
cat .newsservice  # Should show URL
cat .agentinbox   # Should show URL
```

**No data:**
```bash
cd news-service
./generate-initial-data.sh  # Run again
```

## Tips

1. **Start simple** - Minimal data structure first
2. **Test early** - Run through workflow before customizing
3. **Realistic data** - Makes demo believable
4. **Tell a story** - Initial state → Updates → Actions
5. **Use dashboard** - Visual updates are impressive
6. **Log everything** - Session logs show reasoning
7. **Git checkpoint** - Commit before adding updates
