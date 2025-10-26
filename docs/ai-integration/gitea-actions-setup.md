# Gitea Actions Setup for AtomicQMS AI Assistant

## Overview

AtomicQMS integrates Claude AI as an intelligent assistant for quality management workflows. The AI assistant helps with document review, CAPA processing, change impact assessment, and compliance checking—all within your Pull Requests and Issues.

## Prerequisites

- AtomicQMS instance running (see [Quick Start](../guide/quick-start.md))
- Admin access to your AtomicQMS instance
- Anthropic API key ([get one here](https://console.anthropic.com/))
- Gitea Actions enabled (included in setup)

## Architecture

```
┌─────────────────────────────────────────────┐
│  AtomicQMS (Gitea)                          │
│  ┌────────────────────────────────────────┐ │
│  │  Pull Request / Issue                  │ │
│  │  ┌──────────────────────────────────┐  │ │
│  │  │  @qms-assistant trigger comment  │  │ │
│  │  └──────────────────────────────────┘  │ │
│  │              │                          │ │
│  │              ▼                          │ │
│  │  ┌──────────────────────────────────┐  │ │
│  │  │  Gitea Actions Runner            │  │ │
│  │  │  - Checks out code               │  │ │
│  │  │  - Runs claude-code-gitea-action │  │ │
│  │  │  - Loads QMS context             │  │ │
│  │  └──────────────────────────────────┘  │ │
│  │              │                          │ │
│  │              ▼                          │ │
│  │  ┌──────────────────────────────────┐  │ │
│  │  │  Claude API                      │  │ │
│  │  │  - Analyzes documents            │  │ │
│  │  │  - Provides QMS guidance         │  │ │
│  │  │  - Suggests improvements         │  │ │
│  │  └──────────────────────────────────┘  │ │
│  │              │                          │ │
│  │              ▼                          │ │
│  │  ┌──────────────────────────────────┐  │ │
│  │  │  Response posted as comment      │  │ │
│  │  └──────────────────────────────────┘  │ │
│  └────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

## Step 1: Enable Gitea Actions

Gitea Actions is already enabled in your AtomicQMS configuration (`gitea/gitea/conf/app.ini`):

```ini
[actions]
ENABLED = true
DEFAULT_ACTIONS_URL = github
```

Restart your container if this wasn't already configured:

```bash
docker compose restart
```

## Step 2: Set Up Actions Runner

### Option A: Docker Runner (Recommended)

Add the Gitea Actions Runner to your `docker-compose.yml`:

```yaml
services:
  # ... existing atomicqms service ...

  runner:
    image: gitea/act_runner:latest
    container_name: atomicqms-runner
    restart: unless-stopped
    depends_on:
      - server
    networks:
      - gitea
    volumes:
      - ./runner-data:/data
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - GITEA_INSTANCE_URL=http://server:3000
      - GITEA_RUNNER_REGISTRATION_TOKEN=${RUNNER_TOKEN}
```

### Option B: Host Runner

Install act_runner on your host:

```bash
# Download act_runner
wget https://dl.gitea.com/act_runner/0.2.11/act_runner-0.2.11-linux-amd64

# Make executable
chmod +x act_runner-0.2.11-linux-amd64
sudo mv act_runner-0.2.11-linux-amd64 /usr/local/bin/act_runner

# Register runner
act_runner register --instance http://localhost:3001 --token YOUR_REGISTRATION_TOKEN

# Run as service
act_runner daemon
```

## Step 3: Get Runner Registration Token

1. Log in to AtomicQMS web interface: http://localhost:3001
2. Navigate to **Site Administration** (gear icon) → **Actions** → **Runners**
3. Click **Create new Runner**
4. Copy the registration token
5. Use token in docker-compose.yml or during `act_runner register`

## Step 4: Configure Secrets

Add required secrets to your AtomicQMS instance:

### Via Web Interface

1. Navigate to your repository **Settings** → **Secrets**
2. Add the following secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `ANTHROPIC_API_KEY` | `sk-ant-...` | Your Claude API key |
| `GITEA_SERVER_URL` | `http://localhost:3001` | Public URL of your instance |

### Via CLI

```bash
# Using Gitea CLI (if available)
gitea admin secret create \
  --name ANTHROPIC_API_KEY \
  --value "sk-ant-api03-..." \
  --repo owner/repo
```

## Step 5: Test the Integration

1. Create a test repository in AtomicQMS
2. Create a test Pull Request or Issue
3. Add a comment: `@qms-assistant Please review this for compliance`
4. Watch the Actions tab for workflow execution
5. Claude will respond with a detailed review

### Example Test PR

```markdown
Title: Update SOP-001 Sample Processing

Description:
Added clarification to Section 4.2 regarding sample temperature requirements.

Changes:
- Specified temperature range: 2-8°C
- Added temperature monitoring requirements
- Updated related forms

Comment: @qms-assistant Please review this SOP update for compliance and completeness.
```

Expected response: Claude will analyze the changes, check for compliance requirements, suggest improvements, and flag any missing elements.

## Step 6: Verify Workflow Execution

Check that the workflow file is in place:

```bash
ls -la .gitea/workflows/
# Should show: claude-qms-assistant.yml
```

View workflow runs:
1. Go to repository → **Actions** tab
2. See execution logs and results
3. Debug any issues using logs

## Troubleshooting

### Runner Not Connecting

**Problem:** Runner shows as offline in Gitea

**Solutions:**
- Verify registration token is correct
- Check network connectivity between runner and Gitea
- Review runner logs: `docker logs atomicqms-runner`
- Ensure `GITEA_INSTANCE_URL` points to correct address

### Workflow Not Triggering

**Problem:** Comment with `@qms-assistant` doesn't trigger workflow

**Solutions:**
- Verify workflow file exists in `.gitea/workflows/`
- Check workflow syntax with YAML validator
- Ensure trigger conditions match event type
- Review Actions logs in Gitea UI

### API Authentication Fails

**Problem:** Claude API returns 401 Unauthorized

**Solutions:**
- Verify `ANTHROPIC_API_KEY` secret is set correctly
- Check API key is valid at https://console.anthropic.com/
- Ensure no extra whitespace in secret value
- Test API key with curl:

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":1024,"messages":[{"role":"user","content":"Hello"}]}'
```

### Docker Socket Permission Denied

**Problem:** Runner can't access Docker socket

**Solutions:**
- Add runner user to docker group
- Or run runner with appropriate permissions
- Check socket permissions: `ls -la /var/run/docker.sock`

## Security Considerations

### API Key Management

- **Never commit API keys** to repository
- Use repository secrets for sensitive data
- Rotate API keys regularly
- Use read-only keys when possible

### Tool Restrictions

The workflow limits Claude to safe operations:

```yaml
allowed_tools: 'Read,Edit,Grep,Glob'
disallowed_tools: 'Bash,WebSearch'
```

This prevents:
- Arbitrary command execution
- Network access beyond API calls
- File system modifications outside repo

### User Access Control

Control who can trigger the assistant:

```yaml
# Option 1: Require specific label
label_trigger: 'ai-review'

# Option 2: Restrict to specific users
# (Configure in Gitea branch protection rules)
```

### Audit Logging

All AI interactions are logged:
- Workflow execution logs in Actions tab
- Claude responses as PR/Issue comments
- Full audit trail in Git history

## Advanced Configuration

### Custom Trigger Phrases

Modify `.gitea/workflows/claude-qms-assistant.yml`:

```yaml
trigger_phrase: '@compliance-bot'  # or '@qms-ai', '@doc-review', etc.
```

### Self-Hosted Claude (Coming Soon)

For air-gapped or highly regulated environments:

```yaml
# Future support for local Claude models
use_local_model: true
model_endpoint: 'http://local-claude:8080'
```

### Multiple Assistants

Create specialized assistants for different workflows:

```yaml
# .gitea/workflows/claude-sop-review.yml
trigger_phrase: '@sop-reviewer'
prompt: 'You are an SOP review specialist...'

# .gitea/workflows/claude-capa-assistant.yml
trigger_phrase: '@capa-assistant'
prompt: 'You are a CAPA documentation expert...'
```

## Next Steps

- [QMS Workflows](./qms-workflows.md) - Learn QMS-specific use cases
- [Core Concepts](../guide/core-concepts.md) - Understand AtomicQMS architecture
- [Deployment Guide](../deployment/README.md) - Production deployment tips

## Support

For issues with:
- **Gitea Actions**: Check [Gitea Actions docs](https://docs.gitea.com/usage/actions/overview)
- **Claude Code**: See [claude-code-gitea-action](https://github.com/markwylde/claude-code-gitea-action)
- **AtomicQMS**: Open an issue in this repository

## References

- [Gitea Actions Documentation](https://docs.gitea.com/usage/actions/overview)
- [Claude API Documentation](https://docs.anthropic.com/claude/reference/getting-started-with-the-api)
- [claude-code-gitea-action](https://github.com/markwylde/claude-code-gitea-action)
