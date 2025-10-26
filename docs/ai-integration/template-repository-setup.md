# Template Repository Setup Guide

This guide explains how to set up and use the AtomicQMS template repository feature, which provides the easiest way to create new QMS repositories with AI assistant integration pre-configured.

## Table of Contents

- [Overview](#overview)
- [Benefits of Template Repositories](#benefits-of-template-repositories)
- [Prerequisites](#prerequisites)
- [Setup: Creating the Template](#setup-creating-the-template)
- [Usage: Creating Repositories from Template](#usage-creating-repositories-from-template)
- [Variable Substitution](#variable-substitution)
- [Template Contents](#template-contents)
- [Customizing the Template](#customizing-the-template)
- [Troubleshooting](#troubleshooting)

## Overview

The AtomicQMS template repository provides a pre-configured starting point for new QMS repositories. When you create a new repository from the template, Gitea automatically:

1. Copies all template files
2. Substitutes variables with repository-specific values
3. Initializes the repository with a complete QMS structure
4. Pre-configures AI assistant integration

**User Control**: Each user explicitly chooses when to create a repository from the template. No automatic initialization occurs.

## Benefits of Template Repositories

Compared to automatic initialization:

| Feature | Template Repository | Auto-Init Service |
|---------|-------------------|-------------------|
| **User Control** | ✓ Explicit choice | ✗ Automatic |
| **Variable Substitution** | ✓ Built-in | ✗ Requires custom code |
| **Repository Diversity** | ✓ Multiple templates | ✗ One configuration |
| **Maintenance** | ✓ Gitea built-in | ✗ Custom service |
| **Testing** | ✓ Preview before use | ✗ Affects all repos |
| **Performance** | ✓ One-time operation | ✗ Periodic scanning |

## Prerequisites

Before setting up the template repository:

1. **AtomicQMS Running**
   ```bash
   docker ps | grep atomicqms
   ```

2. **User Account Created**
   - You need a Gitea user account with repository creation permissions
   - See main README.md for creating admin user

3. **Template Files Available**
   - The `template-qms-repository/` directory exists in your AtomicQMS installation
   - Contains AI assistant workflow, QMS structure, and sample documents

## Setup: Creating the Template

### Automated Setup (Recommended)

Run the provided setup script:

```bash
./setup-template-repository.sh
```

The script will:
1. Verify prerequisites
2. Check Gitea connection
3. Prompt for your credentials
4. Create the template repository
5. Push template files
6. Mark repository as a template

**Example Session**:

```bash
$ ./setup-template-repository.sh

========================================
  AtomicQMS Template Repository Setup
========================================

[1/7] Checking template directory...
✓ Template directory found

[2/7] Checking Gitea connection...
✓ Connected to Gitea

[3/7] Gitea Authentication
Please provide your Gitea credentials:
Username: admin
Password or Token: ********

✓ Authenticated as admin

[4/7] Checking if repository exists...

[5/7] Creating repository...
✓ Repository created

[6/7] Pushing template files...
  ✓ Template pushed to Gitea

[7/7] Configuring as template repository...
✓ Repository marked as template

========================================
  ✓ Template Repository Ready!
========================================
```

### Manual Setup

If you prefer manual setup:

1. **Create Repository in Gitea UI**
   - Go to http://localhost:3001
   - Click "+" → "New Repository"
   - Name: `atomicqms-template`
   - Description: "AtomicQMS Repository Template"
   - Initialize: No (we'll push content)

2. **Push Template Files**
   ```bash
   cd template-qms-repository
   git init
   git add -A
   git commit -m "Initial commit: AtomicQMS Template"
   git remote add origin http://localhost:3001/YOUR_USERNAME/atomicqms-template.git
   git push -u origin main
   ```

3. **Mark as Template**
   - Go to repository Settings → Advanced Settings
   - Check "Template Repository"
   - Click "Update Settings"

## Usage: Creating Repositories from Template

### Web Interface Method

1. **Navigate to Create Repository Page**
   - Go to http://localhost:3001/repo/create
   - Or click "+" → "New Repository" in top navigation

2. **Select Template**
   - In "Template" dropdown, select `atomicqms-template`
   - Gitea will show which files will be created

3. **Configure New Repository**
   ```
   Owner: your-username
   Repository Name: my-qms-project
   Description: QMS for [Project Name]
   Visibility: Private (recommended for QMS)
   ```

4. **Create Repository**
   - Click "Create Repository"
   - Gitea creates the repository with all template files
   - Variables are automatically substituted

### API Method

Using the Gitea API:

```bash
# Create repository from template
curl -X POST \
  -H "Content-Type: application/json" \
  -u "username:token" \
  "http://localhost:3001/api/v1/repos/OWNER/TEMPLATE/generate" \
  -d '{
    "owner": "username",
    "name": "my-qms-project",
    "description": "QMS for My Project",
    "private": true
  }'
```

## Variable Substitution

Gitea automatically replaces template variables with repository-specific values:

### Available Variables

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `$REPO_NAME` | Repository name | `my-qms-project` |
| `$REPO_OWNER` | Repository owner username | `admin` |
| `$REPO_LINK` | Full repository URL | `http://localhost:3001/admin/my-qms-project` |
| `$TEMPLATE_NAME` | Source template name | `atomicqms-template` |
| `$YEAR` | Current year | `2025` |
| `$MONTH` | Current month (01-12) | `10` |
| `$DAY` | Current day (01-31) | `26` |

### Which Files Get Substitution?

The `.gitea/template` file defines which files undergo variable substitution:

```
README.md
docs/**/*.md
```

This means:
- ✓ README.md gets variable substitution
- ✓ All .md files in docs/ and subdirectories get substitution
- ✗ Workflow files (.gitea/workflows/*.yml) do NOT get substitution
- ✗ Other file types are copied as-is

### Example Substitution

**Template file** (`template-qms-repository/README.md`):
```markdown
# $REPO_NAME

Created from [AtomicQMS Template]($TEMPLATE_URL)
Owner: $REPO_OWNER

**Created**: $YEAR-$MONTH-$DAY
```

**After creating repository named "quality-system"**:
```markdown
# quality-system

Created from [AtomicQMS Template](http://localhost:3001/admin/atomicqms-template)
Owner: admin

**Created**: 2025-10-26
```

## Template Contents

The template repository includes:

### AI Assistant Integration

```
.gitea/
├── workflows/
│   └── claude-qms-assistant.yml    # AI workflow
└── template                          # Variable substitution config
.claude/
└── qms-context.md                   # QMS-specific AI context
```

**Pre-configured features**:
- Issue and PR monitoring
- @qms-assistant mention triggers
- Document review capabilities
- Compliance checking

### QMS Directory Structure

```
docs/
├── sops/
│   └── SOP-TEMPLATE.md              # Standard Operating Procedure template
├── forms/
│   └── .gitkeep                     # Placeholder for forms
├── capas/
│   └── CAPA-TEMPLATE.md             # Corrective/Preventive Action template
├── change-controls/
│   └── .gitkeep                     # Placeholder for change controls
└── training/
    └── .gitkeep                     # Placeholder for training records
```

### Documentation

```
README.md                             # Repository overview with variables
.gitignore                            # Pre-configured ignore patterns
```

## Customizing the Template

### Modifying Template Content

To update the template for all future repositories:

1. **Clone Template Repository**
   ```bash
   git clone http://localhost:3001/YOUR_USERNAME/atomicqms-template.git
   cd atomicqms-template
   ```

2. **Make Changes**
   ```bash
   # Edit files
   nano docs/sops/SOP-TEMPLATE.md

   # Add new templates
   cp SOP-TEMPLATE.md docs/sops/SOP-NEW-TEMPLATE.md
   ```

3. **Update Variable Substitution (if needed)**
   ```bash
   # Edit .gitea/template to add new file patterns
   echo "docs/new-folder/**/*.md" >> .gitea/template
   ```

4. **Commit and Push**
   ```bash
   git add -A
   git commit -m "Update SOP template with new sections"
   git push
   ```

5. **Test Changes**
   - Create a new repository from the updated template
   - Verify changes appear correctly
   - Check variable substitution works

### Adding Additional Variables

Gitea supports these built-in variables only. For custom variables, you can:

1. Use placeholder text in templates (e.g., `[COMPANY_NAME]`)
2. Document that users should search/replace after creation
3. Add custom post-creation scripts

### Creating Multiple Templates

You can create different templates for different use cases:

- `atomicqms-template` - Full QMS with all features
- `atomicqms-lite-template` - Minimal setup for simple projects
- `atomicqms-clinical-template` - Clinical trial specific structure

Each template is a separate repository marked as a template.

## Troubleshooting

### Template Not Appearing in Dropdown

**Symptom**: When creating a new repository, template doesn't show in dropdown

**Solutions**:
1. Verify repository is marked as template:
   ```bash
   curl -s -u "username:token" \
     "http://localhost:3001/api/v1/repos/OWNER/atomicqms-template" | \
     grep "template"
   ```
   Should show `"template":true`

2. Check repository visibility - private templates only show to authorized users

3. Refresh browser cache (Ctrl+Shift+R / Cmd+Shift+R)

### Variables Not Substituting

**Symptom**: Created repository shows `$REPO_NAME` instead of actual name

**Solutions**:
1. Check `.gitea/template` file exists and includes the file pattern:
   ```bash
   cat .gitea/template
   ```

2. Verify file path matches pattern:
   - `README.md` matches `README.md` ✓
   - `docs/sops/SOP-001.md` matches `docs/**/*.md` ✓
   - `.gitea/workflows/ai.yml` does NOT match (not in template file) ✗

3. Variable syntax must be exact:
   - `$REPO_NAME` ✓ (works)
   - `${REPO_NAME}` ✗ (doesn't work in Gitea templates)
   - `$REPONAME` ✗ (wrong variable name)

### AI Assistant Not Working in New Repository

**Symptom**: Created repository from template but @qms-assistant doesn't respond

**Solutions**:
1. Configure repository secrets:
   - Go to Settings → Secrets
   - Add `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN`
   - Add `QMS_SERVER_URL` (e.g., http://localhost:3001)

2. Verify Actions are enabled:
   - Go to repository Actions tab
   - If disabled, enable Actions in Settings

3. Check workflow file exists:
   ```bash
   ls -la .gitea/workflows/claude-qms-assistant.yml
   ```

4. Test by creating an issue and commenting:
   ```
   @qms-assistant Hello! Are you configured correctly?
   ```

5. Check Actions run log for errors

See [AI Integration Setup Guide](./gitea-actions-setup.md) for detailed troubleshooting.

### Template Repository Shows Workflow Runs

**Symptom**: The template repository itself is triggering AI assistant workflows

**Solution**: This is expected if the template repo has issues/PRs. The template is a normal repository that happens to be marked as template. You can:
1. Disable Actions on the template repository (Settings → Actions → Disable)
2. Keep Actions enabled for testing updates before propagating to template

### Permission Denied When Pushing Template

**Symptom**: `git push` fails with authentication error

**Solutions**:
1. Verify credentials:
   ```bash
   git remote -v
   # Should show http://localhost:3001/username/atomicqms-template.git
   ```

2. Check username in remote URL matches your Gitea account

3. Use personal access token instead of password:
   - Go to Gitea Settings → Applications → Generate Token
   - Use token as password: `git push https://username:TOKEN@localhost:3001/...`

4. Verify repository exists and you have write access

## Next Steps

After creating a repository from the template:

1. **Configure Secrets** (Required for AI assistant)
   - Settings → Secrets
   - Add `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN`
   - Add `QMS_SERVER_URL`

2. **Customize Repository**
   - Update README.md with project-specific information
   - Create your first SOP from SOP-TEMPLATE.md
   - Review and adjust QMS structure for your needs

3. **Test AI Assistant**
   - Create a test issue
   - Comment: `@qms-assistant Please review the structure of this repository`
   - Check Actions tab to see workflow run

4. **Set Up Team**
   - Add collaborators in Settings → Collaborators
   - Configure branch protection if needed
   - Set up issue templates

5. **Start Documenting**
   - Create SOPs from template
   - Document processes
   - Use AI assistant for review and compliance checking

## Related Documentation

- [AI Integration Setup](./gitea-actions-setup.md) - Detailed AI assistant configuration
- [OAuth Setup](./oauth-setup-guide.md) - Using Claude Code OAuth for authentication
- [Main README](../../README.md) - AtomicQMS overview and getting started

## Support

If you encounter issues:

1. Check [Troubleshooting](#troubleshooting) section above
2. Review Gitea logs: `docker logs atomicqms`
3. Review Actions runner logs: `docker logs atomicqms-runner`
4. Check Gitea documentation: https://docs.gitea.io/en-us/usage/template-repository/
