# Getting Started

Welcome to AtomicQMS! This guide will help you understand the fundamentals of AtomicQMS and get your first instance up and running.

## What You'll Learn

In this guide, you'll learn:

- Core concepts behind AtomicQMS
- How to deploy your first instance
- Working with version-controlled SOPs
- Managing change control through pull requests
- Implementing CAPA workflows with issues
- Integrating AI assistance for documentation

## Prerequisites

Before you begin, ensure you have:

- Docker and Docker Compose installed
- Basic understanding of Git version control
- A modern web browser
- (Optional) API access to LLM services for AI features

## Key Concepts

### Atomic Units

AtomicQMS instances are called "Atomic Units" - self-contained QMS modules that handle specific workflows or processes. Each unit:

- Operates independently with its own Git repository
- Maintains complete audit trails
- Can be linked to other units for organization-wide compliance
- Scales from single-process to enterprise deployments

### Git-Based Version Control

Unlike traditional QMS platforms, AtomicQMS uses Git as its core version control system. This provides:

- **Cryptographic Integrity**: Every change is cryptographically signed
- **Complete History**: Never lose track of document evolution
- **Branching Workflows**: Test changes before implementation
- **Familiar Tools**: Use standard Git operations and interfaces

### Markdown-First Documentation

All SOPs, procedures, and quality records are written in Markdown. Benefits include:

- Plain text format - no proprietary file formats
- Version control friendly
- Easy to read and edit
- Export to multiple formats (PDF, HTML, etc.)
- Automation-friendly

### Pull Request Approvals

Process checkpoints become pull request reviews:

- **Draft → Review → Approve → Merge**
- Multiple reviewers with required approvals
- Discussion threads for clarification
- Automatic audit trail generation

### Issue-Based CAPA

Change control and corrective actions use issue tracking:

- Structured templates for CAPA records
- Labels for categorization
- Assignments and due dates
- Lifecycle tracking from open to closed

## Next Steps

Ready to dive in? Check out the [Quick Start Guide](./quick-start.md) to deploy your first AtomicQMS instance.

Or explore:

- [Core Concepts](./core-concepts.md) - Deep dive into AtomicQMS philosophy
- [Architecture](/architecture/) - Technical details of the platform
- [Deployment Guide](/deployment/) - Production deployment strategies
