# AtomicQMS

**Containerized Quality Management for Agile Teams**

## Overview

AtomicQMS is a containerized, self-hosted Quality Management System designed for agile teams and modern lab environments. Built on a rebranded, lightweight Gitea core, each AtomicQMS instance serves as a standalone, browser-based QMS unit—complete with version-controlled SOPs, audit logs, and AI-assisted documentation workflows. It uses pull requests as process checkpoints, issues as CAPA or change-control records, and Markdown as the single-source format for procedural documentation. AtomicQMS delivers structured quality oversight without the bloat of traditional enterprise systems.

## Quick Start

### Option 1: Automated Setup (Recommended)

The setup script automatically checks all prerequisites before starting:
- Docker availability and status
- Port availability (3001, 222)
- Disk space (minimum 2GB)
- AI credentials (for standard/full setup)
- Required configuration files

```bash
# One-command setup with guided prompts
./setup-all.sh

# Or choose your setup level:
./setup-all.sh --minimal    # Just server (no AI)
./setup-all.sh --full       # Everything (server + AI + organization)
```

If prerequisites are missing, you'll get clear instructions to fix them before the setup begins.

### Option 2: Manual Setup

```bash
# Start AtomicQMS
docker compose up -d

# Create admin user (first run only)
docker exec -u git atomicqms gitea admin user create \
  --username admin \
  --password 'YourSecurePassword' \
  --email admin@example.com \
  --admin

# Access web interface
open http://localhost:3001
```

### Which Setup Should I Choose?

| I want... | Run this | Time |
|-----------|----------|------|
| Just try AtomicQMS | `./setup-all.sh --minimal` | 2 min |
| AtomicQMS + AI assistant | `./setup-all.sh` → choose "Standard" | 5 min |
| Full team setup (recommended for labs) | `./setup-all.sh --full` | 8 min |
| Manual control of every step | See [SETUP.md](./SETUP.md) | 15-30 min |

## Architecture & Philosophy

Every AtomicQMS runs as a micro-deployed container that operates independently or within a fleet of other instances. This modular structure allows teams to spin up process-specific QMS modules—"Atomic Units"—for distinct workflows (e.g., assay validation, design control, analytical testing). Each unit retains its own change history, approvals, and compliance metadata while maintaining Git-level audit integrity and traceability.

### Key Features

- **Version-Controlled SOPs**: All documentation tracked in Git with full audit trails
- **Pull Request Workflows**: Process checkpoints through code review patterns
- **Issue-Based CAPA**: Change control and corrective actions as structured issues
- **Markdown-First**: Single-source documentation format for consistency
- **Modular Deployment**: Standalone instances or federated fleets
- **Browser-Based**: No desktop software required
- **GitHub OAuth**: Single Sign-On authentication with GitHub accounts

## AI Integration

AtomicQMS features an integrated Claude AI Assistant that works directly within your Pull Requests and Issues. Simply mention `@qms-assistant` to get intelligent help with:

- **SOP Review**: Automated completeness and compliance checking
- **CAPA Documentation**: Structured guidance for root cause analysis and corrective actions
- **Change Impact Assessment**: Analyze effects of process or equipment changes
- **Compliance Verification**: Check against FDA 21 CFR Part 11, ISO 13485, GxP requirements

The AI assistant understands QMS terminology, regulatory requirements, and maintains context throughout your workflow. All interactions are logged for audit purposes.

**Quick Setup:**

1. Get runner token from Gitea: Site Admin → Actions → Runners → Create new Runner
2. Run the setup script: `./setup-claude-assistant.sh`
3. **Set global credentials** in `.env` file (works for ALL repositories):
   ```bash
   # Add ONE of these to your .env file:
   ANTHROPIC_API_KEY=sk-ant-xxxxx        # Option 1: Direct API access
   CLAUDE_CODE_OAUTH_TOKEN=your-token    # Option 2: Claude Max users
   ```
4. Restart runner: `docker compose restart runner`
5. Test by commenting: `@qms-assistant Hello!`

**No per-repository configuration needed!** The AI assistant now works in all repositories automatically.

**📖 Complete Setup Guides:**
- **Anthropic API Key**: [docs/ai-integration/gitea-actions-setup.md](./docs/ai-integration/gitea-actions-setup.md)
- **Claude Code OAuth**: [docs/ai-integration/claude-code-oauth-setup.md](./docs/ai-integration/claude-code-oauth-setup.md)

### Template Repository (Recommended)

The easiest way to create new QMS repositories with AI assistant pre-configured is using the template repository feature:

```bash
./setup-template-repository.sh
```

This creates a reusable template repository (`atomicqms-template`) in your Gitea instance. When you create a new repository, simply select this template from the dropdown menu, and Gitea will automatically:

- Copy all AI assistant files and configurations
- Set up the complete QMS directory structure (SOPs, CAPAs, forms, training)
- Substitute repository-specific variables (name, owner, dates)
- Include sample SOP and CAPA templates
- Initialize with proper .gitignore and documentation

**Benefits:**
- **User Control**: You choose when to use the template
- **Variable Substitution**: Built-in Gitea feature replaces `$REPO_NAME`, `$REPO_OWNER`, `$YEAR-$MONTH-$DAY` automatically
- **Multiple Templates**: Create different templates for different use cases (clinical, manufacturing, etc.)
- **Zero Maintenance**: No background services required
- **Preview Before Use**: See template contents before creating your repository

**Usage:**
1. Run setup script once: `./setup-template-repository.sh`
2. When creating new repository: Select "atomicqms-template" from template dropdown
3. **That's it!** If you set global credentials in `.env`, the AI assistant works immediately
4. (Optional) Override credentials per-repository in Settings → Secrets:
   - `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` - Override global credentials
   - `QMS_SERVER_URL` - Only for production with public URLs
5. Start documenting!

**📖 Complete Guide:** [docs/ai-integration/template-repository-setup.md](./docs/ai-integration/template-repository-setup.md)

###  Automatic Repository Initialization

Want the AI assistant files added to every new repository automatically? Enable the auto-init service:

```bash
./setup-auto-init.sh
```

The service runs in the background and automatically commits AI assistant files (`.gitea/workflows/claude-qms-assistant.yml` and `.claude/qms-context.md`) to any repository that doesn't have them.

- **Periodic Scanning**: Checks all repositories every 5 minutes (configurable)
- **Smart Detection**: Only adds files to repos that need them
- **Zero Maintenance**: Runs automatically in Docker container
- **Fully Logged**: All operations tracked for audit purposes

See [auto-init-service/README.md](./auto-init-service/README.md) for configuration and troubleshooting.

## Target Market

Early-stage biotech, academic labs, and healthcare startups that need regulatory discipline without enterprise lock-in. AtomicQMS replaces rigid, legacy QMS suites with a modular, transparent, automation-friendly system. Users can deploy in minutes, operate offline, and scale to organization-wide compliance by linking multiple AtomicQMS instances.

## Strategic Direction

* Establish a growing **library of AtomicQMS templates** (SOP, CAPA, Audit, Change Control)
* Develop **AI-assisted routines** for continuous compliance validation and document lifecycle management
* Position AtomicQMS as the foundation for **compliance-on-demand infrastructure** in translational research and technical operations
* Explore integrations with lightweight LIMS and ELN tools for full digital lab coverage

---

## Authentication

> **Note:** This section covers **user authentication** (how users sign into AtomicQMS).
> For **AI assistant authentication**, see [AI Integration](#ai-integration) below.

### GitHub OAuth (Single Sign-On)

AtomicQMS supports GitHub OAuth for Single Sign-On authentication, allowing users to sign in with their GitHub accounts instead of creating local credentials.

**Features:**
- Single Sign-On with GitHub accounts
- Automatic user registration on first login
- Profile sync (username, email, avatar from GitHub)
- Minimal OAuth scopes (read:user, user:email)

**Quick Setup:**

1. Create a GitHub OAuth App at https://github.com/settings/developers
2. Configure credentials in `.env` file
3. Run the setup script: `./setup-github-oauth.sh`
4. Users can now sign in with GitHub!

**📖 Complete Setup Guide:** See [docs/authentication/github-oauth-setup.md](./docs/authentication/github-oauth-setup.md) for:
- Step-by-step instructions with screenshots
- Prerequisites and verification steps
- Troubleshooting common issues
- Production deployment considerations
- Security best practices

**Quick Troubleshooting:**
- No "Sign in with GitHub" button? Run `./setup-github-oauth.sh`
- Credential errors? Verify Client ID and Secret match your GitHub OAuth App
- Redirect URI mismatch? Callback URL must be: `http://localhost:3001/user/oauth2/github/callback`

---

## Technical Stack

- **Platform**: Docker Compose
- **Git Service**: Gitea (rebranded as AtomicQMS)
- **Database**: SQLite3
- **Authentication**: GitHub OAuth + local accounts
- **Configuration**: File-based (app.ini)
- **Data Persistence**: Local volumes with Git LFS support

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

## Custom Branding

AtomicQMS supports custom logo branding to replace the default Gitea teacup icon:

1. **Add your logo files**:
   ```bash
   # Place your SVG logos in the public assets directory
   cp /path/to/your/logo.svg gitea/public/assets/img/logo.svg
   cp /path/to/your/full-logo.svg gitea/public/assets/img/logo-full.svg
   ```

2. **Restart the container**:
   ```bash
   docker compose restart
   ```

3. **Clear browser cache**: Press `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows/Linux)

**How it works**: Files in `gitea/public/` override Gitea's embedded assets. The logo appears in the header, navigation, and as the site icon.

**Requirements**:
- Format: SVG (Scalable Vector Graphics)
- Naming: Must be named `logo.svg` for the mini logo
- Optional: Add `logo-full.svg` for larger branding areas

See `gitea/public/README.md` for detailed customization options.

## Documentation

For complete documentation, see:
- `CLAUDE.md` - Technical documentation and configuration details
- `docs/` folder - Additional documentation and guides

## License

[To be determined]

## Contact

For more information about AtomicQMS deployment and consulting:
- Folder: `/Dropbox/DEEPPROJECTS/AtomicQMS`
