# Authentication Guide

AtomicQMS supports multiple authentication methods for different purposes. This guide helps you choose and configure the right authentication for your needs.

## Two Types of Authentication

AtomicQMS uses **two separate authentication systems** that serve different purposes:

### 1. User Authentication (GitHub OAuth)

**Purpose:** Allow users to sign into AtomicQMS

**What it does:**
- Enables Single Sign-On (SSO) with GitHub accounts
- Users click "Sign in with GitHub" instead of creating local passwords
- Automatically syncs user profiles (name, email, avatar)
- Simplifies user management for teams already using GitHub

**Who needs it:**
- System administrators setting up user access
- Teams wanting to use GitHub for identity management
- Organizations requiring SSO

**Setup Guide:** [GitHub OAuth Setup Guide](./github-oauth-setup.md)

---

### 2. AI Assistant Authentication (Claude Code OAuth)

**Purpose:** Allow the AI assistant to authenticate with Claude API

**What it does:**
- Enables the AtomicQMS AI Assistant to use your Claude subscription
- Powers AI-driven features like SOP review, CAPA assistance
- Uses your existing Claude Max/Pro subscription (no separate API billing)

**Who needs it:**
- Developers setting up AI integration features
- Teams wanting automated compliance assistance
- Users with Claude Max/Pro subscriptions

**Setup Guide:** [Claude Code OAuth Setup Guide](../ai-integration/claude-code-oauth-setup.md)

---

## Comparison Table

| Feature | GitHub OAuth | Claude Code OAuth |
|---------|--------------|-------------------|
| **Purpose** | User login | AI assistant |
| **Users** | All team members | System/automation |
| **Required?** | Optional (can use local accounts) | Only if using AI features |
| **Credentials** | GitHub OAuth App | Claude Code token |
| **Setup Time** | ~10 minutes | ~20 minutes |
| **Maintenance** | Regenerate secrets annually | Token auto-refreshes |
| **Dependencies** | GitHub account | Claude Max/Pro subscription |

---

## Choosing Your Setup

### Scenario 1: Basic QMS Without AI

**What you need:**
- ✅ GitHub OAuth (for easy user management)
- ❌ Claude Code OAuth (not needed)

**Setup:**
1. Follow [GitHub OAuth Setup Guide](./github-oauth-setup.md)
2. Users sign in with GitHub accounts
3. Done!

---

### Scenario 2: QMS With AI Assistant

**What you need:**
- ✅ GitHub OAuth (optional, but recommended)
- ✅ Claude Code OAuth (required for AI)

**Setup:**
1. Follow [GitHub OAuth Setup Guide](./github-oauth-setup.md) *(optional)*
2. Follow [Claude Code OAuth Setup Guide](../ai-integration/claude-code-oauth-setup.md) *(required)*
3. Users sign in with GitHub, AI assistant helps with compliance

---

### Scenario 3: Local Accounts Only

**What you need:**
- ❌ GitHub OAuth (not using SSO)
- ❌ Claude Code OAuth (not using AI)

**Setup:**
- No additional authentication setup needed
- Users create local accounts at first login
- Standard username/password authentication

---

## FAQ

### Can I use both GitHub OAuth and local accounts?

Yes! GitHub OAuth doesn't disable local accounts. Users can choose either method:
- "Sign in with GitHub" button for OAuth users
- Traditional username/password for local users

### Can I use GitHub OAuth without Claude AI features?

Absolutely! GitHub OAuth is independent of AI features. Set up only what you need.

### Can I use Claude AI without GitHub OAuth?

Yes! Users can sign in with local accounts while the AI assistant uses Claude Code OAuth.

### What if I want to use Anthropic API key instead of Claude Code OAuth?

See the [AI Integration Setup Guide](../ai-integration/gitea-actions-setup.md) for API key-based authentication.

### Can I disable GitHub OAuth after setting it up?

Yes, you can disable or remove OAuth sources:
```bash
docker exec -u git atomicqms gitea admin auth delete --id 1
docker compose restart
```

### How do I update OAuth credentials?

**GitHub OAuth:**
1. Update `.env` file with new credentials
2. Re-run `./setup-github-oauth.sh`

**Claude Code OAuth:**
1. Re-login to Claude Code: `claude logout && claude login`
2. Update repository secret with new token

---

## Security Best Practices

### For Both Authentication Methods

✅ **DO:**
- Use HTTPS in production
- Store secrets in environment variables or secret management systems
- Regularly review access logs
- Rotate credentials periodically
- Use minimal OAuth scopes

❌ **DON'T:**
- Commit credentials to Git
- Share OAuth tokens via email/chat
- Use development credentials in production
- Grant excessive OAuth permissions

### Audit Logging

All authentication events are logged:

```bash
# View authentication logs
docker logs atomicqms | grep -i "oauth\|auth"

# View Gitea logs
docker exec atomicqms cat /data/gitea/log/gitea.log | grep -i "oauth"
```

---

## Troubleshooting

### GitHub OAuth Issues

See the [GitHub OAuth Setup Guide - Troubleshooting](./github-oauth-setup.md#troubleshooting) section.

Common issues:
- No "Sign in with GitHub" button
- Redirect URI mismatch
- Incorrect credentials

### Claude Code OAuth Issues

See the [Claude Code OAuth Setup Guide - Troubleshooting](../ai-integration/claude-code-oauth-setup.md#part-7-troubleshooting) section.

Common issues:
- Workflow not triggering
- Authentication failed
- Token expired

---

## Additional Resources

### Documentation

- **GitHub OAuth Setup**: [./github-oauth-setup.md](./github-oauth-setup.md)
- **Claude Code OAuth Setup**: [../ai-integration/claude-code-oauth-setup.md](../ai-integration/claude-code-oauth-setup.md)
- **AI Integration Overview**: [../ai-integration/](../ai-integration/)
- **Quick Start**: [../guide/quick-start.md](../guide/quick-start.md)

### External Resources

- **GitHub OAuth Apps**: https://docs.github.com/en/apps/oauth-apps
- **Gitea Authentication**: https://docs.gitea.com/administration/authentication
- **Claude API**: https://docs.anthropic.com/claude/reference

---

## Quick Reference

### File Locations

```
# GitHub OAuth
.env                              # OAuth credentials (not in Git)
setup-github-oauth.sh             # Setup script
gitea/gitea/conf/app.ini         # OAuth capability config

# Claude Code OAuth
~/.config/claude/config.json     # Claude Code token (local)
.gitea/workflows/*.yml           # Workflow files using Claude
```

### Common Commands

```bash
# GitHub OAuth
./setup-github-oauth.sh                         # Run setup
docker exec -u git atomicqms gitea admin auth list  # Check config

# Claude Code OAuth
claude login                                     # Login to Claude Code
grep "oauth_token" ~/.config/claude/config.json # Get token
```

---

**Last Updated:** 2025-10-26
**Version:** 1.0.0
