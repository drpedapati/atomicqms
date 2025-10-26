# Core Concepts

Understanding the fundamental concepts behind AtomicQMS will help you make the most of the platform.

## The Atomic Philosophy

AtomicQMS is built on the principle of **modular, composable quality units**. Unlike monolithic QMS platforms, AtomicQMS allows you to:

- Deploy focused, process-specific QMS instances
- Link instances together as needed
- Scale from single-process to organization-wide
- Maintain independence and flexibility

### Why "Atomic"?

Just as atoms are the fundamental building blocks of matter, AtomicQMS instances are the fundamental building blocks of your quality system. Each instance:

- Is self-contained and complete
- Can exist independently
- Can combine with others to form larger structures
- Maintains its identity within larger systems

## Git as the Foundation

Traditional QMS platforms use proprietary databases and workflows. AtomicQMS uses **Git** as its foundation, providing:

### Cryptographic Integrity

Every commit in Git is cryptographically hashed, creating an immutable audit trail. Tampering with history is immediately detectable.

### Distributed Architecture

Git's distributed nature means:
- Every clone is a complete backup
- Work offline without interruption
- Sync changes when convenient
- No single point of failure

### Industry-Standard Tools

By using Git, you gain access to:
- Decades of tooling development
- Widespread developer knowledge
- Integration with CI/CD pipelines
- Battle-tested workflows

## Version Control as Quality Control

AtomicQMS reimagines quality processes as version control operations:

| QMS Process | Git Operation | Benefit |
|-------------|---------------|---------|
| Document creation | Commit | Timestamped, attributed |
| Review process | Pull request | Multi-reviewer workflow |
| Approval | Merge | Gated transition |
| Change control | Branch/PR | Isolated changes |
| Audit trail | Git log | Complete history |
| Document versions | Tags | Semantic versioning |

## Markdown: The Universal Format

AtomicQMS uses Markdown as the single-source format for all documentation:

### Benefits of Markdown

- **Plain Text**: No proprietary formats, always readable
- **Version Control Friendly**: Easy to diff and merge
- **Widely Supported**: Thousands of tools available
- **Future-Proof**: Will be readable in decades
- **Automation-Friendly**: Easy to parse and generate

### Markdown to Multiple Formats

From a single Markdown source, you can generate:
- PDF documents for formal submissions
- HTML for web viewing
- Word documents for collaboration
- LaTeX for scientific publications

## Process Patterns

### Pull Request Workflow

AtomicQMS uses pull requests as the core approval mechanism:

```
Draft Document → Create PR → Request Reviews → Address Comments → Approval → Merge
```

This provides:
- **Transparency**: All discussions visible
- **Accountability**: Reviewers explicitly listed
- **Traceability**: Complete thread of decisions
- **Flexibility**: Multiple reviewers, staged approvals

### Issue-Based CAPA

Corrective and Preventive Actions become structured issues:

1. **Creation**: Issue opened with CAPA template
2. **Investigation**: Comments document findings
3. **Action Plan**: Checklist in issue body
4. **Implementation**: Linked commits/PRs
5. **Verification**: Review and testing
6. **Closure**: Issue closed with summary

### Branch-Based Change Control

Changes are developed in isolated branches:

```
main (production)
  ├── feature/sop-update (in progress)
  ├── hotfix/typo-correction (urgent)
  └── release/v2.0 (staging)
```

Benefits:
- **Isolation**: Changes don't affect production
- **Parallel Work**: Multiple changes simultaneously
- **Testing**: Verify before release
- **Rollback**: Easy to revert if needed

## Modular Architecture

### Single Instance

Start with one instance for a specific need:
- SOP management
- CAPA tracking
- Change control

### Federated Instances

Link multiple instances for larger organizations:
- Quality Management
- Manufacturing
- Laboratory Operations
- Regulatory Affairs

Each maintains independence while sharing standards.

### Instance Types

Common instance patterns:

- **Document Control**: Central SOP repository
- **Change Control**: Change requests and evaluations
- **CAPA Management**: Corrective/preventive actions
- **Training Records**: Personnel qualification tracking
- **Equipment Management**: Calibration and maintenance
- **Supplier Quality**: Vendor qualifications and audits

## AI Integration Model

AtomicQMS treats AI as a **writing assistant**, not a replacement for human judgment:

### AI Roles

- **Draft Generation**: Create initial document versions
- **Review Summarization**: Condense feedback threads
- **Template Population**: Fill standard forms
- **Consistency Checking**: Flag deviations from standards
- **Search Enhancement**: Semantic document discovery

### Human Oversight

All AI-generated content requires:
- Human review and approval
- Attribution of AI assistance
- Validation against requirements
- Final sign-off by qualified personnel

## Next Steps

Now that you understand the core concepts, explore:

- [Working with SOPs](./sops.md) - SOP lifecycle management
- [CAPA Workflows](./capa.md) - Corrective actions in practice
- [Architecture Details](/architecture/) - Technical deep dive
- [AI Integration](/ai-integration/) - Setting up AI features
