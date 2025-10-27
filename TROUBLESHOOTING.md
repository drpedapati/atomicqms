# AtomicQMS Troubleshooting Guide

This guide covers common issues and their solutions.

## Table of Contents

- [Setup Issues](#setup-issues)
- [AI Assistant Issues](#ai-assistant-issues)
- [Docker Issues](#docker-issues)
- [Credential Issues](#credential-issues)
- [Runner Issues](#runner-issues)
- [Organization & Template Issues](#organization--template-issues)

---

## Setup Issues

### "Cannot connect to Docker daemon"

**Problem**: Docker is not running or not accessible.

**Solution**:
```bash
# Check if Docker is running
docker info

# If not running, start Docker Desktop (macOS/Windows)
# Or start Docker service (Linux)
sudo systemctl start docker
```

### "Container atomicqms is not running"

**Problem**: AtomicQMS container hasn't started properly.

**Solution**:
```bash
# Check container status
docker compose ps

# View logs to see what went wrong
docker compose logs server

# Restart containers
docker compose restart

# If still failing, clean restart:
docker compose down
docker compose up -d
```

### "Admin user already exists" error

**Problem**: Trying to create admin user when it already exists.

**Solution**:
```bash
# List existing users
docker exec atomicqms gitea admin user list

# If admin exists, either:
# 1. Use existing admin account
# 2. Change password:
docker exec -u git atomicqms gitea admin user change-password \
  --username admin \
  --password 'NewPassword'
```

---

## AI Assistant Issues

### "@qms-assistant doesn't respond"

**Checklist**:
1. **Is the runner running?**
   ```bash
   docker compose ps runner
   # Should show "Up"
   ```

2. **Are credentials configured?**
   ```bash
   # Check .env file exists and has token
   grep CLAUDE_CODE_OAUTH_TOKEN .env

   # OR check organization secrets
   ./verify-org-secrets.sh
   ```

3. **Did the workflow trigger?**
   - Go to repository → Actions tab
   - Look for workflow run
   - Click on run to view logs

4. **Check workflow logs for errors**:
   - Look for "Environment variable validation failed"
   - Look for "Installation failed"

### "Environment variable validation failed"

**Problem**: Claude Code credentials not found.

**Credential Precedence** (highest to lowest):
1. Repository secrets (`Settings → Secrets`)
2. Organization secrets (if repo is in an organization)
3. Runner environment variables (`.env` file)

**Solution**:
```bash
# Option 1: Set organization secret (recommended for teams)
./setup-organization.sh

# Option 2: Check runner env vars
cat .env | grep CLAUDE_CODE_OAUTH_TOKEN

# Option 3: Set per-repository
# Go to repo → Settings → Secrets
# Add CLAUDE_CODE_OAUTH_TOKEN
```

### "HttpError: Only admins can query all permissions"

**Problem**: Using external claude-code-gitea-action instead of vendored version.

**Solution**:
Your repository must use the vendored action with Gitea permission fix:

```yaml
# In .gitea/workflows/claude-qms-assistant.yml
# CORRECT:
uses: ./actions/claude-code-gitea-action

# WRONG:
uses: markwylde/claude-code-gitea-action@main
```

If using template repository, this is already fixed. If manual setup, copy the `actions/` directory from the template.

### "Claude Code installation hangs"

**Problem**: Installation timeout or network issues.

**Solution**:
```bash
# Check runner logs
docker logs atomicqms-runner --tail 100

# If stuck at "Installing Claude Code...", restart runner
docker compose restart runner

# Check if bun is working inside container
docker exec atomicqms-runner bun --version
```

---

## Docker Issues

### "Port 3001 already in use"

**Problem**: Another service is using port 3001.

**Solution**:
```bash
# Find what's using the port
lsof -i :3001  # macOS/Linux
netstat -ano | findstr :3001  # Windows

# Either stop that service, or change AtomicQMS port:
# Edit docker-compose.yml
ports:
  - "3002:3000"  # Change 3001 → 3002
```

### "Permission denied" when running Docker commands

**Problem**: User not in docker group or Docker Desktop not running.

**Solution**:
```bash
# macOS/Windows: Start Docker Desktop

# Linux: Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in for changes to take effect
```

### "Cannot remove container: container is in use"

**Problem**: Container is still running.

**Solution**:
```bash
# Stop all containers first
docker compose down

# If that doesn't work, force remove
docker compose down --volumes --remove-orphans
```

---

## Credential Issues

### "Which credentials should I use?"

**Decision tree**:

```
Do you have Claude Max subscription?
├─ YES: Use Claude Code OAuth Token
│         Get from: https://claude.ai/code
│         Set as: CLAUDE_CODE_OAUTH_TOKEN
│
└─ NO: Use Anthropic API Key
          Get from: https://console.anthropic.com/
          Set as: ANTHROPIC_API_KEY
```

### "I set credentials but they're not working"

**Diagnostic steps**:

1. **Check credential location**:
   ```bash
   # Runner environment (works globally)
   cat .env

   # Organization secrets (works for org repos)
   ./verify-org-secrets.sh

   # Repository secrets (works for specific repo)
   # Check in Gitea UI: repo → Settings → Secrets
   ```

2. **Check credential format**:
   ```bash
   # OAuth token should start with:
   CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-...

   # API key should start with:
   ANTHROPIC_API_KEY=sk-ant-api03-...
   ```

3. **Restart runner after changing .env**:
   ```bash
   docker compose restart runner
   ```

### "Credentials worked yesterday, now they don't"

**Possible causes**:
1. **Token expired**: Claude Code OAuth tokens can expire. Generate new token at https://claude.ai/code
2. **API quota exceeded**: Check your Anthropic console for usage limits
3. **Runner restarted without .env**: Ensure .env file exists and is readable

---

## Runner Issues

### "Runner is not picking up jobs"

**Diagnostic steps**:

1. **Check runner status**:
   ```bash
   docker logs atomicqms-runner --tail 50
   ```

2. **Look for**:
   - "runner: atomicqms-runner-1, with version: v0.2.13, declare successfully" ✅
   - Any error messages about registration
   - Connection errors to Gitea

3. **Common fixes**:
   ```bash
   # Restart runner
   docker compose restart runner

   # If registration failed, check token in .env
   grep RUNNER_TOKEN .env

   # Re-register runner (if needed)
   # Get new token from: Gitea → Site Admin → Actions → Runners
   # Update .env and restart
   ```

### "Runner shows 'idle' but won't run jobs"

**Problem**: Runner registered but not processing workflows.

**Solution**:
```bash
# Check runner labels
docker logs atomicqms-runner | grep "with labels"

# Should show: ubuntu-latest, ubuntu-24.04, ubuntu-22.04

# If not, check runner-data/config.yaml
cat runner-data/config.yaml

# Restart to reload config
docker compose restart runner
```

### "Job containers can't reach Gitea"

**Problem**: Networking issue between job containers and Gitea.

**Solution**:
Check `GITEA_INSTANCE_URL` in docker-compose.yml:
```yaml
# CORRECT (for local development):
- GITEA_INSTANCE_URL=http://host.docker.internal:3001

# WRONG:
- GITEA_INSTANCE_URL=http://localhost:3001  # won't work from containers
```

---

## Organization & Template Issues

### "Organization 'atomicqms-lab' not found"

**Problem**: Organization hasn't been created yet.

**Solution**:
```bash
# Create organization
./setup-organization.sh

# Or create manually in Gitea:
# Click + → New Organization
```

### "Template repository not found"

**Problem**: Template hasn't been created or transferred to organization.

**Solution**:
```bash
# Create template
./setup-template-repository.sh

# Check if template exists
curl -s http://localhost:3001/api/v1/repos/atomicqms-lab/atomicqms-template

# If you see 404, template doesn't exist
# If you see JSON with repository info, template exists
```

### "New repo from template doesn't have AI assistant"

**Problem**: Workflow files or action directory missing.

**Solution**:
1. **Check if .gitea/workflows/ directory exists** in new repo
2. **Check if actions/claude-code-gitea-action/ exists** in new repo
3. **If missing**, the template wasn't properly set up:
   ```bash
   # Re-create template
   ./setup-template-repository.sh

   # Verify template has all files:
   curl -s http://localhost:3001/api/v1/repos/atomicqms-lab/atomicqms-template/contents/
   ```

### "Organization secrets not working in new repos"

**Problem**: Secrets are organization-level but not being inherited.

**Diagnostic**:
```bash
# Verify secret exists at org level
./verify-org-secrets.sh

# Check workflow is using correct input format
# Should have:
claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}

# NOT:
claude_code_oauth_token: ${{ env.CLAUDE_CODE_OAUTH_TOKEN }}
```

---

## Advanced Diagnostics

### View complete workflow execution

```bash
# Download log from Actions UI
# Or check runner logs during execution
docker logs -f atomicqms-runner
```

### Check runner environment variables

```bash
# What environment does the runner see?
docker exec atomicqms-runner env | grep -i claude
docker exec atomicqms-runner env | grep -i anthropic
```

### Verify network connectivity

```bash
# Can runner reach Gitea?
docker exec atomicqms-runner curl -I http://host.docker.internal:3001

# Can runner reach Claude API?
docker exec atomicqms-runner curl -I https://api.anthropic.com
```

### Reset everything

```bash
# Nuclear option - fresh start
docker compose down --volumes
rm -rf gitea/ runner-data/
rm .env

# Then start over
./setup-all.sh --full
```

---

## Still Having Issues?

1. **Check the logs**:
   - Gitea: `docker logs atomicqms`
   - Runner: `docker logs atomicqms-runner`
   - Workflow: Check Actions tab in Gitea UI

2. **Review documentation**:
   - [Complete AI Integration Guide](./docs/ai-integration/)
   - [Architecture Documentation](./docs/architecture/)

3. **File an issue**:
   - Include relevant log excerpts
   - Describe what you tried
   - Include your environment (OS, Docker version)

---

## Quick Reference: Common Commands

```bash
# Check status
docker compose ps
docker logs atomicqms --tail 50
docker logs atomicqms-runner --tail 50

# Restart services
docker compose restart
docker compose restart runner

# Verify credentials
cat .env | grep CLAUDE
./verify-org-secrets.sh

# Fresh start
docker compose down
docker compose up -d

# View workflow logs
# Use Gitea UI: Repository → Actions → Click on run
```
