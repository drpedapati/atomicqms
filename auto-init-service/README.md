# AtomicQMS Auto-Init Service

Automatically initializes new repositories with AI assistant integration files.

## What It Does

The Auto-Init service periodically scans all repositories in your AtomicQMS instance and automatically adds AI assistant files to any repository that doesn't have them yet.

**Files automatically added:**
- `.gitea/workflows/claude-qms-assistant.yml` - Gitea Actions workflow for Claude AI
- `.claude/qms-context.md` - QMS-specific context and guidelines

## Quick Start

```bash
# From the AtomicQMS root directory
./setup-auto-init.sh
```

That's it! The service will start running in the background.

## How It Works

1. **Periodic Scanning**: Every 5 minutes (configurable), the service scans all repositories
2. **Smart Detection**: Checks if each repository already has the AI assistant files
3. **Automatic Initialization**: Commits missing files with a descriptive commit message
4. **Idempotent**: Safe to run multiple times - only initializes repos that need it

## Architecture

```
┌─────────────────────────────────────────┐
│  AtomicQMS (Gitea)                      │
│  ┌────────────────────────────────────┐ │
│  │  Repository Storage                 │ │
│  │  /data/git/repositories/            │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
                 ▲
                 │ (shared volume)
                 │
┌─────────────────────────────────────────┐
│  Auto-Init Service                      │
│  ┌────────────────────────────────────┐ │
│  │  Periodic Scanner (every 5 min)    │ │
│  │  - Find all repositories           │ │
│  │  - Check for AI assistant files    │ │
│  │  - Commit missing files            │ │
│  └────────────────────────────────────┘ │
│  ┌────────────────────────────────────┐ │
│  │  Templates                          │ │
│  │  - claude-qms-assistant.yml        │ │
│  │  - qms-context.md                  │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## Configuration

### Environment Variables

Configure in your `.env` file:

```bash
# Container name
ATOMICQMS_AUTO_INIT_CONTAINER=atomicqms-auto-init

# Git commit author info
AUTO_INIT_GIT_USER_NAME=AtomicQMS Auto-Init
AUTO_INIT_GIT_USER_EMAIL=autoinit@atomicqms.local

# How often to scan (in seconds)
AUTO_INIT_CHECK_INTERVAL=300  # Default: 5 minutes
```

### Customizing Templates

The service copies files from `auto-init-service/templates/`. To customize:

1. Edit files in `auto-init-service/templates/`:
   - `.gitea/workflows/claude-qms-assistant.yml`
   - `.claude/qms-context.md`

2. Rebuild the service:
   ```bash
   docker compose --profile auto-init down auto-init
   docker compose --profile auto-init build auto-init
   docker compose --profile auto-init up -d auto-init
   ```

## Usage

### Start the Service

```bash
# Using the setup script (recommended)
./setup-auto-init.sh

# Or manually with docker compose
docker compose --profile auto-init up -d auto-init
```

### View Logs

```bash
# View logs
docker logs atomicqms-auto-init

# Follow logs in real-time
docker logs -f atomicqms-auto-init
```

### Manual Trigger

```bash
# Force an immediate scan (doesn't wait for interval)
docker compose --profile auto-init exec auto-init /app/auto-init.sh
```

### Dry Run Mode

Test what the service would do without making changes:

```bash
docker compose --profile auto-init exec -e DRY_RUN=true auto-init /app/auto-init.sh
```

### Stop the Service

```bash
# Stop auto-init (keeps other services running)
docker compose --profile auto-init down auto-init

# Or stop everything
docker compose --profile auto-init down
```

## Troubleshooting

### Service Won't Start

1. **Check Docker build logs:**
   ```bash
   docker compose --profile auto-init build auto-init
   ```

2. **Verify template files exist:**
   ```bash
   ls -la auto-init-service/templates/.gitea/workflows/
   ls -la auto-init-service/templates/.claude/
   ```

3. **Check container logs:**
   ```bash
   docker logs atomicqms-auto-init
   ```

### Files Not Being Added

1. **Check if repository is empty:**
   - Service only processes repos with at least one commit
   - Push an initial commit to trigger initialization

2. **Verify service is running:**
   ```bash
   docker ps | grep auto-init
   ```

3. **Check scan interval:**
   - Default is 5 minutes
   - Trigger manually for immediate results:
     ```bash
     docker compose --profile auto-init exec auto-init /app/auto-init.sh
     ```

4. **Review service logs:**
   ```bash
   docker logs -f atomicqms-auto-init
   ```

### Permission Issues

If the service can't write to repositories:

1. **Check volume mount:**
   ```bash
   docker inspect atomicqms-auto-init | grep -A 5 Mounts
   ```

2. **Verify git directory permissions:**
   ```bash
   ls -la gitea/git/repositories/
   ```

3. **Ensure service user has access:**
   - Service runs as user ID 1000
   - Gitea also uses UID 1000 by default

## Advanced

### Changing Scan Interval

Update `.env`:
```bash
# Scan every minute (for testing)
AUTO_INIT_CHECK_INTERVAL=60

# Scan every 30 minutes
AUTO_INIT_CHECK_INTERVAL=1800
```

Then restart:
```bash
docker compose --profile auto-init restart auto-init
```

### Running Without Docker Compose Profile

To always start auto-init with other services, remove the `profiles:` section from `docker-compose.yml`:

```yaml
# Before
auto-init:
  ...
  profiles:
    - auto-init  # Remove these lines

# After
auto-init:
  ...
  # No profiles section
```

Then `docker compose up -d` will start everything including auto-init.

### Integration with CI/CD

The service can run alongside your existing Gitea Actions workflows. It won't interfere with manual commits or CI/CD operations.

## Files

- `Dockerfile` - Container definition
- `auto-init.sh` - Main initialization script
- `templates/` - Files to copy to new repositories
  - `.gitea/workflows/claude-qms-assistant.yml`
  - `.claude/qms-context.md`
- `README.md` - This file

## Security Considerations

- Service has **write access** to all repositories
- Commits are signed with configured author info
- Service runs as non-root user (UID 1000)
- Only adds files, never modifies existing content
- Audit trail in Git history shows all auto-init commits

## Support

For issues or questions:
- Check logs: `docker logs atomicqms-auto-init`
- Review main AtomicQMS documentation
- Open an issue in the repository
