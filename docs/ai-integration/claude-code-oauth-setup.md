# Claude Code OAuth Setup Guide for AtomicQMS

## Overview

This guide walks you through setting up the AtomicQMS AI Assistant using your Claude Max or Claude Pro subscription via Claude Code OAuth authentication. This method allows you to use your existing Claude subscription instead of requiring a separate Anthropic API key.

## Prerequisites

Before you begin, ensure you have:

- ✅ Active Claude Max or Claude Pro subscription
- ✅ Claude Code CLI installed on your computer ([download here](https://claude.ai/download))
- ✅ AtomicQMS instance running (see [Quick Start](../guide/quick-start.md))
- ✅ Admin access to your AtomicQMS instance
- ✅ Docker and Docker Compose installed

## Understanding Authentication Options

### Option 1: Claude Code OAuth (Recommended for Subscribers)

**What it is:** Uses your existing Claude subscription's authentication token from the Claude Code desktop/CLI application.

**Pros:**
- No separate API billing required
- Uses your existing Claude Max/Pro subscription
- Easier token management through Claude Code CLI
- Automatically refreshed by Claude Code app

**Cons:**
- Requires Claude Code CLI to be installed
- Token tied to your personal Claude account

**Best for:** Individual users or small teams with Claude Max/Pro subscriptions

### Option 2: Anthropic API Key

**What it is:** A dedicated API key from Anthropic's developer platform.

**Pros:**
- Independent of personal accounts
- Better for team/organizational use
- More granular usage controls

**Cons:**
- Requires separate API billing account
- Additional cost beyond Claude subscription
- Separate from Claude Max/Pro subscription

**Best for:** Organizations needing separate billing or team-based API access

---

## Part 1: Get Your Claude Code OAuth Token

### Step 1.1: Install Claude Code CLI

If you haven't already installed Claude Code:

**macOS:**
```bash
# Download from claude.ai/download
# Or install via Homebrew (if available)
brew install --cask claude
```

**Linux:**
```bash
# Download from claude.ai/download
# Or use the installer script
curl -fsSL https://claude.ai/install.sh | bash
```

**Windows:**
```powershell
# Download installer from claude.ai/download
# Run the installer
```

### Step 1.2: Login to Claude Code

Open your terminal and authenticate:

```bash
claude login
```

This will:
1. Open your browser
2. Ask you to authorize Claude Code
3. Redirect you back to confirm authentication
4. Save your OAuth token locally

You should see a success message like:
```
✓ Successfully logged in to Claude Code
```

### Step 1.3: Locate Your OAuth Token

Your OAuth token is stored in Claude Code's configuration file.

**macOS/Linux:**
```bash
cat ~/.config/claude/config.json
```

**Windows:**
```powershell
type %USERPROFILE%\.config\claude\config.json
```

The file will look like this:
```json
{
  "oauth_token": "sess-ant-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "user_id": "user-xxxxxxxxx",
  ...
}
```

**Extract just the token:**

**macOS/Linux:**
```bash
# This command prints just the token value
grep -o '"oauth_token": "[^"]*' ~/.config/claude/config.json | cut -d'"' -f4
```

**Windows:**
```powershell
# Or manually copy the value between quotes after "oauth_token":
```

**Copy this token** - you'll need it in the next section.

**⚠️ Security Note:** This token provides access to your Claude account. Keep it secret and never commit it to Git!

---

## Part 2: Configure AtomicQMS Gitea Instance

### Step 2.1: Access AtomicQMS Admin Panel

1. Open your browser and navigate to your AtomicQMS instance:
   ```
   http://localhost:3001
   ```
   (or your production URL)

2. Log in with your admin credentials

3. Click the **settings icon** (⚙️) in the top right corner

4. Select **Site Administration**

### Step 2.2: Enable and Configure Gitea Actions Runner

1. In Site Administration, go to **Actions** → **Runners**

2. Click **Create new Runner**

3. You'll see a registration command like:
   ```bash
   act_runner register \
     --instance http://localhost:3001 \
     --token AbCdEfGhIjKlMnOpQrStUvWxYz1234567890
   ```

4. **Copy the token** (the part after `--token`)

   Example: `AbCdEfGhIjKlMnOpQrStUvWxYz1234567890`

5. **Keep this window open** - you'll return here after the runner connects

### Step 2.3: Create Environment File

On your local machine where AtomicQMS is installed:

```bash
# Navigate to the claude-integration worktree
cd /Users/ernie/Documents/Sandbox/atomicqms-claude-integration

# Create .env file from template
cp .env.example .env

# Edit the .env file
nano .env
```

Add your runner token:

```bash
# AtomicQMS Environment Configuration

# Gitea Actions Runner Token (from Step 2.2)
RUNNER_TOKEN=AbCdEfGhIjKlMnOpQrStUvWxYz1234567890

# Public URL for your AtomicQMS instance
GITEA_SERVER_URL=http://localhost:3001
```

**For production deployments**, update `GITEA_SERVER_URL` to your actual domain:
```bash
GITEA_SERVER_URL=https://qms.yourcompany.com
```

Save and close the file (`Ctrl+X`, then `Y`, then `Enter` in nano).

### Step 2.4: Start the Actions Runner

Start AtomicQMS with the Actions runner:

```bash
# Make sure you're in the right directory
cd /Users/ernie/Documents/Sandbox/atomicqms-claude-integration

# Start both AtomicQMS and the runner
docker compose up -d

# Check that both containers are running
docker ps
```

You should see two containers:
- `atomicqms` - The Gitea instance
- `atomicqms-runner` - The Actions runner

**Verify runner connection:**

```bash
# Check runner logs
docker logs atomicqms-runner

# You should see:
# "Runner registered successfully"
# "Runner started"
```

**Back in the Gitea web interface:**

1. Refresh the **Actions** → **Runners** page
2. You should now see your runner listed with status **Idle** (green)
3. Runner name: `atomicqms-runner-1`

---

## Part 3: Configure Repository Secrets

### Step 3.1: Create or Select a Repository

You need a repository in AtomicQMS to add the AI assistant to.

**Option A: Create a new test repository**

1. In AtomicQMS, click the **+** icon → **New Repository**
2. Repository name: `test-qms`
3. Description: `Testing AI Assistant`
4. Initialize repository: ✅ Add a README
5. Click **Create Repository**

**Option B: Use an existing repository**

Navigate to your existing repository where you want AI assistance.

### Step 3.2: Add Claude OAuth Token Secret

1. In your repository, go to **Settings** → **Secrets** (in left sidebar)

2. Click **Add Secret**

3. Configure the secret:
   - **Name:** `CLAUDE_CODE_OAUTH_TOKEN`
   - **Value:** Paste your OAuth token from Part 1, Step 1.3
     ```
     sess-ant-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
     ```

4. Click **Add Secret**

### Step 3.3: Add Server URL Secret

1. Click **Add Secret** again

2. Configure:
   - **Name:** `GITEA_SERVER_URL`
   - **Value:** Your AtomicQMS URL
     ```
     http://localhost:3001
     ```
     (or your production URL like `https://qms.yourcompany.com`)

3. Click **Add Secret**

### Step 3.4: Verify Secrets

You should now see two secrets listed:
- ✅ `CLAUDE_CODE_OAUTH_TOKEN` (last updated just now)
- ✅ `GITEA_SERVER_URL` (last updated just now)

**⚠️ Security:** Secret values are encrypted and hidden after creation. You won't be able to view them again, only update or delete them.

---

## Part 4: Update Workflow Configuration

### Step 4.1: Add Workflow File to Repository

You need to add the Claude assistant workflow to your repository.

**If you're in the `atomicqms-claude-integration` worktree**, the workflow already exists:

```bash
# Check if workflow exists
ls -la .gitea/workflows/claude-qms-assistant.yml
```

**If it exists**, you just need to update it to use OAuth instead of API key.

**If starting fresh** in a different repository:

1. In AtomicQMS web interface, navigate to your repository
2. Create a new file: `.gitea/workflows/claude-qms-assistant.yml`
3. Copy the workflow content (see Step 4.2)

### Step 4.2: Update Authentication Method

Edit `.gitea/workflows/claude-qms-assistant.yml`

Find this line (around line 48):
```yaml
anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

**Replace it with:**
```yaml
claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
```

**Complete Authentication Section Should Look Like:**

```yaml
# Authentication
github_token: ${{ secrets.GITHUB_TOKEN }}
claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
```

### Step 4.3: Commit the Workflow

**Via Git CLI:**

```bash
cd /Users/ernie/Documents/Sandbox/atomicqms-claude-integration

# Stage the workflow file
git add .gitea/workflows/claude-qms-assistant.yml

# Commit
git commit -m "Configure Claude Code OAuth authentication for AI assistant"

# Push to repository
git push origin feature/claude-integration
```

**Via Gitea Web Interface:**

1. Click **Commit Changes** button
2. Add commit message: "Configure OAuth authentication"
3. Choose "Commit directly to the feature/claude-integration branch"
4. Click **Commit Changes**

---

## Part 5: Test the AI Assistant

### Step 5.1: Create a Test Issue

1. In your repository, go to **Issues** tab
2. Click **New Issue**
3. Configure:
   - **Title:** `Test AI Assistant Integration`
   - **Description:**
     ```markdown
     This is a test issue to verify the Claude AI assistant is working.

     We're using Claude Code OAuth authentication with our Claude Max subscription.

     @qms-assistant Hello! Can you confirm you're working and tell me what you can help with?
     ```

4. Click **Create Issue**

### Step 5.2: Monitor Workflow Execution

1. Go to the **Actions** tab in your repository
2. You should see a new workflow run: "AtomicQMS AI Assistant"
3. Click on the workflow run to see details
4. Watch the execution steps:
   - ✅ Checkout repository
   - ✅ Run AtomicQMS AI Assistant
   - 🔄 (Processing...)

**Expected Timeline:**
- Workflow starts: < 30 seconds after comment
- Execution time: 30-60 seconds
- Response posted: Shortly after completion

### Step 5.3: Verify AI Response

1. Return to your test issue
2. After workflow completes, you should see a new comment from the AI assistant
3. The comment should include:
   - Introduction to capabilities
   - List of supported features (SOP review, CAPA, etc.)
   - Offer to help with specific QMS tasks

**Example Expected Response:**

```markdown
Hello! I'm the AtomicQMS AI Assistant, and I'm working correctly with your Claude Code OAuth authentication. ✅

**I can help you with:**

- 📋 **SOP Review**: Review Standard Operating Procedures for completeness, clarity, and regulatory compliance
- 🔍 **CAPA Documentation**: Guide you through Corrective and Preventive Action documentation with structured root cause analysis
- ⚙️ **Change Impact Assessment**: Analyze the impact of process or equipment changes
- ✅ **Compliance Checking**: Verify documentation against FDA 21 CFR Part 11, ISO 13485, and GxP requirements

**QMS Context I Understand:**
- Pull Requests = Document approval workflows
- Issues = CAPA records and change control
- Git commits = Audit trail entries
- Markdown documentation = Single-source compliance documentation

**How to Use Me:**
Simply mention `@qms-assistant` in any PR or Issue comment with your request, such as:
- `@qms-assistant Review this SOP for ISO 13485 compliance`
- `@qms-assistant Help me structure a CAPA for [issue description]`
- `@qms-assistant What's the impact of changing [equipment/process]?`

What would you like help with today?
```

---

## Part 6: Real-World Usage Examples

### Example 1: SOP Review

**Create a Pull Request:**

1. Create a new branch: `sop/temperature-monitoring-v2`
2. Add or edit an SOP document
3. Open a Pull Request
4. In the PR description or comments, add:
   ```markdown
   @qms-assistant Please review this SOP for:
   1. Completeness (all required sections present)
   2. ISO 13485 compliance
   3. Clear procedures and acceptance criteria
   4. Training requirements
   ```

Claude will analyze and provide structured feedback.

### Example 2: CAPA Assistance

**Create a CAPA Issue:**

1. Create a new issue with label `capa`
2. Title: `CAPA-2025-001: Temperature Excursion in Sample Storage`
3. In the issue description:
   ```markdown
   ## Problem Statement
   Temperature in refrigerator SN-RF-001 exceeded 8°C limit, reaching 12°C for 30 minutes.

   @qms-assistant Help me structure the root cause analysis and corrective action plan for this temperature excursion.
   ```

Claude will provide a structured CAPA framework.

### Example 3: Change Control

**Create a Change Request Issue:**

1. Create issue with label `change-control`
2. Title: `Change Control: Switch to Alternative Reagent Supplier`
3. Description:
   ```markdown
   We need to change our PBS buffer supplier due to product discontinuation.

   Current: BioSupply Corp (Cat# PBS-1000)
   New: LabChem Industries (Cat# PBS-2000)

   @qms-assistant Analyze the impact of this supplier change on:
   - Validated processes
   - Required documentation updates
   - Regulatory notifications
   - Qualification requirements
   ```

---

## Part 7: Troubleshooting

### Issue: Workflow Not Triggering

**Symptoms:**
- Comment with `@qms-assistant` doesn't start a workflow
- No workflow run appears in Actions tab

**Solutions:**

1. **Check runner is connected:**
   ```bash
   docker logs atomicqms-runner
   # Should show: "Runner registered" and "Runner idle"
   ```

2. **Verify workflow file exists:**
   - Repository → Browse Files → `.gitea/workflows/claude-qms-assistant.yml`
   - File must be in main/default branch or the PR source branch

3. **Check workflow syntax:**
   - Go to Actions → Workflows
   - Look for syntax errors

4. **Restart runner:**
   ```bash
   docker restart atomicqms-runner
   ```

### Issue: Authentication Failed

**Symptoms:**
- Workflow runs but fails with "Authentication error"
- Error message about invalid token

**Solutions:**

1. **Verify secret name matches exactly:**
   - Settings → Secrets
   - Must be `CLAUDE_CODE_OAUTH_TOKEN` (exact case)

2. **Re-copy OAuth token:**
   ```bash
   # Get fresh token
   grep "oauth_token" ~/.config/claude/config.json
   ```
   - Remove any whitespace or newlines
   - Update secret in repository settings

3. **Check token hasn't expired:**
   - Re-login to Claude Code:
     ```bash
     claude logout
     claude login
     ```
   - Get new token and update secret

4. **Verify Claude Code CLI is active:**
   ```bash
   claude --version
   # Should show version number
   ```

### Issue: Runner Offline

**Symptoms:**
- Runner shows as "Offline" in Gitea
- Workflows queued but never execute

**Solutions:**

1. **Check runner container status:**
   ```bash
   docker ps | grep runner
   # Should show "Up" status
   ```

2. **Check runner logs:**
   ```bash
   docker logs atomicqms-runner --tail 50
   ```

3. **Verify registration token:**
   - Check `.env` file has correct `RUNNER_TOKEN`
   - Get new token from Gitea if needed

4. **Restart runner:**
   ```bash
   docker compose restart runner
   ```

5. **Re-register runner:**
   ```bash
   # Stop containers
   docker compose down

   # Remove runner data
   rm -rf runner-data/

   # Get new registration token from Gitea
   # Update .env file

   # Start fresh
   docker compose up -d
   ```

### Issue: Permission Errors

**Symptoms:**
- "Permission denied" errors
- Can't create branches or post comments

**Solutions:**

1. **Check workflow permissions:**
   - Edit `.gitea/workflows/claude-qms-assistant.yml`
   - Ensure permissions section exists:
     ```yaml
     permissions:
       contents: write
       issues: write
       pull-requests: write
       actions: read
     ```

2. **Verify repository access:**
   - Ensure bot/user has write access to repository

### Issue: Claude Responses Are Generic

**Symptoms:**
- Responses don't mention QMS/compliance
- Doesn't understand regulatory context

**Solutions:**

1. **Verify QMS context file exists:**
   ```bash
   ls -la .claude/qms-context.md
   ```

2. **Check workflow loads context:**
   - Line 86 in workflow: `Load additional context from: .claude/qms-context.md`

3. **Ensure context file is committed:**
   ```bash
   git add .claude/qms-context.md
   git commit -m "Add QMS context for AI assistant"
   git push
   ```

---

## Part 8: Advanced Configuration

### Custom Trigger Phrases

Change the trigger phrase from `@qms-assistant` to something else:

Edit `.gitea/workflows/claude-qms-assistant.yml`:

```yaml
# Change line 38
trigger_phrase: '@compliance-bot'  # or '@doc-reviewer', '@qms-ai', etc.
```

### Multiple Assistants

Create specialized assistants for different purposes:

**SOP Reviewer Only:**
```yaml
# .gitea/workflows/sop-reviewer.yml
trigger_phrase: '@sop-reviewer'
prompt: |
  You are an SOP review specialist. Focus exclusively on:
  - Document structure and completeness
  - ISO 13485 compliance
  - Training requirements
  ...
```

**CAPA Specialist:**
```yaml
# .gitea/workflows/capa-assistant.yml
trigger_phrase: '@capa-assistant'
label_trigger: 'capa'
prompt: |
  You are a CAPA documentation expert. Focus on:
  - Root cause analysis methods
  - Corrective action effectiveness
  - Verification planning
  ...
```

### Organization-Specific Context

Customize `.claude/qms-context.md` for your organization:

```markdown
## [Your Company] Specific Guidelines

### Document Numbering
- SOPs: SOP-[DEPT]-[NUM] (e.g., SOP-QC-001)
- CAPAs: CAPA-[YEAR]-[NUM] (e.g., CAPA-2025-042)

### Approval Requirements
- Quality Manager: All SOPs
- Department Head: Departmental procedures
- Regulatory Affairs: Customer-facing documents

### Regulatory Framework
Primary: FDA 21 CFR Part 820 (Medical Devices)
Secondary: ISO 13485:2016
Additional: EU MDR 2017/745
```

---

## Part 9: Security Best Practices

### Token Security

✅ **DO:**
- Store OAuth tokens only in repository secrets
- Use environment variables for local development
- Rotate tokens periodically (re-login to Claude Code)
- Limit repository access to authorized personnel

❌ **DON'T:**
- Commit tokens to Git
- Share tokens via email/chat
- Use the same token across multiple systems
- Log tokens in application logs

### Access Control

**Repository Level:**
- Use branch protection rules
- Require PR reviews before merge
- Limit who can modify workflow files

**Runner Level:**
- Run runner in isolated Docker network
- Limit runner container capabilities
- Monitor runner logs for suspicious activity

**AI Assistant Level:**
- Restrict allowed tools (no Bash execution)
- Review AI responses before implementing suggestions
- Maintain human oversight for critical decisions

### Audit Logging

All AI interactions are automatically logged:

1. **Workflow Logs:**
   - Actions → Workflow run → View logs
   - Contains full execution trace

2. **Issue/PR Comments:**
   - All AI responses are posted as comments
   - Full conversation history preserved

3. **Git Commits:**
   - Any code changes have commit history
   - Co-authored by AI assistant attribution

---

## Part 10: Maintenance

### Weekly Tasks

- Check runner status (should be "Idle" when not running workflows)
- Review Actions logs for errors
- Monitor usage patterns

### Monthly Tasks

- Review and update `.claude/qms-context.md` with new organizational guidelines
- Check for workflow file updates from upstream
- Rotate OAuth token (logout/login Claude Code)

### When Updating AtomicQMS

```bash
# Pull latest changes
cd /Users/ernie/Documents/Sandbox/atomicqms-claude-integration
git pull origin main

# Rebuild containers
docker compose down
docker compose build
docker compose up -d

# Verify runner reconnects
docker logs atomicqms-runner
```

---

## Additional Resources

### Documentation Links

- [Gitea Actions Overview](https://docs.gitea.com/usage/actions/overview)
- [Claude API Documentation](https://docs.anthropic.com/claude/reference/getting-started-with-the-api)
- [claude-code-gitea-action](https://github.com/markwylde/claude-code-gitea-action)

### AtomicQMS Documentation

- [AI Integration Setup](./gitea-actions-setup.md) - Technical setup guide
- [QMS Workflows](./qms-workflows.md) - Detailed usage examples
- [Quick Start](../guide/quick-start.md) - AtomicQMS basics

### Support

**Questions about:**
- **AtomicQMS**: Open an issue in this repository
- **Claude Code**: Visit https://claude.ai/help
- **Gitea Actions**: https://docs.gitea.com/

---

## Quick Reference Card

### Common Commands

```bash
# Check runner status
docker logs atomicqms-runner

# Restart runner
docker restart atomicqms-runner

# Get OAuth token
grep "oauth_token" ~/.config/claude/config.json

# View workflow logs
# (Use Gitea web UI: Actions → Select workflow run)

# Re-login to Claude Code
claude logout && claude login
```

### Trigger Examples

```markdown
# In PR comments:
@qms-assistant Review this SOP for completeness

# In issue descriptions:
@qms-assistant Help me document this CAPA

# Specific requests:
@qms-assistant Check ISO 13485 compliance
@qms-assistant Analyze change impact
@qms-assistant Suggest training requirements
```

### Secret Names (Must Match Exactly)

- `CLAUDE_CODE_OAUTH_TOKEN`
- `GITEA_SERVER_URL`

---

**Last Updated:** 2025-10-26
**Version:** 1.0.0
**For:** AtomicQMS with Claude Code OAuth Integration
