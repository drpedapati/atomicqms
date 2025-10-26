# Architecture Overview

AtomicQMS is built on a modular, container-based architecture designed for flexibility, scalability, and maintainability.

## System Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Browser Client                     │
│                  (Web Interface)                     │
└─────────────────┬───────────────────────────────────┘
                  │ HTTP/HTTPS
                  │ SSH (Git)
┌─────────────────▼───────────────────────────────────┐
│              AtomicQMS Container                     │
│  ┌──────────────────────────────────────────────┐   │
│  │           Gitea Application                  │   │
│  │  (Rebranded as AtomicQMS)                   │   │
│  └─────────────┬────────────────────────────────┘   │
│                │                                     │
│  ┌─────────────▼────────────────────────────────┐   │
│  │         SQLite Database                      │   │
│  │  - Users & Authentication                    │   │
│  │  - Repository Metadata                       │   │
│  │  - Issues & Pull Requests                    │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │      Git Repositories (File System)          │   │
│  │  - Document Storage                          │   │
│  │  - Version History                           │   │
│  │  - Large File Support (LFS)                  │   │
│  └──────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────┘
```

## Core Components

### Gitea Foundation

AtomicQMS is built on Gitea, a lightweight, self-hosted Git service. Gitea provides:

- **Git Server**: Complete Git hosting with SSH and HTTPS
- **Web Interface**: Browser-based repository management
- **Pull Requests**: Code review workflows
- **Issue Tracking**: Task and bug management
- **User Management**: Authentication and authorization
- **API**: RESTful API for automation

### SQLite Database

Uses SQLite for:
- User accounts and permissions
- Repository metadata
- Issue and PR data
- Activity logs
- Configuration settings

**Benefits**:
- Zero configuration
- File-based (easy backup)
- No separate database server
- Excellent performance for this use case

### Git Repositories

Core document storage using bare Git repositories:
- One repository per document collection
- Git LFS for large files (PDFs, images)
- All files tracked with full history
- Cryptographic integrity

### Container Platform

Docker-based deployment:
- Single container for simplicity
- Volume mounts for persistence
- Port mapping for access
- Easy updates and rollback

## Data Flow

### Document Creation

```
User creates document → Commit to branch → Push to server →
Store in Git repo → Update SQLite metadata → Notify watchers
```

### Pull Request Workflow

```
Create PR → Request reviews → Reviewers comment →
Author updates → Approvals collected → Merge to main →
Close PR → Update issue links → Generate audit trail
```

### Issue Management

```
Create issue → Assign personnel → Add labels →
Link to commits/PRs → Discussion thread →
Mark complete → Close with resolution
```

## Scalability Model

### Single Instance

**Capacity**:
- Users: 100-500
- Repositories: Hundreds
- Storage: Terabytes (with LFS)
- Performance: Excellent on modest hardware

**Use Case**:
- Small organizations
- Department-level QMS
- Pilot implementations

### Multi-Instance Federation

**Architecture**:
- Multiple independent AtomicQMS instances
- Shared user authentication (LDAP/SSO)
- Cross-instance references
- Centralized backup/monitoring

**Use Case**:
- Enterprise deployments
- Multi-site organizations
- Isolated compliance domains

## Security Architecture

### Authentication

- Built-in user database
- LDAP/Active Directory integration
- OAuth2/OpenID Connect support
- Two-factor authentication
- API token management

### Authorization

- Role-based access control (RBAC)
- Repository-level permissions
- Branch protection rules
- Required reviewers
- Signed commits

### Audit Trail

- Every Git operation logged
- User actions tracked
- API calls recorded
- Export for compliance review

## Integration Points

### Git Operations

Standard Git protocols:
```bash
# Clone repository
git clone http://localhost:3001/qms/sops.git

# Push changes
git push origin feature/new-sop

# Pull updates
git pull origin main
```

### REST API

Programmatic access:
```bash
# Create repository
curl -X POST http://localhost:3001/api/v1/user/repos \
  -H "Authorization: token YOUR_TOKEN" \
  -d '{"name":"new-repo"}'

# List issues
curl http://localhost:3001/api/v1/repos/qms/sops/issues
```

### Webhooks

Event notifications:
- PR created/merged
- Issue opened/closed
- Commits pushed
- Tags created

Integrate with:
- CI/CD pipelines
- Notification systems
- External QMS tools
- Document management systems

## Deployment Patterns

### Development

```yaml
# Simple Docker Compose
services:
  atomicqms:
    image: gitea/gitea:latest
    ports:
      - "3001:3000"
    volumes:
      - ./data:/data
```

### Production

Additional considerations:
- Reverse proxy (nginx/traefik)
- TLS certificates
- Regular backups
- Monitoring/alerting
- Log aggregation
- Resource limits

## Data Persistence

### Volumes

Three key data locations:
1. `/data/git/repositories/` - Git repos
2. `/data/gitea.db` - SQLite database
3. `/data/gitea/conf/app.ini` - Configuration

### Backup Strategy

**Full Backup**:
```bash
# Stop container
docker compose down

# Backup data directory
tar -czf backup.tar.gz ./data

# Restart
docker compose up -d
```

**Incremental**:
- Database: SQLite backup command
- Repositories: Git bundle or rsync

## Performance Characteristics

### Resource Usage

Typical single instance:
- **CPU**: Low (spikes during Git operations)
- **RAM**: 256MB-1GB (depends on users)
- **Disk I/O**: Moderate (mostly reads)
- **Network**: Low bandwidth

### Bottlenecks

Potential limitations:
- SQLite concurrent writes (not typically an issue)
- Large repository operations
- Many simultaneous users (100+)

Solutions:
- PostgreSQL for larger deployments
- Git LFS for large files
- Caching strategies

## Next Steps

Explore specific architectural topics:

- [Modular Design](./modular-design.md) - Atomic Units in depth
- [Git-Based Audit](./git-based-audit.md) - Cryptographic integrity
- [Deployment Guide](/deployment/) - Production setup
