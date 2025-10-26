# Quick Start

Get your first AtomicQMS instance running in under 5 minutes.

## Installation

### Step 1: Get the Code

Clone the AtomicQMS repository:

```bash
git clone https://github.com/atomicqms/atomicqms.git
cd atomicqms
```

### Step 2: Start the Container

Launch AtomicQMS using Docker Compose:

```bash
docker compose up -d
```

This will:
- Pull the Gitea image
- Configure the AtomicQMS instance
- Start the service on port 3001
- Initialize the SQLite database

### Step 3: Create Admin User

Create your first admin user:

```bash
docker exec -it atomicqms gitea admin user create \
  --config /data/gitea/conf/app.ini \
  --username admin \
  --password 'YourSecurePassword' \
  --email admin@example.com \
  --admin
```

::: warning Security Note
Change 'YourSecurePassword' to a strong password. Consider using a password manager.
:::

### Step 4: Access the Web Interface

Open your browser and navigate to:

```
http://localhost:3001
```

Log in with the admin credentials you just created.

## Your First Repository

Now let's create your first QMS repository for Standard Operating Procedures.

### Create a New Repository

1. Click the **+** icon in the top right
2. Select **New Repository**
3. Fill in the details:
   - **Repository Name**: `sops`
   - **Description**: Standard Operating Procedures
   - **Visibility**: Private (recommended)
   - **Initialize Repository**: ✓ (check this)
   - **Add .gitignore**: None
   - **Add README**: ✓ (check this)
   - **License**: Choose based on your needs

4. Click **Create Repository**

### Create Your First SOP

1. In your new `sops` repository, click **New File**
2. Name it: `SOPs/SOP-001-document-control.md`
3. Add content:

```markdown
# SOP-001: Document Control

**Effective Date**: 2024-10-26
**Version**: 1.0
**Author**: Admin
**Approved By**: [Pending]

## Purpose

This SOP defines the process for creating, reviewing, approving, and maintaining Standard Operating Procedures within AtomicQMS.

## Scope

This procedure applies to all quality documents managed within the AtomicQMS system.

## Procedure

### 1. Document Creation

1. Create new document in appropriate repository
2. Use Markdown format with standard template
3. Include required metadata (effective date, version, author)
4. Draft content in feature branch

### 2. Review Process

1. Create pull request for review
2. Assign appropriate reviewers
3. Address reviewer comments
4. Obtain required approvals

### 3. Approval and Release

1. Once all reviews complete, merge pull request
2. Tag release with version number
3. Update document register
4. Notify stakeholders

### 4. Change Control

1. All changes require new pull request
2. Major revisions increment major version
3. Minor revisions increment minor version
4. Maintain complete version history

## References

- Git workflow documentation
- Quality management system policy

## Revision History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 2024-10-26 | Admin | Initial release |
```

4. Add a commit message: `Initial version of SOP-001`
5. Click **Commit Changes**

## Next Steps

Congratulations! You now have:

- ✅ A running AtomicQMS instance
- ✅ An admin user account
- ✅ Your first repository
- ✅ Your first SOP document

### Explore Further

- [Core Concepts](./core-concepts.md) - Understand the philosophy
- [Working with SOPs](./sops.md) - SOP management in detail
- [CAPA Workflows](./capa.md) - Corrective and preventive actions
- [Change Control](./change-control.md) - Managing document changes

### Enable AI Features

To enable AI-assisted documentation:

1. Obtain API credentials for Claude or OpenAI
2. Configure environment variables
3. See [AI Integration Guide](/ai-integration/)

### Production Deployment

For production use, review:

- [Security best practices](/deployment/configuration.html#security)
- [Backup strategies](/deployment/configuration.html#backups)
- [Scaling guidelines](/deployment/scaling.html)
