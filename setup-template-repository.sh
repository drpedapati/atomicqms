#!/bin/bash
#
# Setup AtomicQMS Template Repository
#
# This script creates and configures the QMS template repository in Gitea
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  AtomicQMS Template Repository Setup${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Configuration
TEMPLATE_DIR="template-qms-repository"
REPO_NAME="atomicqms-template"
REPO_DESCRIPTION="AtomicQMS Repository Template - Includes AI assistant, QMS structure, and sample documents"
GITEA_URL="${GITEA_SERVER_URL:-http://localhost:3001}"

# Check 1: Template directory exists
echo -e "${BLUE}[1/7] Checking template directory...${NC}"
if [ ! -d "$TEMPLATE_DIR" ]; then
    echo -e "${RED}✗ Template directory not found: $TEMPLATE_DIR${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Template directory found${NC}\n"

# Check 2: Gitea is running
echo -e "${BLUE}[2/7] Checking Gitea connection...${NC}"
if ! curl -s "$GITEA_URL/api/v1/version" > /dev/null 2>&1; then
    echo -e "${RED}✗ Cannot connect to Gitea at $GITEA_URL${NC}"
    echo -e "${YELLOW}  Is AtomicQMS running? Check with: docker ps${NC}\n"
    exit 1
fi
echo -e "${GREEN}✓ Connected to Gitea${NC}\n"

# Check 3: Get Gitea credentials
echo -e "${BLUE}[3/7] Gitea Authentication${NC}"
echo -e "${CYAN}Please provide your Gitea credentials:${NC}"
read -p "Username: " GITEA_USER
read -sp "Password or Token: " GITEA_TOKEN
echo ""

# Validate credentials
if ! curl -s -u "$GITEA_USER:$GITEA_TOKEN" "$GITEA_URL/api/v1/user" > /dev/null 2>&1; then
    echo -e "${RED}✗ Authentication failed${NC}"
    echo -e "${YELLOW}  Check your username and password/token${NC}\n"
    exit 1
fi
echo -e "${GREEN}✓ Authenticated as $GITEA_USER${NC}\n"

# Check 4: Check if repository already exists
echo -e "${BLUE}[4/7] Checking if repository exists...${NC}"
if curl -s -u "$GITEA_USER:$GITEA_TOKEN" "$GITEA_URL/api/v1/repos/$GITEA_USER/$REPO_NAME" | grep -q "\"name\":\"$REPO_NAME\""; then
    echo -e "${YELLOW}⚠ Repository $REPO_NAME already exists${NC}"
    read -p "$(echo -e ${CYAN}Delete and recreate? [y/N]: ${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}  Deleting existing repository...${NC}"
        curl -s -X DELETE -u "$GITEA_USER:$GITEA_TOKEN" "$GITEA_URL/api/v1/repos/$GITEA_USER/$REPO_NAME"
        sleep 2
        echo -e "${GREEN}  ✓ Repository deleted${NC}"
    else
        echo -e "${YELLOW}  Aborting${NC}\n"
        exit 0
    fi
fi

# Step 5: Create repository
echo -e "\n${BLUE}[5/7] Creating repository...${NC}"
CREATE_RESPONSE=$(curl -s -u "$GITEA_USER:$GITEA_TOKEN" \
    -H "Content-Type: application/json" \
    -X POST "$GITEA_URL/api/v1/user/repos" \
    -d "{
        \"name\": \"$REPO_NAME\",
        \"description\": \"$REPO_DESCRIPTION\",
        \"private\": false,
        \"auto_init\": false,
        \"template\": false
    }")

if echo "$CREATE_RESPONSE" | grep -q "\"name\":\"$REPO_NAME\""; then
    echo -e "${GREEN}✓ Repository created${NC}\n"
else
    echo -e "${RED}✗ Failed to create repository${NC}"
    echo -e "${YELLOW}Response: $CREATE_RESPONSE${NC}\n"
    exit 1
fi

# Step 6: Initialize and push template
echo -e "${BLUE}[6/7] Pushing template files...${NC}"

# Save current directory
ORIG_DIR=$(pwd)

# Navigate to template directory
cd "$TEMPLATE_DIR"

# Initialize git if needed
if [ ! -d ".git" ]; then
    git init
    git config user.name "$GITEA_USER"
    git config user.email "$GITEA_USER@atomicqms.local"
fi

# Add all files
git add -A

# Commit
if git diff --cached --quiet; then
    echo -e "${YELLOW}⚠ No changes to commit (already committed)${NC}"
else
    git commit -m "Initial commit: AtomicQMS Template

Includes:
- AI assistant integration (Claude via Gitea Actions)
- QMS directory structure (SOPs, Forms, CAPAs)
- Sample templates for documentation
- Variable substitution configured

🤖 Generated with Claude Code" > /dev/null 2>&1
    echo -e "${GREEN}  ✓ Files committed${NC}"
fi

# Add remote
git remote remove origin 2>/dev/null || true
git remote add origin "$GITEA_URL/$GITEA_USER/$REPO_NAME.git"

# Push
if git push -u origin main --force 2>&1 | grep -q "error\|fatal"; then
    # Try master branch
    git branch -M master 2>/dev/null || true
    if git push -u origin master --force 2>&1; then
        echo -e "${GREEN}  ✓ Template pushed to Gitea${NC}\n"
    else
        echo -e "${RED}  ✗ Failed to push template${NC}\n"
        cd "$ORIG_DIR"
        exit 1
    fi
else
    echo -e "${GREEN}  ✓ Template pushed to Gitea${NC}\n"
fi

# Return to original directory
cd "$ORIG_DIR"

# Step 7: Mark as template repository
echo -e "${BLUE}[7/7] Configuring as template repository...${NC}"
PATCH_RESPONSE=$(curl -s -u "$GITEA_USER:$GITEA_TOKEN" \
    -H "Content-Type: application/json" \
    -X PATCH "$GITEA_URL/api/v1/repos/$GITEA_USER/$REPO_NAME" \
    -d "{
        \"template\": true
    }")

if echo "$PATCH_RESPONSE" | grep -q "\"template\":true"; then
    echo -e "${GREEN}✓ Repository marked as template${NC}\n"
else
    echo -e "${YELLOW}⚠ Could not automatically mark as template${NC}"
    echo -e "${YELLOW}  You can mark it manually in Gitea:${NC}"
    echo -e "${YELLOW}  Repository Settings → Advanced → Template Repository${NC}\n"
fi

# Success!
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ Template Repository Ready!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}Repository Details:${NC}"
echo -e "  Name: ${CYAN}$REPO_NAME${NC}"
echo -e "  URL: ${CYAN}$GITEA_URL/$GITEA_USER/$REPO_NAME${NC}"
echo -e "  Template: ${CYAN}Yes${NC}\n"

echo -e "${BLUE}Next Steps:${NC}\n"

echo -e "${YELLOW}1. View your template:${NC}"
echo -e "   ${CYAN}$GITEA_URL/$GITEA_USER/$REPO_NAME${NC}\n"

echo -e "${YELLOW}2. Create a repository from template:${NC}"
echo -e "   a) Go to: ${CYAN}$GITEA_URL/repo/create${NC}"
echo -e "   b) Select \"${CYAN}$REPO_NAME${NC}\" from template dropdown"
echo -e "   c) Name your new QMS repository"
echo -e "   d) Click \"Create Repository\"\n"

echo -e "${YELLOW}3. Configure AI assistant in new repository:${NC}"
echo -e "   a) Go to new repository Settings → Secrets"
echo -e "   b) Add: ${CYAN}ANTHROPIC_API_KEY${NC} or ${CYAN}CLAUDE_CODE_OAUTH_TOKEN${NC}"
echo -e "   c) Add: ${CYAN}GITEA_SERVER_URL${NC} = $GITEA_URL\n"

echo -e "${YELLOW}4. Test AI assistant:${NC}"
echo -e "   a) Create an issue in new repository"
echo -e "   b) Comment: ${CYAN}@qms-assistant Hello!${NC}"
echo -e "   c) Check Actions tab for workflow run\n"

echo -e "${BLUE}Template Features:${NC}"
echo -e "  ${GREEN}✓${NC} AI assistant pre-configured"
echo -e "  ${GREEN}✓${NC} QMS directory structure"
echo -e "  ${GREEN}✓${NC} SOP template"
echo -e "  ${GREEN}✓${NC} CAPA template"
echo -e "  ${GREEN}✓${NC} Variable substitution (repo name, owner, dates)"
echo -e "  ${GREEN}✓${NC} .gitignore configured"
echo -e "  ${GREEN}✓${NC} README with quick start guide\n"

echo -e "${BLUE}Documentation:${NC}"
echo -e "  • Template Usage: ${CYAN}docs/ai-integration/template-repository-setup.md${NC}"
echo -e "  • AI Integration: ${CYAN}docs/ai-integration/gitea-actions-setup.md${NC}\n"
