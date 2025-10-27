#!/bin/bash
#
# Setup Default AtomicQMS Organization (Token-based Authentication)
#
# Creates atomicqms-lab organization and sets up organization-level secrets
# for zero-config Claude AI integration across all repositories
#
# PREREQUISITE: Create a Gitea Personal Access Token with the following scopes:
#   - admin:org (to create and manage organizations)
#   - write:repository (to transfer repositories)
#   - read:user (to verify authentication)
#
# To create a token:
#   1. Log in to Gitea: http://localhost:3001
#   2. Go to Settings > Applications > Generate New Token
#   3. Select the required scopes listed above
#   4. Copy the generated token

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  AtomicQMS Organization Setup${NC}"
echo -e "${BLUE}  (Token-based Authentication)${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check if Gitea is running
if ! curl -s http://localhost:3001 > /dev/null; then
    echo -e "${RED}Error: Gitea is not running at http://localhost:3001${NC}"
    echo "Start AtomicQMS first: docker compose up -d"
    exit 1
fi

# Load credentials from .env
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Run setup-claude-assistant.sh first to create .env"
    exit 1
fi

# Extract CLAUDE_CODE_OAUTH_TOKEN from .env (handle values with spaces)
CLAUDE_CODE_OAUTH_TOKEN=$(grep "^CLAUDE_CODE_OAUTH_TOKEN=" .env | cut -d'=' -f2-)

# Get API token
echo -e "${BLUE}[1/5] Authentication${NC}"
echo -e "${YELLOW}This script requires a Gitea Personal Access Token.${NC}\n"
echo "If you don't have one yet:"
echo "  1. Go to: http://localhost:3001/user/settings/applications"
echo "  2. Click 'Generate New Token'"
echo "  3. Token Name: 'atomicqms-setup'"
echo "  4. Select scopes: admin:org, write:repository, read:user"
echo "  5. Click 'Generate Token' and copy the token"
echo ""
echo -e "${YELLOW}Enter your Gitea Personal Access Token:${NC}"
read -s GITEA_TOKEN
echo

# Verify token works
echo -e "\n${BLUE}[2/5] Verifying Token${NC}"
USER_INFO=$(curl -s -H "Authorization: token $GITEA_TOKEN" \
  "http://localhost:3001/api/v1/user")

if echo "$USER_INFO" | grep -q '"login"'; then
    USERNAME=$(echo "$USER_INFO" | grep -o '"login":"[^"]*"' | cut -d'"' -f4)
    echo -e "${GREEN}✓ Authenticated as: $USERNAME${NC}"
else
    echo -e "${RED}✗ Authentication failed${NC}"
    echo "Response: $USER_INFO"
    echo ""
    echo "Please check:"
    echo "  - Token is valid and not expired"
    echo "  - Token has 'admin:org' and 'write:repository' scopes"
    exit 1
fi

# Create organization
echo -e "\n${BLUE}[3/5] Creating Organization${NC}"
ORG_NAME="atomicqms-lab"
ORG_FULL_NAME="AtomicQMS Lab"
ORG_DESCRIPTION="Default organization for AtomicQMS repositories and team collaboration"

# Check if org already exists
ORG_EXISTS=$(curl -s -H "Authorization: token $GITEA_TOKEN" \
  "http://localhost:3001/api/v1/orgs/$ORG_NAME" | grep -o '"username":"atomicqms-lab"' || echo "")

if [ -n "$ORG_EXISTS" ]; then
    echo -e "${YELLOW}Organization '$ORG_NAME' already exists${NC}"
else
    # Create organization
    CREATE_RESULT=$(curl -s -H "Authorization: token $GITEA_TOKEN" \
      -X POST "http://localhost:3001/api/v1/orgs" \
      -H "Content-Type: application/json" \
      -d "{
        \"username\": \"$ORG_NAME\",
        \"full_name\": \"$ORG_FULL_NAME\",
        \"description\": \"$ORG_DESCRIPTION\",
        \"visibility\": \"public\"
      }")

    if echo "$CREATE_RESULT" | grep -q '"username":"atomicqms-lab"'; then
        echo -e "${GREEN}✓ Created organization: $ORG_NAME${NC}"
    else
        echo -e "${RED}✗ Failed to create organization${NC}"
        echo "Response: $CREATE_RESULT"
        echo ""
        echo "Common issues:"
        echo "  - Organization name already taken"
        echo "  - Token lacks 'admin:org' scope"
        echo "  - User doesn't have permission to create organizations"
        exit 1
    fi
fi

# Set organization-level secret
echo -e "\n${BLUE}[4/5] Setting Organization-Level Secret${NC}"

if [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    echo -e "${RED}Error: CLAUDE_CODE_OAUTH_TOKEN not found in .env${NC}"
    exit 1
fi

SECRET_RESULT=$(curl -s -H "Authorization: token $GITEA_TOKEN" \
  -X PUT "http://localhost:3001/api/v1/orgs/$ORG_NAME/actions/secrets/CLAUDE_CODE_OAUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"data\":\"$CLAUDE_CODE_OAUTH_TOKEN\"}")

if echo "$SECRET_RESULT" | grep -q '"name":"CLAUDE_CODE_OAUTH_TOKEN"' || [ -z "$SECRET_RESULT" ]; then
    echo -e "${GREEN}✓ Set CLAUDE_CODE_OAUTH_TOKEN secret at organization level${NC}"
else
    echo -e "${RED}✗ Failed to set organization secret${NC}"
    echo "Response: $SECRET_RESULT"
    echo ""
    echo "Common issues:"
    echo "  - Token lacks 'admin:org' scope"
    echo "  - User is not an organization admin"
    exit 1
fi

# Transfer template repository to organization
echo -e "\n${BLUE}[5/5] Transferring Template Repository${NC}"

# Check if template exists under current user
TEMPLATE_EXISTS=$(curl -s -H "Authorization: token $GITEA_TOKEN" \
  "http://localhost:3001/api/v1/repos/$USERNAME/atomicqms-template" | grep -o '"name":"atomicqms-template"' || echo "")

if [ -n "$TEMPLATE_EXISTS" ]; then
    # Transfer to organization
    TRANSFER_RESULT=$(curl -s -H "Authorization: token $GITEA_TOKEN" \
      -X POST "http://localhost:3001/api/v1/repos/$USERNAME/atomicqms-template/transfer" \
      -H "Content-Type: application/json" \
      -d "{\"new_owner\":\"$ORG_NAME\"}")

    if echo "$TRANSFER_RESULT" | grep -q "\"owner\".*\"login\":\"$ORG_NAME\""; then
        echo -e "${GREEN}✓ Template repository transferred to organization${NC}"
    elif echo "$TRANSFER_RESULT" | grep -q "already been transferred"; then
        echo -e "${GREEN}✓ Template repository already belongs to organization${NC}"
    else
        echo -e "${YELLOW}Note: Template may already belong to organization${NC}"
        echo "Response: $TRANSFER_RESULT"
    fi
else
    # Check if template already exists in organization
    ORG_TEMPLATE_EXISTS=$(curl -s -H "Authorization: token $GITEA_TOKEN" \
      "http://localhost:3001/api/v1/repos/$ORG_NAME/atomicqms-template" | grep -o '"name":"atomicqms-template"' || echo "")

    if [ -n "$ORG_TEMPLATE_EXISTS" ]; then
        echo -e "${GREEN}✓ Template repository already exists in organization${NC}"
    else
        echo -e "${YELLOW}⚠ Template repository not found${NC}"
        echo "You can create it manually:"
        echo "  1. Create 'atomicqms-template' repository in '$ORG_NAME' organization"
        echo "  2. Mark it as a template in repository settings"
    fi
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Organization Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "Organization: ${BLUE}$ORG_NAME${NC}"
echo -e "URL: ${BLUE}http://localhost:3001/$ORG_NAME${NC}"
echo -e "Secret: ${GREEN}CLAUDE_CODE_OAUTH_TOKEN${NC} (organization-level)"
echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Create new repositories in the '$ORG_NAME' organization"
echo "2. Use 'atomicqms-template' when creating repos"
echo "3. AI assistant will work automatically with zero configuration!"
echo ""
echo -e "${YELLOW}Note:${NC} You can rename the organization in Gitea Settings"
echo ""
