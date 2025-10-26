# AtomicQMS

**Containerized Quality Management for Agile Teams**

## Overview

AtomicQMS is a containerized, self-hosted Quality Management System designed for agile teams and modern lab environments. Built on a rebranded, lightweight Gitea core, each AtomicQMS instance serves as a standalone, browser-based QMS unit—complete with version-controlled SOPs, audit logs, and AI-assisted documentation workflows. It uses pull requests as process checkpoints, issues as CAPA or change-control records, and Markdown as the single-source format for procedural documentation. AtomicQMS delivers structured quality oversight without the bloat of traditional enterprise systems.

## Quick Start

```bash
# Start AtomicQMS
docker compose up -d

# Create admin user (first run only)
docker exec -it atomicqms gitea admin user create \
  --config /data/gitea/conf/app.ini \
  --username admin \
  --password 'YourSecurePassword' \
  --email admin@example.com \
  --admin

# Access web interface
open http://localhost:3001
```

## Architecture & Philosophy

Every AtomicQMS runs as a micro-deployed container that operates independently or within a fleet of other instances. This modular structure allows teams to spin up process-specific QMS modules—"Atomic Units"—for distinct workflows (e.g., assay validation, design control, analytical testing). Each unit retains its own change history, approvals, and compliance metadata while maintaining Git-level audit integrity and traceability.

### Key Features

- **Version-Controlled SOPs**: All documentation tracked in Git with full audit trails
- **Pull Request Workflows**: Process checkpoints through code review patterns
- **Issue-Based CAPA**: Change control and corrective actions as structured issues
- **Markdown-First**: Single-source documentation format for consistency
- **Modular Deployment**: Standalone instances or federated fleets
- **Browser-Based**: No desktop software required

## AI Integration

AtomicQMS integrates directly with LLM APIs (Claude, Codex, etc.) for AI-assisted drafting, document refinement, review summarization, and quality record completion. This reduces authoring time and ensures documentation consistency without relying on centralized QMS vendors or consultants.

## Target Market

Early-stage biotech, academic labs, and healthcare startups that need regulatory discipline without enterprise lock-in. AtomicQMS replaces rigid, legacy QMS suites with a modular, transparent, automation-friendly system. Users can deploy in minutes, operate offline, and scale to organization-wide compliance by linking multiple AtomicQMS instances.

## Strategic Direction

* Establish a growing **library of AtomicQMS templates** (SOP, CAPA, Audit, Change Control)
* Develop **AI-assisted routines** for continuous compliance validation and document lifecycle management
* Position AtomicQMS as the foundation for **compliance-on-demand infrastructure** in translational research and technical operations
* Explore integrations with lightweight LIMS and ELN tools for full digital lab coverage

## Technical Stack

- **Platform**: Docker Compose
- **Git Service**: Gitea (rebranded as AtomicQMS)
- **Database**: SQLite3
- **Configuration**: File-based (app.ini)
- **Data Persistence**: Local volumes with Git LFS support

## Service Access

- **Web Interface**: http://localhost:3001
- **SSH Git Access**: ssh://git@localhost:222
- **Container Name**: atomicqms

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

For complete documentation, see the [docs](./docs) folder or visit the full documentation site.

## License

[To be determined]

## Contact

For more information about AtomicQMS deployment and consulting:
- Folder: `/Dropbox/DEEPPROJECTS/AtomicQMS`
