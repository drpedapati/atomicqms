# Next Steps: Organization Setup and Testing

## Current Status

All code changes are complete and pushed to GitHub. The integration is ready for final testing using organization-level secrets.

## What We Fixed

**Problem**: Credentials weren't being passed to new repositories created from the template because:
- Runner environment variables (`runner.envs` in config.yaml) don't work with composite actions
- This is a fundamental limitation of Gitea/act - expressions are evaluated before containers start
- The `test-permission-fix` repository worked because it had manually configured repository secrets

**Solution**: Use organization-level secrets that automatically apply to all repositories in the organization.

## Setup Instructions

### Step 1: Run Organization Setup Script

**For OAuth users (GitHub authentication)**, use the token-based script:

```bash
cd /Users/ernie/Documents/Sandbox/atomicqms-claude-integration
./setup-organization-token.sh
```

**Before running**, create a Gitea Personal Access Token:
1. Go to http://localhost:3001/user/settings/applications
2. Click "Generate New Token"
3. Token Name: `atomicqms-setup`
4. Select scopes: `admin:org`, `write:repository`, `read:user`
5. Click "Generate Token" and copy it

**Alternative: For local admin users with password**:

```bash
./setup-organization.sh
```

**The script will**:
1. Create `atomicqms-lab` organization
2. Set `CLAUDE_CODE_OAUTH_TOKEN` as an organization-level secret
3. Transfer `atomicqms-template` to the organization

### Step 2: Test with New Repository

After running the setup script:

1. **Create new repository** in the `atomicqms-lab` organization:
   - Go to http://localhost:3001/org/atomicqms-lab
   - Click "New Repository"
   - Select "atomicqms-template" as the template
   - Name it something like "test-org-secrets"

2. **Trigger the AI assistant**:
   - Create a new issue in the repository
   - Mention `@qms-assistant` in the issue body
   - The workflow should trigger automatically

3. **Verify success**:
   - Check the Actions tab for workflow runs
   - The workflow should complete without credential errors
   - Claude should respond to the issue

### Step 3: Verify Automatic Credential Injection

Check the workflow logs to confirm:
- No "Environment variable validation failed" errors
- Claude successfully authenticates
- The response is posted back to the issue

## What Changed

### Files Modified

1. **setup-organization.sh** (NEW)
   - Creates default organization structure
   - Sets organization-level secrets via Gitea API
   - Transfers template repository

2. **template-qms-repository/.gitea/workflows/claude-qms-assistant.yml**
   - Uses vendored action: `./actions/claude-code-gitea-action`
   - Removed explicit credential inputs (will use org secrets)
   - Simplified authentication flow

3. **actions/claude-code-gitea-action/action.yml**
   - Added fallback to environment variables (though this alone didn't solve the problem)
   - Ready to accept credentials from organization secrets

## Why This Works

Organization-level secrets are managed by Gitea server (not the runner), so:
- ✅ Secrets are available during expression evaluation
- ✅ All repositories in the organization inherit the secret automatically
- ✅ Zero per-repository configuration needed
- ✅ Composite actions can access secrets via `${{ secrets.* }}`

## Expected Outcome

After setup:
- ✅ Any new repository created in `atomicqms-lab` organization with the template will automatically work
- ✅ No manual secret configuration needed per repository
- ✅ Claude AI assistant responds to `@qms-assistant` mentions
- ✅ Fully zero-configuration deployment for lab/team environments

## Troubleshooting

If the workflow still fails:

1. **Verify organization secret exists**:
   ```bash
   curl -u admin:password http://localhost:3001/api/v1/orgs/atomicqms-lab/actions/secrets
   ```
   Should show `CLAUDE_CODE_OAUTH_TOKEN` in the list

2. **Check workflow is using vendored action**:
   - Open `.gitea/workflows/claude-qms-assistant.yml` in new repo
   - Should have `uses: ./actions/claude-code-gitea-action`

3. **Verify action code exists in repository**:
   ```bash
   ls -la actions/claude-code-gitea-action/
   ```
   Should show action.yml and src/ directory

## Architecture

```
User creates repo from template
         ↓
Template includes:
  - .gitea/workflows/claude-qms-assistant.yml
  - actions/claude-code-gitea-action/ (vendored)
         ↓
Workflow triggers on issue/PR events
         ↓
Workflow uses: ./actions/claude-code-gitea-action
         ↓
Action reads: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
         ↓
Gitea provides organization-level secret
         ↓
Claude Code executes with credentials
         ↓
Response posted to issue/PR
```

## Clean Next Session

Once verified working, consider:
1. Removing old test repositories (test-permission-fix, etc.)
2. Documenting the organization approach in README
3. Creating user guide for adding team members to organization
4. Setting up organization-level GitHub token if needed for private repos
