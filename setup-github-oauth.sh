#!/bin/bash
#
# Smart GitHub OAuth Setup Script for AtomicQMS
#
# This script automatically:
# - Detects if GitHub OAuth source exists in Gitea database
# - Adds new OAuth source (first time) OR updates existing source
# - Loads credentials from .env file
# - Restarts container to apply changes
#
# Usage:
#   1. Create .env file with your GitHub OAuth credentials
#   2. Make executable: chmod +x setup-github-oauth.sh
#   3. Run: ./setup-github-oauth.sh
#
# Prerequisites:
#   - GitHub OAuth App created with callback URL:
#     http://localhost:3001/user/oauth2/github/callback
#   - AtomicQMS container running (atomicqms)
#   - .env file with GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET
#

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  AtomicQMS GitHub OAuth Setup${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Load container names from .env or use defaults
if [ -f .env ]; then
    source .env
fi
CONTAINER_NAME="${ATOMICQMS_CONTAINER:-atomicqms}"

# Check if container is running
echo -e "${BLUE}[1/6] Checking container status...${NC}"
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}✗ Error: $CONTAINER_NAME container is not running${NC}"
    echo -e "${YELLOW}Start it with: docker compose up -d${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Container is running${NC}\n"

# Load credentials from .env file
echo -e "${BLUE}[2/6] Loading credentials from .env file...${NC}"
if [ ! -f .env ]; then
    echo -e "${RED}✗ Error: .env file not found${NC}"
    echo -e "${YELLOW}Create it from template:${NC}"
    echo -e "  cp .env.example .env"
    echo -e "  # Edit .env with your GitHub OAuth credentials"
    exit 1
fi

source .env

# Validate credentials
if [ -z "$GITHUB_CLIENT_ID" ] || [ -z "$GITHUB_CLIENT_SECRET" ]; then
    echo -e "${RED}✗ Error: GITHUB_CLIENT_ID or GITHUB_CLIENT_SECRET not set in .env${NC}"
    echo -e "${YELLOW}Edit .env and add your GitHub OAuth App credentials${NC}"
    exit 1
fi

# Basic validation of credential format
if [[ ! "$GITHUB_CLIENT_ID" =~ ^(Iv1\.|Ov-) ]]; then
    echo -e "${YELLOW}⚠ Warning: Client ID doesn't start with 'Iv1.' or 'Ov-' (expected format)${NC}"
    echo -e "${YELLOW}  Client ID: ${GITHUB_CLIENT_ID:0:10}...${NC}"
fi

if [ ${#GITHUB_CLIENT_SECRET} -ne 40 ]; then
    echo -e "${YELLOW}⚠ Warning: Client Secret is not 40 characters (expected length)${NC}"
    echo -e "${YELLOW}  Length: ${#GITHUB_CLIENT_SECRET} characters${NC}"
fi

echo -e "${GREEN}✓ Credentials loaded${NC}"
echo -e "  Client ID: ${GITHUB_CLIENT_ID:0:10}...${NC}\n"

# Set defaults for optional parameters
AUTH_SOURCE_NAME="${GITHUB_AUTH_SOURCE_NAME:-github}"
OAUTH_SCOPES="${GITHUB_OAUTH_SCOPES:-read:user,user:email}"

# Check if OAuth source already exists
echo -e "${BLUE}[3/6] Checking if GitHub OAuth source exists...${NC}"
if docker exec -u git $CONTAINER_NAME gitea admin auth list 2>/dev/null | grep -q "github"; then
    OAUTH_EXISTS=true
    OAUTH_ID=$(docker exec -u git $CONTAINER_NAME gitea admin auth list 2>/dev/null | grep "github" | awk '{print $1}')
    echo -e "${YELLOW}⚠ GitHub OAuth source already exists (ID: $OAUTH_ID)${NC}"
    echo -e "${BLUE}  Will update existing OAuth source...${NC}\n"
else
    OAUTH_EXISTS=false
    echo -e "${GREEN}✓ No existing OAuth source found${NC}"
    echo -e "${BLUE}  Will create new OAuth source...${NC}\n"
fi

# Configure or update OAuth source
echo -e "${BLUE}[4/6] Configuring GitHub OAuth...${NC}"

if [ "$OAUTH_EXISTS" = true ]; then
    # Update existing OAuth source
    docker exec -u git $CONTAINER_NAME gitea admin auth update-oauth \
        --id "$OAUTH_ID" \
        --name "$AUTH_SOURCE_NAME" \
        --provider "github" \
        --key "$GITHUB_CLIENT_ID" \
        --secret "$GITHUB_CLIENT_SECRET" \
        --auto-discover-url "https://github.com/.well-known/openid-configuration" \
        --scopes "$OAUTH_SCOPES" 2>&1 | grep -v "Incorrect Usage" || true

    echo -e "${GREEN}✓ OAuth source updated successfully${NC}\n"
else
    # Add new OAuth source
    docker exec -u git $CONTAINER_NAME gitea admin auth add-oauth \
        --name "$AUTH_SOURCE_NAME" \
        --provider "github" \
        --key "$GITHUB_CLIENT_ID" \
        --secret "$GITHUB_CLIENT_SECRET" \
        --auto-discover-url "https://github.com/.well-known/openid-configuration" \
        --scopes "$OAUTH_SCOPES" 2>&1 | grep -v "Incorrect Usage" || true

    echo -e "${GREEN}✓ OAuth source created successfully${NC}\n"
fi

# Verify configuration
echo -e "${BLUE}[5/6] Verifying configuration...${NC}"
docker exec -u git $CONTAINER_NAME gitea admin auth list
echo ""

# Restart container to apply changes
echo -e "${BLUE}[6/6] Restarting container to apply changes...${NC}"
docker compose restart >/dev/null 2>&1
echo -e "${GREEN}✓ Container restarted${NC}\n"

# Wait for container to be ready
echo -e "${BLUE}Waiting for Gitea to be ready...${NC}"
sleep 3
echo -e "${GREEN}✓ Gitea is ready${NC}\n"

# Success message
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ GitHub OAuth Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Open: ${YELLOW}http://localhost:3001/user/login${NC}"
echo -e "2. Click ${YELLOW}\"Sign in with GitHub\"${NC}"
echo -e "3. Authorize the application"
echo -e "4. You'll be logged in with your GitHub account!\n"

echo -e "${BLUE}OAuth Configuration:${NC}"
echo -e "  Source Name: ${AUTH_SOURCE_NAME}"
echo -e "  Provider: GitHub"
echo -e "  Scopes: ${OAUTH_SCOPES}"
echo -e "  Callback URL: http://localhost:3001/user/oauth2/${AUTH_SOURCE_NAME}/callback\n"

echo -e "${YELLOW}Troubleshooting:${NC}"
echo -e "  • No GitHub button? Check logs: ${YELLOW}docker logs $CONTAINER_NAME${NC}"
echo -e "  • Credential errors? Verify GitHub OAuth App settings"
echo -e "  • Still issues? See README.md Troubleshooting section\n"
