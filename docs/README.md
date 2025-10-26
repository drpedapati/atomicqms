---
home: true
heroText: AtomicQMS
tagline: Containerized Quality Management for Agile Teams
actions:
  - text: Get Started
    link: /guide/
    type: primary
  - text: Quick Start
    link: /guide/quick-start.html
    type: secondary
features:
  - title: Version-Controlled SOPs
    details: All documentation tracked in Git with full audit trails. Every change is recorded, reviewed, and traceable.
  - title: Pull Request Workflows
    details: Use familiar code review patterns as process checkpoints. Approvals become merge operations with full traceability.
  - title: Issue-Based CAPA
    details: Change control and corrective actions structured as issues with labels, assignments, and lifecycle tracking.
  - title: Markdown-First
    details: Single-source documentation format ensures consistency and enables automation without vendor lock-in.
  - title: Modular Deployment
    details: Standalone instances or federated fleets. Deploy process-specific QMS modules as "Atomic Units" for distinct workflows.
  - title: AI Integration
    details: Built-in support for LLM APIs (Claude, Codex) for document drafting, review summarization, and quality record completion.
footer: AtomicQMS - Quality Management for Modern Labs
---

## What is AtomicQMS?

AtomicQMS is a containerized, self-hosted Quality Management System designed for agile teams and modern lab environments. Built on a rebranded, lightweight Gitea core, each AtomicQMS instance serves as a standalone, browser-based QMS unit—complete with version-controlled SOPs, audit logs, and AI-assisted documentation workflows.

## Why AtomicQMS?

Traditional enterprise QMS platforms are rigid, expensive, and designed for large organizations with complex hierarchies. AtomicQMS takes a different approach:

- **Deploy in Minutes**: Docker-based deployment with pre-configured templates
- **Git-Level Audit Integrity**: Every change is tracked with cryptographic verification
- **No Vendor Lock-In**: Markdown files and standard Git operations
- **AI-Powered**: Reduce documentation time with integrated LLM support
- **Modular Architecture**: Spin up process-specific instances as needed

## Who is it For?

- **Early-stage Biotech**: Establish regulatory discipline without enterprise overhead
- **Academic Labs**: Maintain compliance while staying agile
- **Healthcare Startups**: Build quality systems that scale with your organization
- **Technical Operations**: Integrate with existing LIMS and ELN tools

## Quick Example

```bash
# Deploy AtomicQMS
docker compose up -d

# Create admin user
docker exec -it atomicqms gitea admin user create \
  --username admin \
  --password 'YourSecurePassword' \
  --email admin@example.com \
  --admin

# Access at http://localhost:3001
```

## Philosophy

Every AtomicQMS runs as a micro-deployed container that operates independently or within a fleet of other instances. This modular structure allows teams to spin up process-specific QMS modules—"Atomic Units"—for distinct workflows (e.g., assay validation, design control, analytical testing). Each unit retains its own change history, approvals, and compliance metadata while maintaining Git-level audit integrity and traceability.

## Ready to Get Started?

::: tip
Check out the [Getting Started Guide](/guide/) to deploy your first AtomicQMS instance.
:::
