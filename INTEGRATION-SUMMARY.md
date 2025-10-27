# Claude AI Assistant Integration - Complete Summary

## Overview

This integration adds Claude AI capabilities to AtomicQMS through Gitea Actions, enabling automated code reviews, documentation assistance, and intelligent issue responses.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│ User creates issue/PR with @qms-assistant mention   │
└────────────────┬────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────┐
│ Gitea Actions Workflow Triggers                     │
│ (.gitea/workflows/claude-qms-assistant.yml)         │
└────────────────┬────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────┐
│ Vendored claude-code-gitea-action                   │
│ (actions/claude-code-gitea-action/)                 │
│ - Modified permissions.ts for Gitea compatibility   │
└────────────────┬────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────┐
│ Claude Code Execution                                │
│ - API credentials from repository secrets            │
│ - Git operations in checked-out workspace            │
│ - Creates branch, commits, pushes changes            │
└─────────────────────────────────────────────────────┘
```

## Key Components

### 1. Vendored Action with Permission Fix
**Location:** `actions/claude-code-gitea-action/`

**Critical Modification:** `src/github/validation/permissions.ts`

The permission check was modified to detect Gitea environments and bypass GitHub-specific API calls that fail with Gitea runner tokens:

```typescript
// Detect Gitea environment
const giteaApiUrl = process.env.GITEA_API_URL?.trim();
const isGitea = giteaApiUrl && 
                !giteaApiUrl.includes("api.github.com") &&
                !giteaApiUrl.includes("github.com");

if (isGitea) {
  core.info(`Detected Gitea environment (${giteaApiUrl}), assuming actor has permissions`);
  return true;
}
```

**Testing:** Confirmed working in test-permission-fix repository, workflow run #21.

### 2. Workflow Configuration
**Location:** `.gitea/workflows/claude-qms-assistant.yml` (example template)

**Triggers:**
- Issue comments containing `@qms-assistant`
- New issues opened
- Pull requests opened
- Assignment to `qms-assistant` user

**Key Configuration:**
```yaml
anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
```

### 3. Docker Networking Configuration

**Runner Registration:** Uses `host.docker.internal:3001` to access Gitea from runner container

**Job Container Access:** Environment variable `GITEA_SERVER_URL` (or `QMS_SERVER_URL`) set to `http://host.docker.internal:3001` allows job containers to reach Gitea API

**Configuration:** In `docker-compose.yml`:
```yaml
runner:
  environment:
    - GITEA_INSTANCE_URL=http://host.docker.internal:3001
```

## Critical Findings

### ❌ What Doesn't Work: Runner Environment Variables

**Attempted Approach:**
```yaml
# In runner-data/config.yaml
runner:
  envs:
    ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY}

# In workflow
anthropic_api_key: ${{ env.ANTHROPIC_API_KEY }}
```

**Issue:** Gitea Actions does NOT populate the workflow `env` context from `runner.envs` configuration. The `${{ env.VARIABLE }}` expressions always evaluate to empty strings.

### ✅ What Works: Repository Secrets

**Working Approach:**
```yaml
# In workflow
anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
```

**Setup:**
1. Add secret via Gitea UI: Repository Settings → Secrets → Actions
2. Or via API:
```bash
curl -X PUT "http://localhost:3001/api/v1/repos/owner/repo/actions/secrets/CLAUDE_CODE_OAUTH_TOKEN" \
  -H "Authorization: token YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data": "your-claude-token-here"}'
```

## Deployment Guide

### Prerequisites
- Docker and Docker Compose
- Anthropic API key or Claude Code OAuth token
- Gitea instance running (AtomicQMS)

### Setup Steps

1. **Add Credentials to Repository**
   ```bash
   # Via Gitea UI:
   # Repository → Settings → Secrets → Actions → New Secret
   # Name: CLAUDE_CODE_OAUTH_TOKEN
   # Value: sk-ant-oat01-...
   ```

2. **Add Workflow File**
   ```bash
   mkdir -p .gitea/workflows
   cp examples/claude-qms-assistant.yml .gitea/workflows/
   git add .gitea/workflows/claude-qms-assistant.yml
   git commit -m "Add Claude AI assistant workflow"
   git push
   ```

3. **Vendor the Action** (if not already present)
   ```bash
   mkdir -p actions
   cp -r path/to/claude-code-gitea-action actions/
   git add actions/claude-code-gitea-action
   git commit -m "Vendor claude-code-gitea-action with Gitea fixes"
   git push
   ```

4. **Test the Integration**
   - Create an issue in the repository
   - Add a comment: `@qms-assistant Please help with...`
   - Check Actions tab for workflow execution

### Verification

Successful execution shows:
```
✅ Detected Gitea environment, assuming actor has permissions
✅ Successfully checked out base branch
✅ Claude Code successfully installed
✅ Job succeeded
```

Failed execution (credential issues):
```
❌ Environment variable validation failed:
   - Either ANTHROPIC_API_KEY or CLAUDE_CODE_OAUTH_TOKEN is required
```

## Testing Results

**Test Repository:** `drpedapati/test-permission-fix`
**Successful Run:** Workflow #21
**Key Validations:**
- ✅ Permission check bypass working (Gitea environment detected)
- ✅ Repository secrets passed correctly to action
- ✅ Claude Code executed successfully
- ✅ Branch created: `claude/issue-4-readme-update`
- ✅ Changes committed and pushed

**Log Evidence:**
```
2025-10-27T00:09:19.3463374Z Detected Gitea environment (http://host.docker.internal:3001), assuming actor has permissions
2025-10-27T00:11:52.3955635Z 🏁  Job succeeded
```

## Files Modified

### Core Integration
- `actions/claude-code-gitea-action/` - Vendored action with permission fix
- `runner-data/config.yaml` - Runner configuration (documented non-working env approach)
- `runner-data/.gitignore` - Ignore sensitive `.runner-env` file

### Documentation
- `docs/claude-ai-integration.md` - Integration guide
- `INTEGRATION-SUMMARY.md` - This file

### Examples
- `examples/claude-qms-assistant.yml` - Workflow template

## Maintenance Notes

### Updating Claude Code Version
The action uses Claude Code CLI version 1.0.117 (pinned in action.yml line 183).
To update:
1. Modify `actions/claude-code-gitea-action/action.yml`
2. Update version in install command
3. Test in a non-production repository first

### Updating Credentials
Repository secrets can be updated via:
- Gitea UI: Repository Settings → Secrets → Actions
- API: PUT request to secrets endpoint (overwrites existing)

### Monitoring
- Check Actions tab in Gitea for workflow runs
- Download logs for detailed execution traces
- Look for "Job succeeded" or "Job failed" in final output

## Known Limitations

1. **No Global Environment Variables:** Credentials must be configured per-repository as secrets
2. **Docker Networking:** Requires `host.docker.internal` for Mac/Windows Docker Desktop
3. **External Action Dependencies:** The vendored action calls `anthropics/claude-code-base-action@v0.0.63` which must be accessible from job containers

## Future Enhancements

- [ ] Organization-level secrets for shared credentials across repositories
- [ ] Custom MCP server integration for QMS-specific tools
- [ ] Template workflows for common QMS tasks
- [ ] Integration with document approval workflows

## Credits

- **Permission Fix:** Developed by senior engineer to enable Gitea compatibility
- **Integration Development:** Comprehensive testing and validation completed
- **Documentation:** Based on actual deployment experience with AtomicQMS

## References

- Claude Code Documentation: https://docs.claude.com/claude-code
- Gitea Actions Documentation: https://docs.gitea.com/usage/actions
- AtomicQMS Project: Quality Management System built on Gitea
