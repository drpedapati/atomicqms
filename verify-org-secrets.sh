#!/bin/bash
#
# Verify Organization Secrets
#
# Checks that organization-level secrets are properly configured

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Organization Secrets Verification${NC}"
echo -e "${BLUE}========================================${NC}\n"

ORG_NAME="atomicqms-lab"

# Get admin credentials
echo -e "${BLUE}Authentication${NC}"
echo -e "${YELLOW}Enter your Gitea admin username (default: admin):${NC}"
read -r GITEA_USER
GITEA_USER=${GITEA_USER:-admin}

echo -e "${YELLOW}Enter your Gitea admin password:${NC}"
read -s GITEA_PASSWORD
echo

# List organization secrets
echo -e "\n${BLUE}Checking Organization Secrets${NC}"
SECRETS_LIST=$(curl -s -u "$GITEA_USER:$GITEA_PASSWORD" \
  "http://localhost:3001/api/v1/orgs/$ORG_NAME/actions/secrets")

# Check if we got a valid response (array of secrets)
if echo "$SECRETS_LIST" | grep -q '\['; then
    echo -e "${GREEN}✓ Organization secrets API is accessible${NC}\n"

    # Check for CLAUDE_CODE_OAUTH_TOKEN
    if echo "$SECRETS_LIST" | grep -q '"name":"CLAUDE_CODE_OAUTH_TOKEN"'; then
        echo -e "${GREEN}✓ CLAUDE_CODE_OAUTH_TOKEN is set${NC}"
    else
        echo -e "${RED}✗ CLAUDE_CODE_OAUTH_TOKEN is NOT set${NC}"
    fi

    # Check for ANTHROPIC_API_KEY
    if echo "$SECRETS_LIST" | grep -q '"name":"ANTHROPIC_API_KEY"'; then
        echo -e "${GREEN}✓ ANTHROPIC_API_KEY is set${NC}"
    else
        echo -e "${YELLOW}⚠ ANTHROPIC_API_KEY is NOT set (optional if using OAuth token)${NC}"
    fi

    echo -e "\n${BLUE}Full secrets list:${NC}"
    echo "$SECRETS_LIST" | grep -o '"name":"[^"]*"' | cut -d':' -f2 | tr -d '"' | while read -r secret; do
        echo "  - $secret"
    done
else
    echo -e "${RED}✗ Failed to list organization secrets${NC}"
    echo "Response: $SECRETS_LIST"
    exit 1
fi

echo ""
