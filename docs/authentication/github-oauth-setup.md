# GitHub OAuth Authentication Setup Guide

## Overview

This guide walks you through setting up GitHub OAuth authentication for AtomicQMS. This allows users to sign in with their GitHub accounts instead of creating local credentials, providing Single Sign-On (SSO) functionality.

## What You'll Get

- **Single Sign-On** with GitHub accounts
- **Automatic user registration** on first login
- **Profile sync** (username, email, avatar from GitHub)
- **Minimal OAuth scopes** (read:user, user:email)
- **Secure credential management**
- **Account linking** for existing users

---

## Prerequisites

Before you begin, ensure you have:

- ✅ **Docker and Docker Compose** installed and running
- ✅ **AtomicQMS container running** (`docker ps | grep atomicqms`)
- ✅ **GitHub account** with OAuth App creation permissions
- ✅ **Command-line access** to the AtomicQMS host machine
- ✅ **Write permissions** in the AtomicQMS directory

**Verify prerequisites:**

```bash
# Check Docker is running
docker --version

# Check AtomicQMS container
docker ps | grep atomicqms

# Check you're in the right directory
pwd  # Should show your AtomicQMS installation path
```

---

## Understanding the Two-Part Setup

GitHub OAuth configuration in Gitea requires **two separate components**:

### Part 1: OAuth Capability (Pre-Configured ✅)

This is already done for you in `gitea/gitea/conf/app.ini`:

```ini
[service]
DISABLE_REGISTRATION = true              # No local registration
ALLOW_ONLY_EXTERNAL_REGISTRATION = true  # OAuth registration allowed
ENABLE_USER_AVATAR = true                # Avatar support

[oauth2_client]
ENABLE_AUTO_REGISTRATION = true          # Auto-create users on first login
UPDATE_AVATAR = true                     # Sync GitHub avatars
```

### Part 2: OAuth Source (You Configure 🔧)

This stores your specific GitHub OAuth App credentials in the Gitea database. This **cannot** be pre-configured because it contains your unique Client ID and Client Secret.

**Why two parts?**
- Part 1 enables the feature (committed to Git)
- Part 2 contains secrets (NOT in Git, configured per deployment)

The setup script (`setup-github-oauth.sh`) handles Part 2 automatically.

---

## Step 1: Create GitHub OAuth Application

### 1.1: Navigate to GitHub Developer Settings

1. Go to: **https://github.com/settings/developers**
2. Click **"OAuth Apps"** tab (left sidebar)
3. Click **"New OAuth App"** button

### 1.2: Configure OAuth Application

Fill in the form with these values:

| Field | Value |
|-------|-------|
| **Application name** | `AtomicQMS` (or your preferred name) |
| **Homepage URL** | `http://localhost:3001` |
| **Application description** | `AtomicQMS Quality Management System` (optional) |
| **Authorization callback URL** | `http://localhost:3001/user/oauth2/github/callback` |

⚠️ **CRITICAL:** The callback URL **must** be exactly:
```
http://localhost:3001/user/oauth2/github/callback
```

**For production deployments**, replace `http://localhost:3001` with your actual domain:
```
https://qms.yourcompany.com/user/oauth2/github/callback
```

**Why this URL?**
- `/user/oauth2/` is Gitea's OAuth handler path
- `/github/` matches the authentication source name (configurable)
- `/callback` is where GitHub sends users after authorization

### 1.3: Generate Client Secret

1. Click **"Register application"**
2. You'll see your **Client ID** (starts with `Ov23...` or `Iv1.`)
3. Click **"Generate a new client secret"**
4. **Copy the Client Secret immediately** - it's only shown once!

**Save both values:**
```
Client ID:     Ov23liXXXXXXXXXXXXXX
Client Secret: 70a53c5ba4b173db5a21e95b699a1747bc32a567
```

⚠️ **Security Note:** Treat these like passwords. Never commit them to Git.

---

## Step 2: Configure OAuth Credentials

### 2.1: Create Environment File

Navigate to your AtomicQMS directory and create a `.env` file:

```bash
# Navigate to AtomicQMS directory
cd /path/to/atomicqms

# Copy the template
cp .env.example .env

# Verify it was created
ls -la .env
```

### 2.2: Edit Environment File

Open `.env` in your preferred editor:

```bash
# Using nano
nano .env

# Or vim
vim .env

# Or any text editor
```

### 2.3: Add Your Credentials

Replace the placeholder values with your actual GitHub OAuth App credentials:

**Before:**
```bash
# GitHub OAuth App Credentials
GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxx
GITHUB_CLIENT_SECRET=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**After:**
```bash
# GitHub OAuth App Credentials
GITHUB_CLIENT_ID=Ov23liY3gccPRTuIy1kE
GITHUB_CLIENT_SECRET=70a53c5ba4b173db5a21e95b699a1747bc32a567
```

**Optional advanced configuration** (most users don't need this):

```bash
# Authentication Source Name (appears in callback URL)
# Default: github
# GITHUB_AUTH_SOURCE_NAME=github

# OAuth Scopes (default: read:user,user:email)
# Add read:org for organization membership sync
# GITHUB_OAUTH_SCOPES=read:user,user:email,read:org
```

**Save and close** (`Ctrl+X`, then `Y`, then `Enter` in nano).

### 2.4: Verify .env File

Check that your `.env` file is properly configured:

```bash
# View the file (redacted for security)
grep "GITHUB_CLIENT" .env

# Should show:
# GITHUB_CLIENT_ID=Ov23...
# GITHUB_CLIENT_SECRET=70a53...
```

⚠️ **Security Check:** Verify `.env` is in `.gitignore`:

```bash
cat .gitignore | grep "\.env"

# Should show: .env
```

---

## Step 3: Start or Restart Container

Ensure the AtomicQMS container is running:

```bash
# Start if not running
docker compose up -d

# Or restart if already running
docker compose restart

# Verify it's running
docker ps | grep atomicqms
```

**Expected output:**
```
atomicqms    Up 10 seconds    0.0.0.0:3001->3000/tcp, 0.0.0.0:222->22/tcp
```

---

## Step 4: Run OAuth Setup Script

### 4.1: Make Script Executable

The setup script needs execute permissions:

```bash
# Check current permissions
ls -l setup-github-oauth.sh

# Make executable
chmod +x setup-github-oauth.sh

# Verify
ls -l setup-github-oauth.sh
# Should show: -rwxr-xr-x ... setup-github-oauth.sh
```

### 4.2: Run the Script

Execute the automated setup:

```bash
./setup-github-oauth.sh
```

### 4.3: Expected Output

You should see colored output showing progress:

```
========================================
  AtomicQMS GitHub OAuth Setup
========================================

[1/6] Checking container status...
✓ Container is running

[2/6] Loading credentials from .env file...
✓ Credentials loaded
  Client ID: Ov23liY3gc...

[3/6] Checking if GitHub OAuth source exists...
✓ No existing OAuth source found
  Will create new OAuth source...

[4/6] Configuring GitHub OAuth...
✓ OAuth source created successfully

[5/6] Verifying configuration...
ID  Name    Type        Enabled
1   github  OAuth2      true

[6/6] Restarting container to apply changes...
✓ Container restarted

Waiting for Gitea to be ready...
✓ Gitea is ready

========================================
  ✓ GitHub OAuth Setup Complete!
========================================

Next steps:
1. Open: http://localhost:3001/user/login
2. Click "Sign in with GitHub"
3. Authorize the application
4. You'll be logged in with your GitHub account!
```

### 4.4: What the Script Does

The script automates these tasks:

1. ✅ Validates container is running
2. ✅ Loads credentials from `.env`
3. ✅ Validates credential format
4. ✅ Checks for existing OAuth configuration
5. ✅ Creates new OAuth source OR updates existing
6. ✅ Restarts container to apply changes
7. ✅ Provides next steps

**Smart Features:**
- **Idempotent**: Safe to run multiple times
- **Auto-detect**: Updates existing config instead of creating duplicates
- **Validation**: Checks credential format before applying
- **Error handling**: Clear error messages if something fails

---

## Step 5: Test GitHub Login

### 5.1: Access Login Page

Open your browser and navigate to:

```
http://localhost:3001/user/login
```

(Or your production URL: `https://qms.yourcompany.com/user/login`)

### 5.2: Verify GitHub Login Button

You should now see a button:

```
┌────────────────────────────┐
│   Sign in with GitHub      │
└────────────────────────────┘
```

If you **don't see this button**, see [Troubleshooting](#troubleshooting) below.

### 5.3: Authorize Application

1. Click **"Sign in with GitHub"**
2. You'll be redirected to GitHub
3. Review the permissions requested:
   - ✅ Read your basic profile information
   - ✅ Read your email address
4. Click **"Authorize [Your OAuth App Name]"**
5. You'll be redirected back to AtomicQMS
6. **You're logged in!**

### 5.4: Verify Profile Sync

After login, check that your profile synced correctly:

1. Click your avatar (top right)
2. Go to **Settings** → **Profile**
3. Verify:
   - ✅ Username matches GitHub
   - ✅ Email matches GitHub
   - ✅ Avatar matches GitHub

---

## Understanding OAuth Scopes

AtomicQMS uses **minimal scopes** for security:

| Scope | Purpose | Data Accessed |
|-------|---------|---------------|
| `read:user` | Basic profile | Username, full name, avatar URL |
| `user:email` | Email addresses | Primary email (for notifications) |

**Optional scopes** you can add to `.env`:

| Scope | Purpose | When to Use |
|-------|---------|-------------|
| `read:org` | Organization membership | If you want to sync team/org info |

To add scopes, edit `.env`:

```bash
GITHUB_OAUTH_SCOPES=read:user,user:email,read:org
```

Then re-run `./setup-github-oauth.sh`.

---

## Troubleshooting

### Issue: No "Sign in with GitHub" Button

**Symptoms:**
- Login page only shows local username/password fields
- No GitHub button visible

**Solutions:**

1. **Verify script completed successfully:**
   ```bash
   ./setup-github-oauth.sh
   ```
   Look for "✓ OAuth source created successfully"

2. **Check OAuth source in database:**
   ```bash
   docker exec -u git atomicqms gitea admin auth list
   ```
   Should show:
   ```
   ID  Name    Type        Enabled
   1   github  OAuth2      true
   ```

3. **Check container logs:**
   ```bash
   docker logs atomicqms | grep -i oauth
   ```
   Look for errors related to OAuth configuration

4. **Restart container:**
   ```bash
   docker compose restart
   ```
   Wait 10 seconds, then hard refresh browser (`Cmd+Shift+R` or `Ctrl+Shift+R`)

5. **Verify app.ini has OAuth enabled:**
   ```bash
   docker exec atomicqms cat /data/gitea/conf/app.ini | grep -A 3 "\[oauth2_client\]"
   ```
   Should show:
   ```ini
   [oauth2_client]
   ENABLE_AUTO_REGISTRATION = true
   UPDATE_AVATAR = true
   ```

---

### Issue: "incorrect_client_credentials" Error

**Symptoms:**
- Redirected to GitHub successfully
- After clicking "Authorize", error: "incorrect_client_credentials"

**Solutions:**

1. **Verify credentials match GitHub:**
   - Go to https://github.com/settings/developers
   - Click your OAuth App
   - Compare Client ID with `.env` file:
     ```bash
     grep "GITHUB_CLIENT_ID" .env
     ```
   - If they don't match, update `.env` and re-run script

2. **Regenerate Client Secret:**
   - In GitHub OAuth App settings
   - Click "Generate a new client secret"
   - Copy the new secret immediately
   - Update `.env`:
     ```bash
     nano .env
     # Update GITHUB_CLIENT_SECRET=<new_secret>
     ```
   - Re-run script:
     ```bash
     ./setup-github-oauth.sh
     ```

3. **Check for whitespace:**
   ```bash
   # View exact characters (including hidden whitespace)
   cat -A .env | grep GITHUB_CLIENT
   ```
   Remove any trailing spaces or newlines

---

### Issue: "Redirect URI Mismatch" Error

**Symptoms:**
- Error from GitHub: "The redirect_uri MUST match the registered callback URL"

**Solutions:**

1. **Verify callback URL in GitHub OAuth App:**
   - Go to https://github.com/settings/developers
   - Click your OAuth App
   - Check "Authorization callback URL" field
   - Must be **exactly**:
     ```
     http://localhost:3001/user/oauth2/github/callback
     ```

2. **Common mistakes:**
   - ❌ `http://localhost:3001/user/oauth2/callback` (missing `/github/`)
   - ❌ `http://localhost:3001/callback` (wrong path)
   - ❌ `https://localhost:3001/...` (http vs https mismatch)
   - ❌ `http://127.0.0.1:3001/...` (localhost vs 127.0.0.1)

3. **If using custom auth source name:**
   - Check `.env` for `GITHUB_AUTH_SOURCE_NAME`
   - Callback URL must be:
     ```
     http://localhost:3001/user/oauth2/{AUTH_SOURCE_NAME}/callback
     ```
   - Example: If `AUTH_SOURCE_NAME=gh-sso`, callback is:
     ```
     http://localhost:3001/user/oauth2/gh-sso/callback
     ```

---

### Issue: Users Can't Register

**Symptoms:**
- GitHub login works for admin
- New users get "Registration is disabled" error

**Solutions:**

1. **Check app.ini settings:**
   ```bash
   docker exec atomicqms cat /data/gitea/conf/app.ini | grep -A 3 "\[service\]"
   ```
   Should show:
   ```ini
   [service]
   DISABLE_REGISTRATION = true
   ALLOW_ONLY_EXTERNAL_REGISTRATION = true
   ```

2. **Verify OAuth auto-registration:**
   ```bash
   docker exec atomicqms cat /data/gitea/conf/app.ini | grep ENABLE_AUTO_REGISTRATION
   ```
   Should show:
   ```ini
   ENABLE_AUTO_REGISTRATION = true
   ```

3. **If still failing**, manually enable OAuth registration:
   - Log into AtomicQMS as admin
   - Go to: Site Administration → Configuration → Authentication Sources
   - Click on "github" OAuth source
   - Ensure "Skip local 2FA" is checked
   - Save

---

### Issue: Avatar Not Syncing

**Symptoms:**
- User logs in successfully
- Avatar shows default icon instead of GitHub avatar

**Solutions:**

1. **Enable avatar sync:**
   ```bash
   docker exec atomicqms cat /data/gitea/conf/app.ini | grep UPDATE_AVATAR
   ```
   Should show:
   ```ini
   UPDATE_AVATAR = true
   ```

2. **Manually sync avatar:**
   - Log into AtomicQMS
   - Go to Settings → Profile
   - Click "Update Avatar from GitHub"

3. **Check avatar URL permissions:**
   - GitHub avatar URLs must be publicly accessible
   - Private/custom avatars may not sync

---

## Production Deployment Considerations

### HTTPS Configuration

For production, **always use HTTPS**:

1. **Update GitHub OAuth App:**
   - Callback URL: `https://qms.yourcompany.com/user/oauth2/github/callback`
   - Homepage URL: `https://qms.yourcompany.com`

2. **Update AtomicQMS `app.ini`:**
   ```ini
   [server]
   PROTOCOL = https
   DOMAIN = qms.yourcompany.com
   ROOT_URL = https://qms.yourcompany.com/
   ```

3. **Update `.env`** (if using for production URLs):
   ```bash
   QMS_SERVER_URL=https://qms.yourcompany.com
   ```

### Secrets Management

**Development:**
- ✅ `.env` file (gitignored)

**Production:**
- ✅ **Environment variables** (Docker secrets, Kubernetes secrets)
- ✅ **Secrets management** (AWS Secrets Manager, HashiCorp Vault)
- ❌ **NOT** hardcoded in configuration files

**Example with Docker secrets:**

```yaml
# docker-compose.yml
services:
  atomicqms:
    secrets:
      - github_client_id
      - github_client_secret

secrets:
  github_client_id:
    external: true
  github_client_secret:
    external: true
```

### Multiple Environments

Use separate OAuth Apps for each environment:

| Environment | OAuth App Name | Callback URL |
|-------------|---------------|--------------|
| Development | `AtomicQMS-Dev` | `http://localhost:3001/user/oauth2/github/callback` |
| Staging | `AtomicQMS-Staging` | `https://staging-qms.company.com/user/oauth2/github/callback` |
| Production | `AtomicQMS` | `https://qms.company.com/user/oauth2/github/callback` |

This prevents credential mixing and improves security.

---

## Advanced Configuration

### Custom Authentication Source Name

Change the name that appears in the callback URL:

**Default:**
```
http://localhost:3001/user/oauth2/github/callback
```

**Custom:**
```bash
# In .env
GITHUB_AUTH_SOURCE_NAME=gh-sso
```

**Result:**
```
http://localhost:3001/user/oauth2/gh-sso/callback
```

⚠️ **Remember to update the GitHub OAuth App callback URL to match!**

### Organization-Restricted Access

Limit access to specific GitHub organizations:

1. **Add `read:org` scope:**
   ```bash
   # In .env
   GITHUB_OAUTH_SCOPES=read:user,user:email,read:org
   ```

2. **Configure in Gitea UI:**
   - Log in as admin
   - Site Administration → Authentication Sources
   - Edit "github" OAuth source
   - Add required organization name

### Manual OAuth Configuration

If you prefer to configure manually instead of using the script:

```bash
# Add OAuth source
docker exec -u git atomicqms gitea admin auth add-oauth \
  --name "github" \
  --provider "github" \
  --key "YOUR_CLIENT_ID" \
  --secret "YOUR_CLIENT_SECRET" \
  --auto-discover-url "https://github.com/.well-known/openid-configuration" \
  --scopes "read:user,user:email"

# List OAuth sources
docker exec -u git atomicqms gitea admin auth list

# Update existing source
docker exec -u git atomicqms gitea admin auth update-oauth \
  --id 1 \
  --name "github" \
  --provider "github" \
  --key "NEW_CLIENT_ID" \
  --secret "NEW_CLIENT_SECRET"
```

---

## Security Best Practices

### Credential Protection

✅ **DO:**
- Store credentials in `.env` (gitignored)
- Use environment variables in production
- Rotate secrets periodically
- Use HTTPS in production
- Limit OAuth scopes to minimum required

❌ **DON'T:**
- Commit `.env` to Git
- Share credentials via email/Slack
- Use same OAuth App for dev and production
- Use HTTP in production
- Request more OAuth scopes than needed

### Audit Logging

All OAuth login attempts are logged:

```bash
# View OAuth-related logs
docker logs atomicqms | grep -i oauth

# View authentication logs
docker exec atomicqms cat /data/gitea/log/gitea.log | grep -i "oauth"
```

### Access Review

Regularly review who has access:

1. Log into AtomicQMS as admin
2. Go to: Site Administration → User Accounts
3. Filter by: "External" (OAuth users)
4. Review list and remove unauthorized users

---

## Maintenance

### Updating Credentials

If you need to change OAuth credentials:

1. **Update `.env` file:**
   ```bash
   nano .env
   # Update GITHUB_CLIENT_ID and/or GITHUB_CLIENT_SECRET
   ```

2. **Re-run setup script:**
   ```bash
   ./setup-github-oauth.sh
   ```
   The script will detect existing configuration and update it

3. **Verify:**
   ```bash
   docker exec -u git atomicqms gitea admin auth list
   ```

### Removing OAuth

To disable GitHub OAuth:

```bash
# List OAuth sources to get ID
docker exec -u git atomicqms gitea admin auth list

# Delete OAuth source
docker exec -u git atomicqms gitea admin auth delete --id 1

# Restart container
docker compose restart
```

### Monitoring Usage

Check OAuth usage statistics:

```bash
# Count OAuth users
docker exec atomicqms sqlite3 /data/gitea/gitea.db \
  "SELECT COUNT(*) FROM user WHERE login_type = 6;"

# List OAuth users
docker exec atomicqms sqlite3 /data/gitea/gitea.db \
  "SELECT name, email, created_unix FROM user WHERE login_type = 6;"
```

---

## Additional Resources

### Documentation

- **GitHub OAuth Apps**: https://docs.github.com/en/apps/oauth-apps
- **Gitea Authentication**: https://docs.gitea.com/administration/authentication
- **AtomicQMS CLAUDE.md**: See `CLAUDE.md` for quick reference

### Related Guides

- [Quick Start Guide](../guide/quick-start.md) - AtomicQMS basics
- [AI Integration](../ai-integration/) - Claude assistant setup
- [Deployment Guide](../deployment/) - Production deployment

### Support

**Issues with this guide?**
- Open an issue in the AtomicQMS repository
- Check the troubleshooting section above
- Review Gitea documentation

**GitHub OAuth Issues?**
- GitHub OAuth Apps documentation
- GitHub Support

---

## Quick Reference

### Common Commands

```bash
# Run OAuth setup
./setup-github-oauth.sh

# Check OAuth source
docker exec -u git atomicqms gitea admin auth list

# View logs
docker logs atomicqms | grep -i oauth

# Restart container
docker compose restart

# Check .env file
grep "GITHUB_CLIENT" .env
```

### File Locations

```
.env                              # OAuth credentials (not in Git)
.env.example                      # Template with examples
setup-github-oauth.sh             # Automated setup script
gitea/gitea/conf/app.ini         # OAuth capability settings
gitea/gitea/gitea.db             # OAuth source (in database)
```

### Important URLs

```
GitHub OAuth Apps:     https://github.com/settings/developers
AtomicQMS Login:       http://localhost:3001/user/login
Callback URL:          http://localhost:3001/user/oauth2/github/callback
```

---

**Last Updated:** 2025-10-26
**Version:** 1.0.0
**For:** AtomicQMS GitHub OAuth Integration
