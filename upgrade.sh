#!/bin/bash
#
# AtomicQMS Feature Upgrade Script
#
# Safe upgrade path for existing installations.
# Add GitHub OAuth or AI Assistant without touching your data.
#
# Usage: ./upgrade.sh
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
echo -e "${BLUE}  AtomicQMS Feature Upgrade${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${GREEN}This script safely adds features to your existing AtomicQMS.${NC}"
echo -e "${GREEN}Your data, repos, and users will NOT be modified.${NC}\n"

# Check if AtomicQMS is running
if ! docker ps --filter "name=atomicqms" --filter "status=running" --format "{{.Names}}" | grep -q "atomicqms"; then
    echo -e "${RED}✗ AtomicQMS is not running${NC}"
    echo -e "${YELLOW}Start it first: docker compose up -d${NC}\n"
    exit 1
fi

echo -e "${GREEN}✓ AtomicQMS is running${NC}\n"

# Check what features are already installed
echo -e "${BLUE}Checking current installation...${NC}\n"

# Check GitHub OAuth
if docker exec -u git atomicqms gitea admin auth list 2>/dev/null | grep -q "github"; then
    OAUTH_INSTALLED="true"
    echo -e "  GitHub OAuth (SSO): ${GREEN}✓ Installed${NC}"
else
    OAUTH_INSTALLED="false"
    echo -e "  GitHub OAuth (SSO): ${YELLOW}⚠ Not installed${NC}"
fi

# Check AI Assistant (runner container)
if docker ps --filter "name=atomicqms-runner" --filter "status=running" --format "{{.Names}}" | grep -q "atomicqms-runner"; then
    AI_INSTALLED="true"
    echo -e "  AI Assistant:       ${GREEN}✓ Installed${NC}"
else
    AI_INSTALLED="false"
    echo -e "  AI Assistant:       ${YELLOW}⚠ Not installed${NC}"
fi

# Check organization
if curl -s http://localhost:3001/api/v1/orgs/atomicqms-lab 2>/dev/null | grep -q '"username":"atomicqms-lab"'; then
    ORG_INSTALLED="true"
    echo -e "  Organization:       ${GREEN}✓ Installed${NC}"
else
    ORG_INSTALLED="false"
    echo -e "  Organization:       ${YELLOW}⚠ Not installed${NC}"
fi

echo ""

# Check what can be installed
CAN_INSTALL_OAUTH="false"
CAN_INSTALL_AI="false"

# Check for OAuth credentials in .env
if [ -f ".env" ]; then
    if grep -q "^GITHUB_CLIENT_ID=" .env && grep -q "^GITHUB_CLIENT_SECRET=" .env; then
        CLIENT_ID=$(grep "^GITHUB_CLIENT_ID=" .env | cut -d'=' -f2- | grep -v "xxxx" || echo "")
        CLIENT_SECRET=$(grep "^GITHUB_CLIENT_SECRET=" .env | cut -d'=' -f2- | grep -v "xxxx" || echo "")
        if [ -n "$CLIENT_ID" ] && [ -n "$CLIENT_SECRET" ]; then
            CAN_INSTALL_OAUTH="true"
        fi
    fi

    # Check for AI credentials
    if grep -q "^CLAUDE_CODE_OAUTH_TOKEN=" .env || grep -q "^ANTHROPIC_API_KEY=" .env; then
        TOKEN=$(grep "^CLAUDE_CODE_OAUTH_TOKEN=" .env | cut -d'=' -f2- 2>/dev/null || echo "")
        API_KEY=$(grep "^ANTHROPIC_API_KEY=" .env | cut -d'=' -f2- 2>/dev/null || echo "")
        if [ -n "$TOKEN" ] || [ -n "$API_KEY" ]; then
            CAN_INSTALL_AI="true"
        fi
    fi
fi

# Build menu
echo -e "${CYAN}What would you like to add?${NC}\n"

MENU_OPTIONS=()
MENU_ACTIONS=()

# GitHub OAuth option
if [ "$OAUTH_INSTALLED" == "false" ]; then
    if [ "$CAN_INSTALL_OAUTH" == "true" ]; then
        MENU_OPTIONS+=("GitHub OAuth (Single Sign-On)")
        MENU_ACTIONS+=("install_oauth")
    else
        MENU_OPTIONS+=("GitHub OAuth (Single Sign-On) ${YELLOW}(needs credentials in .env)${NC}")
        MENU_ACTIONS+=("setup_oauth_creds")
    fi
fi

# AI Assistant option
if [ "$AI_INSTALLED" == "false" ]; then
    if [ "$CAN_INSTALL_AI" == "true" ]; then
        MENU_OPTIONS+=("AI Assistant (@qms-assistant)")
        MENU_ACTIONS+=("install_ai")
    else
        MENU_OPTIONS+=("AI Assistant (@qms-assistant) ${YELLOW}(needs credentials in .env)${NC}")
        MENU_ACTIONS+=("setup_ai_creds")
    fi
fi

# Organization option
if [ "$ORG_INSTALLED" == "false" ] && [ "$AI_INSTALLED" == "true" ]; then
    MENU_OPTIONS+=("Organization (atomicqms-lab)")
    MENU_ACTIONS+=("install_org")
fi

# Show existing installations message
if [ "$OAUTH_INSTALLED" == "true" ] && [ "$AI_INSTALLED" == "true" ] && [ "$ORG_INSTALLED" == "true" ]; then
    echo -e "${GREEN}✓ All features are already installed!${NC}\n"
    echo -e "Your AtomicQMS has:"
    echo -e "  • GitHub Single Sign-On"
    echo -e "  • AI Assistant"
    echo -e "  • Organization setup"
    echo ""
    exit 0
fi

# Show menu
if [ ${#MENU_OPTIONS[@]} -eq 0 ]; then
    echo -e "${YELLOW}No features available to add right now.${NC}"
    echo -e "Check UPGRADE.md for manual setup instructions.\n"
    exit 0
fi

for i in "${!MENU_OPTIONS[@]}"; do
    echo "$((i+1))) ${MENU_OPTIONS[$i]}"
done
echo "$((${#MENU_OPTIONS[@]}+1))) Exit without changes"

echo ""
read -p "Choose [1-$((${#MENU_OPTIONS[@]}+1))]: " choice

if [ "$choice" -eq "$((${#MENU_OPTIONS[@]}+1))" ] 2>/dev/null; then
    echo -e "\n${YELLOW}No changes made${NC}\n"
    exit 0
fi

if [ "$choice" -lt 1 ] || [ "$choice" -gt "${#MENU_OPTIONS[@]}" ] 2>/dev/null; then
    echo -e "\n${RED}Invalid choice${NC}\n"
    exit 1
fi

ACTION="${MENU_ACTIONS[$((choice-1))]}"

case "$ACTION" in
    setup_oauth_creds)
        echo -e "\n${BLUE}Setting up GitHub OAuth credentials...${NC}\n"
        echo -e "${CYAN}Step 1: Create GitHub OAuth App${NC}"
        echo -e "  1. Go to: ${YELLOW}https://github.com/settings/developers${NC}"
        echo -e "  2. Click: 'New OAuth App'"
        echo -e "  3. Set callback URL: ${YELLOW}http://localhost:3001/user/oauth2/github/callback${NC}"
        echo -e "  4. Copy the Client ID and generate a Client Secret\n"

        echo -e "${CYAN}Step 2: Add to .env file${NC}"
        echo -e "  Run these commands:\n"
        echo -e "  ${YELLOW}# If .env doesn't exist:${NC}"
        echo -e "  ${CYAN}cp .env.example .env${NC}\n"
        echo -e "  ${YELLOW}# Add these lines to .env:${NC}"
        echo -e "  ${CYAN}GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxxx${NC}"
        echo -e "  ${CYAN}GITHUB_CLIENT_SECRET=ghp_xxxxxxxxxxxxxxxx${NC}\n"

        echo -e "${CYAN}Step 3: Run upgrade again${NC}"
        echo -e "  ${CYAN}./upgrade.sh${NC}\n"
        exit 0
        ;;

    setup_ai_creds)
        echo -e "\n${BLUE}Setting up AI Assistant credentials...${NC}\n"
        echo -e "${CYAN}Step 1: Get Claude AI credentials${NC}"
        echo -e "  ${YELLOW}Option A:${NC} Claude Code OAuth Token (requires Claude Max)"
        echo -e "    Get from: ${YELLOW}https://claude.ai/code${NC}\n"
        echo -e "  ${YELLOW}Option B:${NC} Anthropic API Key"
        echo -e "    Get from: ${YELLOW}https://console.anthropic.com${NC}\n"

        echo -e "${CYAN}Step 2: Add to .env file${NC}"
        echo -e "  Run these commands:\n"
        echo -e "  ${YELLOW}# If .env doesn't exist:${NC}"
        echo -e "  ${CYAN}cp .env.example .env${NC}\n"
        echo -e "  ${YELLOW}# Add ONE of these lines to .env:${NC}"
        echo -e "  ${CYAN}CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-...${NC}"
        echo -e "  ${CYAN}ANTHROPIC_API_KEY=sk-ant-api03-...${NC}\n"

        echo -e "${CYAN}Step 3: Run upgrade again${NC}"
        echo -e "  ${CYAN}./upgrade.sh${NC}\n"
        exit 0
        ;;

    install_oauth)
        echo -e "\n${BLUE}Installing GitHub OAuth...${NC}\n"
        echo -e "${GREEN}This will:${NC}"
        echo -e "  • Add GitHub as login option"
        echo -e "  • Enable Single Sign-On"
        echo -e "  • Restart Gitea (~3 seconds downtime)"
        echo -e "\n${GREEN}This will NOT:${NC}"
        echo -e "  • Modify your repositories"
        echo -e "  • Change user data"
        echo -e "  • Affect existing issues/PRs\n"

        read -p "Continue? [y/N]: " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            echo -e "\n${YELLOW}Cancelled${NC}\n"
            exit 0
        fi

        ./setup-github-oauth.sh
        ;;

    install_ai)
        echo -e "\n${BLUE}Installing AI Assistant...${NC}\n"
        echo -e "${GREEN}This will:${NC}"
        echo -e "  • Start the Actions runner"
        echo -e "  • Enable @qms-assistant in your repos"
        echo -e "  • Add AI-powered code review"
        echo -e "\n${GREEN}This will NOT:${NC}"
        echo -e "  • Modify your repositories"
        echo -e "  • Change any code"
        echo -e "  • Cause any downtime\n"

        read -p "Continue? [y/N]: " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            echo -e "\n${YELLOW}Cancelled${NC}\n"
            exit 0
        fi

        ./setup-claude-assistant.sh
        ;;

    install_org)
        echo -e "\n${BLUE}Installing Organization...${NC}\n"
        echo -e "${GREEN}This will:${NC}"
        echo -e "  • Create 'atomicqms-lab' organization"
        echo -e "  • Set organization-level AI credentials"
        echo -e "  • Create template repository"
        echo -e "\n${GREEN}This will NOT:${NC}"
        echo -e "  • Move your existing repositories"
        echo -e "  • Change any data"
        echo -e "  • Cause any downtime\n"

        read -p "Continue? [y/N]: " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            echo -e "\n${YELLOW}Cancelled${NC}\n"
            exit 0
        fi

        ./setup-organization.sh
        ;;
esac

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Upgrade Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "Access AtomicQMS: ${CYAN}http://localhost:3001${NC}\n"
echo -e "${BLUE}To add more features, run:${NC} ${CYAN}./upgrade.sh${NC}\n"
