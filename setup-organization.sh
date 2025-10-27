#!/bin/bash
#
# Setup Default AtomicQMS Organization
#
# Creates atomicqms-lab organization and sets up organization-level secrets
# for zero-config Claude AI integration across all repositories

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  AtomicQMS Organization Setup${NC}"
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

# Get admin credentials
echo -e "${BLUE}[1/4] Gitea Authentication${NC}"

# Use default credentials (consistent with setup-all.sh)
GITEA_USER="${ATOMICQMS_ADMIN_USER:-admin}"
GITEA_PASSWORD="${ATOMICQMS_ADMIN_PASSWORD:-atomicqms123}"

echo -e "${CYAN}Using credentials: ${GITEA_USER} / atomicqms123${NC}"
echo -e "${YELLOW}(Set ATOMICQMS_ADMIN_USER and ATOMICQMS_ADMIN_PASSWORD to override)${NC}"

# Create organization
echo -e "\n${BLUE}[2/4] Creating Organization${NC}"
ORG_NAME="atomicqms-lab"
ORG_FULL_NAME="AtomicQMS Lab"
ORG_DESCRIPTION="Default organization for AtomicQMS repositories and team collaboration"

# Check if org already exists
ORG_EXISTS=$(curl -s -u "$GITEA_USER:$GITEA_PASSWORD" \
  "http://localhost:3001/api/v1/orgs/$ORG_NAME" | grep -o '"username":"atomicqms-lab"' || echo "")

if [ -n "$ORG_EXISTS" ]; then
    echo -e "${YELLOW}Organization '$ORG_NAME' already exists${NC}"
else
    # Create organization
    CREATE_RESULT=$(curl -s -u "$GITEA_USER:$GITEA_PASSWORD" \
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
        echo "$CREATE_RESULT"
        exit 1
    fi
fi

# Set organization-level secret
echo -e "\n${BLUE}[3/4] Setting Organization-Level Secret${NC}"

if [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    echo -e "${RED}Error: CLAUDE_CODE_OAUTH_TOKEN not found in .env${NC}"
    exit 1
fi

SECRET_RESULT=$(curl -s -u "$GITEA_USER:$GITEA_PASSWORD" \
  -X PUT "http://localhost:3001/api/v1/orgs/$ORG_NAME/actions/secrets/CLAUDE_CODE_OAUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"data\":\"$CLAUDE_CODE_OAUTH_TOKEN\"}")

if echo "$SECRET_RESULT" | grep -q '"name":"CLAUDE_CODE_OAUTH_TOKEN"' || [ -z "$SECRET_RESULT" ]; then
    echo -e "${GREEN}✓ Set CLAUDE_CODE_OAUTH_TOKEN secret at organization level${NC}"
else
    echo -e "${RED}✗ Failed to set organization secret${NC}"
    echo "$SECRET_RESULT"
    exit 1
fi

# Transfer template repository to organization
echo -e "\n${BLUE}[4/4] Transferring Template Repository${NC}"

# Check if template exists
TEMPLATE_EXISTS=$(curl -s "http://localhost:3001/api/v1/repos/$GITEA_USER/atomicqms-template" | grep -o '"name":"atomicqms-template"' || echo "")

if [ -n "$TEMPLATE_EXISTS" ]; then
    # Transfer to organization
    TRANSFER_RESULT=$(curl -s -u "$GITEA_USER:$GITEA_PASSWORD" \
      -X POST "http://localhost:3001/api/v1/repos/$GITEA_USER/atomicqms-template/transfer" \
      -H "Content-Type: application/json" \
      -d "{\"new_owner\":\"$ORG_NAME\"}")

    if echo "$TRANSFER_RESULT" | grep -q "\"owner\".*\"login\":\"$ORG_NAME\"" || echo "$TRANSFER_RESULT" | grep -q "already been transferred"; then
        echo -e "${GREEN}✓ Template repository belongs to organization${NC}"
    else
        echo -e "${YELLOW}Note: Template may already belong to organization${NC}"
    fi
else
    echo -e "${YELLOW}Template repository not found - will be created in organization${NC}"
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
