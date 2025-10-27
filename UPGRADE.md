# Upgrading AtomicQMS After Minimal Install

This guide shows **exactly** how to add features to an existing AtomicQMS installation, even with active repositories and users.

## CRITICAL: Where Is My Data Stored?

**Before upgrading, understand where your data lives:**

### Data Directory Location

By default: `./gitea` (relative to docker-compose.yml)

**This directory contains ALL your AtomicQMS data:**
- Git repositories (`./gitea/git/repositories/`)
- Database with users, issues, PRs (`./gitea/gitea/gitea.db`)
- LFS files (`./gitea/git/lfs/`)
- SSH keys (`./gitea/ssh/`)
- Logs and sessions (`./gitea/gitea/`)

**To find your data directory:**
```bash
# Check your configuration
grep ATOMICQMS_DATA_DIR .env

# Or check the default
docker inspect atomicqms | grep "Source.*gitea"
```

**To change data directory location** (must do BEFORE first run):
```bash
# In .env file:
ATOMICQMS_DATA_DIR=/path/to/your/data

# Example for production:
ATOMICQMS_DATA_DIR=/data/atomicqms
```

⚠️ **WARNING:** Moving data directory after installation requires:
1. Stop containers: `docker compose down`
2. Move entire directory: `mv ./gitea /new/location`
3. Update .env: `ATOMICQMS_DATA_DIR=/new/location`
4. Restart: `docker compose up -d`

---

## Can I Add Features Later?

**YES - Both GitHub OAuth and AI Assistant can be safely added after minimal install.**

**Note:** As of the latest version, **organization setup is included in ALL install modes** (minimal, standard, full). This guide focuses on adding the optional features (GitHub OAuth and AI Assistant) after initial setup.

### What Gets Modified

| Feature | Changes | Safe on Busy Repo? |
|---------|---------|-------------------|
| **GitHub OAuth** | Adds auth source to Gitea database | ✅ YES - No data touched |
| **AI Assistant** | Starts runner container, adds .env file | ✅ YES - No data touched |

**Neither feature modifies:**
- Existing repositories
- User data
- Issues, PRs, comments
- Git history
- Configuration files (except adding OAuth source)

---

## Adding GitHub OAuth (SSO)

### Prerequisites
- AtomicQMS running (any mode)
- GitHub OAuth App created at https://github.com/settings/developers
  - **Callback URL:** `http://localhost:3001/user/oauth2/github/callback`

### Exact Steps

**1. Add credentials to .env file:**

```bash
# If .env doesn't exist, create it
cp .env.example .env

# Add these lines (or edit if exists):
GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxxx          # From GitHub OAuth App page
GITHUB_CLIENT_SECRET=ghp_xxxxxxxxxxxxxxxx    # Generate from OAuth App page
```

**2. Run the OAuth setup script:**

```bash
./setup-github-oauth.sh
```

**What it does:**
- Checks if OAuth source already exists
- Adds/updates GitHub OAuth configuration
- Restarts Gitea container (brief ~3 second downtime)
- Verifies configuration

**3. Test it:**

Go to http://localhost:3001/user/login - you'll see "Sign in with GitHub" button

### On a Busy Repo

**Downtime:** ~3 seconds during container restart
**Data risk:** None - only adds auth source
**User impact:** Active sessions preserved, can login during/after
**Rollback:** Remove auth source: `docker exec -u git atomicqms gitea admin auth delete --id <ID>`

---

## Adding AI Assistant

### Prerequisites
- AtomicQMS running (any mode)
- Claude AI credentials (ONE of these):
  - `CLAUDE_CODE_OAUTH_TOKEN` from https://claude.ai/code (requires Claude Max)
  - `ANTHROPIC_API_KEY` from https://console.anthropic.com

### Exact Steps

**1. Add AI credentials to .env file:**

```bash
# If .env doesn't exist, create it
cp .env.example .env

# Add ONE of these lines:
CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-xxxxxxxxxxxxx    # Option 1: Claude Max
ANTHROPIC_API_KEY=sk-ant-api03-xxxxxxxxxxxxx          # Option 2: API Key
```

**2. Get runner token from Gitea:**

- Login to Gitea as admin
- Go to **Site Administration** → **Actions** → **Runners**
- Click **Create new Runner**
- Copy the registration token

**3. Add runner token to .env:**

```bash
# Add this line to .env:
RUNNER_TOKEN=your_runner_registration_token_here
```

**4. Run the AI assistant setup script:**

```bash
./setup-claude-assistant.sh
```

**What it does:**
- Validates Actions are enabled
- Checks for workflow files in your repos
- Starts the runner container
- Registers runner with Gitea
- Verifies connection

**5. Add workflow to existing repositories:**

For each repository where you want AI assistant:

```bash
# Option A: Use template repository
# Create new repos from atomicqms-lab/atomicqms-template

# Option B: Manual setup (for existing repos)
# 1. Create .gitea/workflows/ directory in your repo
mkdir -p .gitea/workflows

# 2. Copy workflow file
cp template-qms-repository/.gitea/workflows/claude-qms-assistant.yml \
   your-repo/.gitea/workflows/

# 3. Copy action directory
cp -r actions/claude-code-gitea-action your-repo/actions/

# 4. Commit and push
git add .gitea actions
git commit -m "Add AI assistant workflow"
git push
```

**6. Test it:**

Create an issue in the repository and comment: `@qms-assistant Hello!`

### On a Busy Repo

**Downtime:** None - runner starts separately
**Data risk:** None - only reads code, adds comments
**User impact:** None until workflow is added to specific repos
**Rollback:** Stop runner: `docker compose stop runner`

---

## Upgrading: Minimal → Standard → Full

**Note:** All modes now include organization setup by default. These upgrade paths focus on adding optional features.

You can upgrade step-by-step:

### Minimal → Standard (Add AI)

```bash
# 1. Add AI credentials to .env
# 2. Run: ./setup-claude-assistant.sh
# 3. Workflow already available via organization template
```

### Standard → Full (Add GitHub OAuth)

```bash
# 1. Add GitHub OAuth credentials to .env
# 2. Run: ./setup-github-oauth.sh
```

### Minimal → Full (All at once)

```bash
# 1. Add all credentials to .env:
#    - GITHUB_CLIENT_ID + GITHUB_CLIENT_SECRET
#    - CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY
#    - RUNNER_TOKEN

# 2. Run setup scripts in order:
./setup-github-oauth.sh
./setup-claude-assistant.sh
# (Organization already set up in all modes)
```

---

## Precise Rollback Commands

### Remove GitHub OAuth

```bash
# List auth sources
docker exec -u git atomicqms gitea admin auth list

# Delete OAuth source (get ID from list above)
docker exec -u git atomicqms gitea admin auth delete --id <ID>

# Restart to apply
docker compose restart
```

### Remove AI Assistant

```bash
# Stop runner
docker compose stop runner

# Remove runner container (optional)
docker compose rm runner

# Remove from docker-compose.yml (optional)
# Comment out the 'runner:' service section
```

### Remove Organization

Organizations can't be easily deleted once created. **Better approach:**
- Leave the organization
- Create new repos outside it
- Move repos out: Settings → Transfer Ownership

---

## Safety Checklist Before Upgrade

✅ **Backup database** (optional but recommended):
```bash
docker exec atomicqms tar -czf /tmp/gitea-backup.tar.gz /data/gitea/gitea.db
docker cp atomicqms:/tmp/gitea-backup.tar.gz ./backup-$(date +%Y%m%d).tar.gz
```

✅ **Check active users:**
```bash
# If you see active sessions, wait for low-traffic time
docker exec atomicqms gitea admin user list
```

✅ **Test credentials first:**
```bash
# For GitHub OAuth - verify in browser:
# https://github.com/settings/developers → Your OAuth App → Check callback URL

# For Claude AI - verify token works (test on another system if possible)
```

✅ **Have rollback commands ready** (see above)

---

## Troubleshooting Upgrades

### "OAuth source already exists"

**This is OK!** The script updates the existing source. If you want to start fresh:
```bash
docker exec -u git atomicqms gitea admin auth list  # Get ID
docker exec -u git atomicqms gitea admin auth delete --id <ID>
./setup-github-oauth.sh  # Run again
```

### "Runner already registered"

**This is OK!** If the runner token changed:
```bash
# Stop old runner
docker compose stop runner

# Remove runner data
rm -rf runner-data/

# Update RUNNER_TOKEN in .env
# Run setup again
./setup-claude-assistant.sh
```

### "Workflow not found in repository"

Workflow files must exist in each repo where you want AI. Options:
1. Use template repository for new repos (automatic)
2. Manually copy workflow + action to existing repos (shown above)
3. Use setup-template-repository.sh to create template, then fork

---

## Summary: What's Safe

| Action | Touches DB | Modifies Repos | Downtime | Reversible |
|--------|-----------|----------------|----------|------------|
| Add GitHub OAuth | Yes (auth table) | No | ~3 sec | Yes (delete auth) |
| Add AI Assistant | No | No* | None | Yes (stop runner) |

\* Workflow available via organization template, or add manually per-repo

**Note:** Organization is now included in ALL install modes by default.

**BOTTOM LINE:** Both GitHub OAuth and AI Assistant are **100% safe to add post-install**, even on busy systems with active users and repositories.
