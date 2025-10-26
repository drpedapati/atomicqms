# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AtomicQMS is a Docker-based deployment of Gitea - a self-hosted Git service (similar to GitHub/GitLab). This is designed as a Quality Management System (QMS) with Git-based version control capabilities.

## Architecture

- **Platform**: Docker Compose
- **Git Service**: Gitea (latest version)
- **Database**: SQLite3 (file-based at `/data/gitea/gitea.db`)
- **Configuration**: Custom app.ini mounted from `./custom/conf/app.ini`
- **Data Persistence**: Volumes mounted to `./gitea` and `./custom`

## Service Access

- **Web Interface**: http://localhost:3001
- **SSH Git Access**: ssh://git@localhost:222
- **Container Name**: atomicqms

## Docker Management

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker logs atomicqms
docker logs atomicqms -f  # follow mode

# Restart container
docker compose restart

# Rebuild and restart
docker compose up -d --build
```

## Configuration

The system uses **pre-seeded configuration** to skip the GUI installation wizard. Key settings in `gitea/gitea/conf/app.ini`:

- **App Name**: AtomicQMS
- **Root URL**: http://localhost:3001/
- **Registration**: Disabled (`DISABLE_REGISTRATION = true`)
- **Public Access**: Enabled (`REQUIRE_SIGNIN_VIEW = false`)
- **Repository Root**: `/data/git/repositories`
- **Install Lock**: `true` (skips GUI setup on first run)
- **LFS Support**: Enabled at `/data/git/lfs`

To modify configuration:
1. Edit `gitea/gitea/conf/app.ini`
2. Restart container: `docker compose restart`

## Automated Setup

The container starts immediately without requiring browser configuration:

```bash
# Start the service
docker compose up -d

# Create admin user (required on first run)
docker exec -u git atomicqms gitea admin user create \
  --username admin \
  --password 'YourSecurePassword' \
  --email admin@example.com \
  --admin \
  --must-change-password=false

# Or change password for existing user
docker exec -u git atomicqms gitea admin user change-password \
  --username admin \
  --password 'YourNewPassword' \
  --must-change-password=false

# Access web interface
open http://localhost:3001
```

The `INSTALL_LOCK = true` setting prevents the initial configuration wizard from appearing.

## Data Management

- **Git Repositories**: Stored in `./gitea/git/repositories/` (gitignored)
- **Configuration**: `./gitea/gitea/conf/app.ini` (tracked in Git)
- **Database**: `./gitea/gitea/gitea.db` (gitignored)
- **SSH Keys**: Auto-generated in `./gitea/ssh/` (gitignored)
- **LFS Objects**: Stored in `./gitea/git/lfs/` (gitignored)
- **Runtime Data**: Logs, sessions, uploads in `./gitea/gitea/` (gitignored)
- **Custom Branding**: Logos in `./gitea/public/assets/img/` (gitignored, structure tracked)

## Custom Branding

AtomicQMS supports custom logo branding to replace Gitea's default teacup icon:

**File Locations:**
- `gitea/public/assets/img/logo.svg` - Mini logo (header, navigation, site icon)
- `gitea/public/assets/img/logo-full.svg` - Full logo (optional, for larger areas)

**How It Works:**
- `GITEA_CUSTOM` environment variable defaults to `/data/gitea`
- Custom assets in `/data/public/` override Gitea's embedded assets
- The `./gitea:/data` volume mount makes `gitea/public/` accessible as `/data/public/`
- SVG format required for `logo.svg`, PNG variants optional

**To Update Logos:**
1. Replace `gitea/public/assets/img/logo.svg` with your custom logo
2. Run `docker compose restart`
3. Hard refresh browser (Cmd+Shift+R)

**Note:** Logo files themselves are gitignored. Only the directory structure and README are tracked in Git.

## Network Configuration

The container runs on a dedicated Docker bridge network named `gitea` for isolation and future extensibility (e.g., adding CI/CD runners, database upgrades).

## Authentication

AtomicQMS supports two independent authentication systems:

| Type | Purpose | Documentation |
|------|---------|---------------|
| **GitHub OAuth** | User login (SSO) | [docs/authentication/github-oauth-setup.md](./docs/authentication/github-oauth-setup.md) |
| **Claude Code OAuth** | AI assistant | [docs/ai-integration/claude-code-oauth-setup.md](./docs/ai-integration/claude-code-oauth-setup.md) |

### GitHub OAuth (User Single Sign-On)

Allows users to sign into AtomicQMS with their GitHub accounts.

**Quick Setup:**
```bash
# 1. Create GitHub OAuth App at https://github.com/settings/developers
# 2. Configure credentials
cp .env.example .env
nano .env  # Add GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET

# 3. Run setup script
chmod +x setup-github-oauth.sh
./setup-github-oauth.sh
```

**Key Configuration** (pre-configured in `app.ini`):
```ini
[service]
DISABLE_REGISTRATION = true              # No local registration
ALLOW_ONLY_EXTERNAL_REGISTRATION = true  # OAuth registration allowed
ENABLE_USER_AVATAR = true                # Avatar support

[oauth2_client]
ENABLE_AUTO_REGISTRATION = true          # Auto-create users on first login
UPDATE_AVATAR = true                     # Sync GitHub avatars
```

**📖 Complete Guide:** [docs/authentication/github-oauth-setup.md](./docs/authentication/github-oauth-setup.md)

## AI Integration (Claude Assistant)

AtomicQMS includes AI-powered assistance for QMS workflows via the Claude API integrated through Gitea Actions.

### Features

- **SOP Review**: Automated document review for completeness and compliance
- **CAPA Guidance**: Structured assistance for corrective/preventive action documentation
- **Change Assessment**: Impact analysis for process and equipment changes
- **Compliance Checking**: FDA 21 CFR Part 11, ISO 13485, GxP compliance verification

### Quick Setup

```bash
# 1. Get runner token from Gitea
# Site Admin → Actions → Runners → Create new Runner

# 2. Run automated setup
chmod +x setup-claude-assistant.sh
./setup-claude-assistant.sh

# 3. Configure repository secrets (via Gitea UI)
# Settings → Secrets → Add:
#   ANTHROPIC_API_KEY or CLAUDE_CODE_OAUTH_TOKEN
#   GITEA_SERVER_URL

# 4. Test in PR/Issue
# Comment: @qms-assistant Hello!
```

### Workflow Files

- `.gitea/workflows/claude-qms-assistant.yml` - Main AI assistant workflow
- `.claude/qms-context.md` - QMS-specific context and guidelines

### Documentation

- **AI Integration Setup** (Anthropic API key): [docs/ai-integration/gitea-actions-setup.md](./docs/ai-integration/gitea-actions-setup.md)
- **Claude Code OAuth Setup** (Use Claude subscription): [docs/ai-integration/claude-code-oauth-setup.md](./docs/ai-integration/claude-code-oauth-setup.md)
- **QMS Workflows**: [docs/ai-integration/qms-workflows.md](./docs/ai-integration/qms-workflows.md)

### Security

- AI assistant has restricted tool access (Read, Edit, Grep, Glob only)
- No arbitrary command execution (Bash disabled)
- All interactions logged in PR/Issue comments and Actions logs
- API keys stored as encrypted repository secrets
