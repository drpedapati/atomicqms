# AtomicQMS - GitHub OAuth Authentication

A Docker-based deployment of Gitea with GitHub OAuth authentication, designed as a Quality Management System (QMS) with Git-based version control.

## Features

- Self-hosted Git service (Gitea)
- GitHub OAuth authentication (Single Sign-On)
- Automatic user registration on first GitHub login
- Profile sync (username, email, avatar from GitHub)
- Repository management with Git workflows
- SQLite database for simple deployment

## Quick Info

- **Web Interface**: http://localhost:3001
- **SSH Git Access**: ssh://git@localhost:222
- **Platform**: Docker Compose
- **Database**: SQLite3 (file-based)

---

## Initial Setup (From Scratch)

Follow these steps to set up AtomicQMS with GitHub OAuth from a fresh clone:

### Prerequisites

- Docker and Docker Compose installed
- GitHub account
- Admin access to create GitHub OAuth Apps

### Step 1: Create GitHub OAuth Application

1. Go to https://github.com/settings/developers
2. Click **"New OAuth App"**
3. Fill in the application details:
   - **Application name**: `AtomicQMS` (or your preferred name)
   - **Homepage URL**: `http://localhost:3001`
   - **Authorization callback URL**: `http://localhost:3001/user/oauth2/github/callback`

   ⚠️ **CRITICAL**: The callback URL must be EXACTLY as shown above

4. Click **"Register application"**
5. On the app page, click **"Generate a new client secret"**
6. **Save both values** (you'll need them in the next step):
   - Client ID (starts with `Iv1.` or `Ov-`)
   - Client Secret (shown only once!)

### Step 2: Clone Repository

```bash
git clone <your-repo-url>
cd atomicqms-github-auth
```

### Step 3: Configure OAuth Credentials

Create a `.env` file with your GitHub OAuth credentials:

```bash
# Copy the template
cp .env.example .env

# Edit with your credentials
nano .env
```

Replace the placeholder values with your actual GitHub OAuth App credentials:
```bash
GITHUB_CLIENT_ID=Iv1.YOUR_ACTUAL_CLIENT_ID
GITHUB_CLIENT_SECRET=YOUR_ACTUAL_CLIENT_SECRET
```

💡 **Tip**: The `.env` file is already in `.gitignore` - it will never be committed to Git.

### Step 4: Start the Container

```bash
docker compose up -d
```

This starts Gitea with OAuth-ready configuration. Wait ~5 seconds for startup.

### Step 5: Configure OAuth in Database

⚠️ **CRITICAL STEP** - This is required for GitHub login to appear!

Run the setup script to configure the GitHub OAuth source in Gitea's database:

```bash
./setup-github-oauth.sh
```

**What this does:**
- Reads credentials from your `.env` file
- Checks if GitHub OAuth source exists in database
- Creates new OAuth source (first time) OR updates existing credentials
- Automatically restarts the container

**Expected output:**
```
✓ GitHub OAuth authentication source configured successfully
```

### Step 6: Test GitHub Login

1. Open http://localhost:3001/user/login
2. You should see a **"Sign in with GitHub"** button
3. Click it and authorize the application
4. You'll be redirected back and logged in!

---

## Understanding the Two-Part Setup

**Why do I need to run a script after starting Docker?**

AtomicQMS GitHub OAuth setup has two parts:

### Part 1: OAuth Capability (Already Configured)
The `gitea/gitea/conf/app.ini` file contains settings that **enable** OAuth:
```ini
[oauth2_client]
ENABLE_AUTO_REGISTRATION = true
UPDATE_AVATAR = true
```

This tells Gitea "you can use OAuth providers."

### Part 2: GitHub OAuth Source (You Must Configure)
The specific GitHub OAuth configuration is stored in **Gitea's database** (`gitea/gitea/gitea.db`):
- Client ID
- Client Secret
- Provider (GitHub)
- Callback URL
- Scopes

**Why not in Git?** The database contains sensitive credentials and is user-specific, so it's in `.gitignore`. Each user must configure their own GitHub OAuth App.

**The script bridges this gap** by writing your GitHub OAuth credentials into the database.

---

## Updating OAuth Credentials

If you need to change your GitHub OAuth credentials:

1. Update your `.env` file with new credentials
2. Run the setup script again:
   ```bash
   ./setup-github-oauth.sh
   ```
3. The script automatically detects the existing OAuth source and updates it

---

## Docker Management

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker logs atomicqms
docker logs atomicqms -f  # follow mode

# Restart container
docker compose restart

# Rebuild and restart
docker compose up -d --build
```

---

## Creating Admin User

On first run, create an admin user:

```bash
docker exec -u git atomicqms gitea admin user create \
  --username admin \
  --password 'YourSecurePassword' \
  --email admin@example.com \
  --admin
```

Or change password for existing user:

```bash
docker exec -u git atomicqms gitea admin user change-password \
  --username admin \
  --password 'YourNewPassword'
```

---

## Troubleshooting

### Issue: No "Sign in with GitHub" button appears

**Cause**: OAuth source not configured in database

**Solution**:
1. Make sure you ran `./setup-github-oauth.sh`
2. Check script output for errors
3. Verify `.env` file has correct credentials
4. Restart container: `docker compose restart`

### Issue: "incorrect_client_credentials" error

**Cause**: Client ID or Client Secret doesn't match GitHub OAuth App

**Solution**:
1. Go to https://github.com/settings/developers
2. Verify Client ID matches your `.env` file exactly
3. Generate a new Client Secret if needed
4. Update `.env` file with correct credentials
5. Run `./setup-github-oauth.sh` to update
6. Restart container: `docker compose restart`

### Issue: "Redirect URI mismatch" error

**Cause**: Callback URL in GitHub OAuth App doesn't match Gitea configuration

**Solution**:
1. Check GitHub OAuth App callback URL is EXACTLY:
   ```
   http://localhost:3001/user/oauth2/github/callback
   ```
2. No trailing slashes, correct port (3001), correct path
3. Update GitHub OAuth App if needed
4. Re-run setup script

### Issue: Container won't start

**Cause**: Port conflict or Docker issue

**Solution**:
```bash
# Check if ports are in use
lsof -i :3001
lsof -i :222

# Check Docker logs
docker logs atomicqms

# Full restart
docker compose down
docker compose up -d
```

### Issue: Users created without avatars

**Cause**: Avatar sync not enabled or GitHub profile has no public avatar

**Solution**:
1. Verify `gitea/gitea/conf/app.ini` has:
   ```ini
   [oauth2_client]
   UPDATE_AVATAR = true

   [service]
   ENABLE_USER_AVATAR = true
   ```
2. User must have public GitHub avatar
3. Log out and log back in to refresh avatar

---

## Security Notes

### For Development (localhost)

✅ Current setup is secure for local development:
- Secrets in `.env` (gitignored)
- SQLite database in gitignored directory
- Minimal OAuth scopes (`read:user`, `user:email`)

### For Production Deployment

⚠️ **Before deploying to production, you MUST**:

1. **Use HTTPS** - Update `app.ini`:
   ```ini
   [server]
   ROOT_URL = https://qms.yourcompany.com/
   ```

2. **Update GitHub OAuth App** with HTTPS callback URL:
   ```
   https://qms.yourcompany.com/user/oauth2/github/callback
   ```

3. **Use environment variables** or secrets manager (not `.env` file)

4. **Enable logging**:
   ```ini
   [log]
   LEVEL = info
   ```

5. **Regular backups** of `gitea/gitea/gitea.db`

6. **Rotate secrets** periodically (every 90 days recommended)

---

## Data Storage

All persistent data is stored in `./gitea/` (gitignored):

- **Repositories**: `./gitea/git/repositories/`
- **Database**: `./gitea/gitea/gitea.db`
- **LFS Objects**: `./gitea/git/lfs/`
- **Avatars**: `./gitea/gitea/avatars/`
- **SSH Keys**: `./gitea/ssh/`
- **Logs**: `./gitea/gitea/log/`

**Configuration** is tracked in Git:
- `gitea/gitea/conf/app.ini` (tracked)
- `.env.example` (tracked template)
- `.env` (gitignored - contains secrets)

---

## Architecture

```
┌─────────────────────────────────────────────┐
│  User Browser                               │
└──────────────┬──────────────────────────────┘
               │
               │ 1. Click "Sign in with GitHub"
               ▼
┌─────────────────────────────────────────────┐
│  GitHub OAuth                               │
│  - Validates credentials                    │
│  - User authorizes app                      │
└──────────────┬──────────────────────────────┘
               │
               │ 2. Callback with auth code
               ▼
┌─────────────────────────────────────────────┐
│  AtomicQMS (Gitea)                          │
│  - Exchanges code for token                 │
│  - Creates/updates user account             │
│  - Syncs profile (username, email, avatar)  │
└─────────────────────────────────────────────┘
```

**OAuth Flow:**
1. User clicks "Sign in with GitHub"
2. Redirected to GitHub authorization page
3. User approves requested scopes (`read:user`, `user:email`)
4. GitHub redirects to callback URL with auth code
5. Gitea exchanges code for access token
6. Gitea fetches user profile from GitHub API
7. Auto-creates account (if new) or logs in (if existing)
8. User is logged into AtomicQMS

---

## Configuration Reference

### OAuth Settings in `app.ini`

```ini
[service]
DISABLE_REGISTRATION = true              # No local registration
ALLOW_ONLY_EXTERNAL_REGISTRATION = true  # OAuth registration allowed
REQUIRE_SIGNIN_VIEW = false              # Public read access
ENABLE_USER_AVATAR = true                # Avatar support enabled

[oauth2_client]
ENABLE_AUTO_REGISTRATION = true          # Auto-create users on first login
UPDATE_AVATAR = true                     # Sync GitHub avatars

[oauth2]
JWT_SECRET = <auto-generated>            # OAuth token signing key
```

### OAuth Source (in Database)

Configured via `setup-github-oauth.sh`:
- **Name**: `github`
- **Provider**: GitHub
- **Client ID**: From `.env`
- **Client Secret**: From `.env`
- **Scopes**: `read:user,user:email`
- **Auto-discover URL**: `https://github.com/.well-known/openid-configuration`

---

## Support & References

**Documentation:**
- [Gitea Authentication](https://docs.gitea.com/usage/authentication)
- [GitHub OAuth Apps](https://docs.github.com/en/developers/apps/building-oauth-apps)
- [OAuth 2.0 Security Best Practices](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics)

**Gitea Commands:**
```bash
# List OAuth sources
docker exec -u git atomicqms gitea admin auth list

# List users
docker exec -u git atomicqms gitea admin user list

# Check version
docker exec -u git atomicqms gitea --version
```

**Get Help:**
- Check logs: `docker logs atomicqms -f`
- Gitea Community: https://forum.gitea.com
- GitHub OAuth Support: https://support.github.com

---

## License

See project repository for license information.
