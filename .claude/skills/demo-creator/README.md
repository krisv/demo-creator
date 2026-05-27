# Demo Creator - Internal Design

This document covers internal design decisions not in Skill.md.

## Architecture

### Template-Based Generation

The skill uses a template directory approach instead of embedded heredocs:

**Why:**
- Separation of content from logic
- Easy to update templates without touching script
- Version control friendly (templates are just files)
- Reusable across multiple demos

**Structure:**
```
templates/
  news-service/    # News service instance templates
  agent/           # Agent project templates
  README.md        # Demo documentation template
```

### Placeholder Replacement

Templates use `{{PLACEHOLDER}}` syntax replaced by `sed`:

```bash
replace_placeholders() {
    sed -i "s|{{INSTANCE_NAME}}|$INSTANCE_NAME|g" "$file"
    sed -i "s|{{SERVICE_PORT}}|$SERVICE_PORT|g" "$file"
    # ... etc
}
```

**Placeholders:**
- `{{INSTANCE_NAME}}` - Instance identifier
- `{{PROJECT_NAME}}` - Project name
- `{{SERVICE_PORT}}` - HTTP port
- `{{DB_PORT}}` - PostgreSQL port
- `{{DB_USER}}` - Database username
- `{{DB_PASSWORD}}` - Generated password
- `{{API_KEY}}` - Generated API key
- `{{TIMESTAMP}}` - Creation timestamp

## Configuration File Strategy

### Why Multiple Config Files?

**News service** uses `config.yaml`:
- Service's own configuration
- Database connection settings
- Contains API key for service authentication

**Agent** uses `.newsservice` and `.agentinbox`:
- JSON format for easy parsing
- Points to service URLs
- Agent-specific settings
- Not committed to git

This separation allows:
- Service and agent to be independently configured
- Demo instances to run on different ports
- Agents to connect to any service instance

## Script Design

### create-demo.sh

**Design principles:**
- Copy templates, don't generate inline
- Single pass through templates
- Generate secrets once
- All placeholders replaced in one loop

**Generated secrets:**
```bash
DB_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(16))")
API_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
```

Falls back to `openssl` if Python not available.

### Folder Naming

**news-service/** instead of **instance/**:
- Clearer what it is
- Consistent with skill name
- Avoids generic "instance" term

## Dashboard Philosophy

Templates include minimal dashboard with Pico CSS:
- Encourages customization (not complete solution)
- Shows pattern for dynamic loading
- Small footprint (<100 lines)
- Uses CDN for Pico CSS (no local dependencies)

Real demos should replace with custom dashboard that loads their specific data files.

## Cross-Platform Compatibility

**Date handling:**
```bash
TODAY=$(date -u +"%Y-%m-%dT12:00:00Z")
```

Avoid date arithmetic (`date -d "2 days ago"`) - doesn't work on Git Bash for Windows.

**Path handling:**
- Use relative paths from `$SCRIPT_DIR`
- Use forward slashes (work on Windows in bash)
- Don't assume Unix-specific paths

**Permissions:**
- Explicitly `chmod +x` generated scripts
- Don't assume umask settings
