# $REPO_NAME

**Quality Management System Repository**

Created from [AtomicQMS Template](https://github.com/your-org/atomicqms-template)
Owner: $REPO_OWNER
Repository: $REPO_LINK

## Overview

This repository is part of your AtomicQMS implementation. It includes:

- **AI-Assisted Documentation**: Claude AI assistant integrated for document review and compliance checking
- **Version Control**: Full Git-based audit trail for all changes
- **Workflow Automation**: Gitea Actions for automated quality checks
- **QMS Structure**: Pre-configured directory structure for SOPs, forms, and CAPA records

## AI Assistant

This repository includes the AtomicQMS AI Assistant. To use it:

### In Issues or Pull Requests

```
@qms-assistant Please review this SOP for ISO 13485 compliance
```

The AI assistant can help with:
- SOP review and compliance checking
- CAPA documentation guidance
- Change impact assessments
- Regulatory requirement verification

### Configuration Required

For the AI assistant to work, you must configure repository secrets:

1. Go to **Settings → Secrets**
2. Add required secrets:
   - `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN`
   - `GITEA_SERVER_URL` (your AtomicQMS URL)

See the [AI Integration Guide]($TEMPLATE_LINK/docs/ai-integration/) for details.

## Directory Structure

```
├── docs/
│   ├── sops/          # Standard Operating Procedures
│   ├── forms/         # Quality forms and templates
│   └── capas/         # CAPA (Corrective/Preventive Action) records
├── .gitea/
│   └── workflows/     # Gitea Actions workflows
└── .claude/           # AI assistant configuration
```

## Quick Start

### 1. Configure AI Assistant Secrets

```bash
# Via Gitea Web UI
Repository → Settings → Secrets → Add Secret

# Required:
ANTHROPIC_API_KEY=sk-ant-api03-...
GITEA_SERVER_URL=http://your-atomicqms-url:3001
```

### 2. Create Your First SOP

```bash
# Copy the sample SOP
cp docs/sops/SOP-TEMPLATE.md docs/sops/SOP-001-your-process.md

# Edit and commit
git add docs/sops/SOP-001-your-process.md
git commit -m "Add SOP-001: Your Process Name"
git push
```

### 3. Get AI Review

1. Create a Pull Request for your SOP
2. Add comment: `@qms-assistant Please review for compliance`
3. The AI will analyze and provide feedback

## Workflow

### Document Changes
1. Create feature branch: `git checkout -b update/sop-001`
2. Make changes to documentation
3. Commit with descriptive message
4. Push and create Pull Request
5. Request AI review: `@qms-assistant review`
6. Address feedback
7. Merge when approved

### CAPA Process
1. Create issue for non-conformance
2. Use CAPA template in `docs/capas/`
3. Document root cause analysis
4. Define corrective actions
5. Get AI assistance: `@qms-assistant help with root cause analysis`
6. Track implementation
7. Verify effectiveness

## Best Practices

### Commit Messages
- Use clear, descriptive messages
- Reference issue numbers when applicable
- Follow format: `type(scope): description`

Examples:
```
docs(sop): Update temperature monitoring procedure
fix(form): Correct sample ID format in chain of custody
feat(capa): Add new deviation tracking process
```

### Branching Strategy
- `main` - Production-ready documentation
- `feature/*` - New SOPs or major updates
- `update/*` - Minor updates to existing docs
- `hotfix/*` - Urgent corrections

### Pull Request Guidelines
1. One logical change per PR
2. Include clear description of changes
3. Request AI review for compliance
4. Link related issues
5. Ensure all checks pass before merging

## Compliance

This repository supports the following regulatory frameworks:

- FDA 21 CFR Part 11 (Electronic Records)
- ISO 13485 (Medical Devices Quality Management)
- GxP (Good Practice) guidelines
- ICH Q9 (Quality Risk Management)

The AI assistant is trained on these standards and can help ensure compliance.

## Support

- **AI Assistant**: `@qms-assistant` in any issue or PR
- **Documentation**: See [AtomicQMS Docs]($TEMPLATE_LINK/docs/)
- **Issues**: Report problems in this repository's issue tracker

## Template Information

This repository was created from the AtomicQMS template repository.

- **Template**: $TEMPLATE_NAME
- **Template Owner**: $TEMPLATE_OWNER
- **Template Link**: $TEMPLATE_LINK
- **Created**: $YEAR-$MONTH-$DAY

---

🤖 This repository includes AI assistance powered by Claude
📋 Part of the AtomicQMS ecosystem
