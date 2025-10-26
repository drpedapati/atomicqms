#!/bin/bash
#
# Smart Claude AI Assistant Setup Script for AtomicQMS
#
# This script automatically:
# - Validates prerequisites (Actions enabled, workflow files)
# - Helps configure Gitea Actions runner registration
# - Verifies runner connection
# - Provides guidance for repository secret setup
# - Tests AI assistant integration
#
# Usage:
#   1. Ensure AtomicQMS is running
#   2. Get runner token from Gitea: Site Admin → Actions → Runners → Create new Runner
#   3. Make executable: chmod +x setup-claude-assistant.sh
#   4. Run: ./setup-claude-assistant.sh
#
# Prerequisites:
#   - AtomicQMS container running (atomicqms)
#   - Admin access to Gitea
#   - .env file (will be created/updated)
#

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  AtomicQMS AI Assistant Setup${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Load container names from .env or use defaults
if [ -f .env ]; then
    source .env
fi
CONTAINER_NAME="${ATOMICQMS_CONTAINER:-atomicqms}"
RUNNER_CONTAINER="${ATOMICQMS_RUNNER_CONTAINER:-atomicqms-runner}"

# Check if containers are running
echo -e "${BLUE}[1/8] Checking prerequisites...${NC}"

if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}✗ Error: $CONTAINER_NAME container is not running${NC}"
    echo -e "${YELLOW}Start it with: docker compose up -d${NC}"
    exit 1
fi
echo -e "${GREEN}✓ AtomicQMS container is running${NC}"

# Check if Actions are enabled
echo -e "${BLUE}[2/8] Verifying Gitea Actions are enabled...${NC}"
if docker exec $CONTAINER_NAME grep -q "ENABLED = true" /data/gitea/conf/app.ini 2>/dev/null | grep -A 1 "\[actions\]"; then
    echo -e "${GREEN}✓ Gitea Actions are enabled${NC}"
else
    echo -e "${YELLOW}⚠ Warning: Gitea Actions may not be enabled${NC}"
    echo -e "${YELLOW}  Check [actions] section in app.ini${NC}"
fi

# Check for workflow files
echo -e "\n${BLUE}[3/8] Checking workflow files...${NC}"
if [ -f ".gitea/workflows/claude-qms-assistant.yml" ]; then
    echo -e "${GREEN}✓ AI assistant workflow found${NC}"
    echo -e "  Location: .gitea/workflows/claude-qms-assistant.yml"
else
    echo -e "${RED}✗ Workflow file not found${NC}"
    echo -e "${YELLOW}  Expected: .gitea/workflows/claude-qms-assistant.yml${NC}"
    echo -e "${YELLOW}  This file is required for AI assistant to work${NC}"
fi

# Check/create .env file
echo -e "\n${BLUE}[4/8] Configuring environment variables...${NC}"

if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠ .env file not found, creating from template...${NC}"
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${GREEN}✓ Created .env from template${NC}"
    else
        echo -e "${YELLOW}⚠ .env.example not found, creating new .env${NC}"
        touch .env
    fi
fi

# Check if RUNNER_TOKEN exists in .env
if grep -q "^RUNNER_TOKEN=" .env; then
    RUNNER_TOKEN=$(grep "^RUNNER_TOKEN=" .env | cut -d'=' -f2)
    if [ -z "$RUNNER_TOKEN" ] || [ "$RUNNER_TOKEN" = "your_runner_registration_token_here" ]; then
        NEED_RUNNER_TOKEN=true
    else
        echo -e "${GREEN}✓ Runner token found in .env${NC}"
        NEED_RUNNER_TOKEN=false
    fi
else
    NEED_RUNNER_TOKEN=true
fi

if [ "$NEED_RUNNER_TOKEN" = true ]; then
    echo -e "${YELLOW}⚠ Runner token not configured${NC}"
    echo -e "${BLUE}  Attempting to auto-generate token...${NC}"

    # Try to auto-generate token via Gitea CLI
    AUTO_TOKEN=$(docker exec -u git $CONTAINER_NAME gitea actions generate-runner-token 2>&1 | head -1)

    if [ ! -z "$AUTO_TOKEN" ] && [ ${#AUTO_TOKEN} -gt 20 ] && [[ ! "$AUTO_TOKEN" =~ "Error" ]]; then
        echo -e "${GREEN}✓ Token generated automatically${NC}"
        echo -e "  Token: ${AUTO_TOKEN:0:10}...${AUTO_TOKEN: -10}"
        INPUT_RUNNER_TOKEN=$AUTO_TOKEN
    else
        echo -e "${YELLOW}⚠ Auto-generation failed, manual input required${NC}"
        echo -e "\n${CYAN}To get your runner registration token:${NC}"
        echo -e "  1. Open: ${YELLOW}http://localhost:3001${NC}"
        echo -e "  2. Log in as admin"
        echo -e "  3. Go to: ${YELLOW}Site Administration → Actions → Runners${NC}"
        echo -e "  4. Click: ${YELLOW}Create new Runner${NC}"
        echo -e "  5. Copy the token shown in the registration command"
        echo -e "\n${CYAN}Example token format:${NC}"
        echo -e "  ${YELLOW}AbCdEfGhIjKlMnOpQrStUvWxYz1234567890${NC}"
        echo -e ""

        read -p "$(echo -e ${CYAN}Enter your runner registration token: ${NC})" INPUT_RUNNER_TOKEN

        if [ -z "$INPUT_RUNNER_TOKEN" ]; then
            echo -e "${RED}✗ No token provided${NC}"
            exit 1
        fi
    fi

    # Update or add RUNNER_TOKEN to .env
    if grep -q "^RUNNER_TOKEN=" .env; then
        # macOS compatible sed
        sed -i '' "s|^RUNNER_TOKEN=.*|RUNNER_TOKEN=$INPUT_RUNNER_TOKEN|" .env 2>/dev/null || \
        sed -i "s|^RUNNER_TOKEN=.*|RUNNER_TOKEN=$INPUT_RUNNER_TOKEN|" .env
    else
        echo "RUNNER_TOKEN=$INPUT_RUNNER_TOKEN" >> .env
    fi

    echo -e "${GREEN}✓ Runner token added to .env${NC}"
    RUNNER_TOKEN=$INPUT_RUNNER_TOKEN
fi

# Check GITEA_SERVER_URL
if ! grep -q "^GITEA_SERVER_URL=" .env; then
    echo -e "${YELLOW}⚠ GITEA_SERVER_URL not set, adding default...${NC}"
    echo "GITEA_SERVER_URL=http://localhost:3001" >> .env
    echo -e "${GREEN}✓ Added GITEA_SERVER_URL=http://localhost:3001${NC}"
fi

# Show current configuration
echo -e "\n${BLUE}[5/8] Current configuration:${NC}"
echo -e "  Runner Token: ${RUNNER_TOKEN:0:10}...${RUNNER_TOKEN: -10}"
GITEA_URL=$(grep "^GITEA_SERVER_URL=" .env | cut -d'=' -f2)
echo -e "  Gitea URL: $GITEA_URL"

# Restart runner to apply token
echo -e "\n${BLUE}[6/8] Starting/restarting Actions Runner...${NC}"

# Check if runner container exists
if docker ps -a | grep -q $RUNNER_CONTAINER; then
    echo -e "${BLUE}  Restarting existing runner...${NC}"
    docker rm -f $RUNNER_CONTAINER >/dev/null 2>&1 || true
fi

# Start with docker compose
docker compose up -d runner >/dev/null 2>&1

# Wait for runner to initialize
echo -e "${BLUE}  Waiting for runner to initialize...${NC}"
sleep 5

# Check runner logs
echo -e "\n${BLUE}[7/8] Verifying runner connection...${NC}"
RUNNER_LOGS=$(docker logs $RUNNER_CONTAINER 2>&1 | tail -20)

if echo "$RUNNER_LOGS" | grep -q "Runner registered successfully"; then
    echo -e "${GREEN}✓ Runner registered successfully!${NC}"
    RUNNER_REGISTERED=true
elif echo "$RUNNER_LOGS" | grep -q "token is empty"; then
    echo -e "${RED}✗ Runner token is empty or invalid${NC}"
    echo -e "${YELLOW}  Please check your .env file and re-run this script${NC}"
    RUNNER_REGISTERED=false
elif echo "$RUNNER_LOGS" | grep -q "401\|invalid token\|authentication failed"; then
    echo -e "${RED}✗ Runner registration failed: Invalid token${NC}"
    echo -e "${YELLOW}  The token may have expired or is incorrect${NC}"
    echo -e "${YELLOW}  Get a new token from: Site Admin → Actions → Runners${NC}"
    RUNNER_REGISTERED=false
else
    # Check if runner is actually running
    if docker logs $RUNNER_CONTAINER 2>&1 | grep -q "Runner started"; then
        echo -e "${GREEN}✓ Runner is active and connected${NC}"
        RUNNER_REGISTERED=true
    else
        echo -e "${YELLOW}⚠ Runner status unclear, check logs:${NC}"
        echo -e "${YELLOW}  docker logs $RUNNER_CONTAINER${NC}"
        RUNNER_REGISTERED="unknown"
    fi
fi

# Repository secrets guidance
echo -e "\n${BLUE}[8/8] Repository Secrets Configuration${NC}"
echo -e "${CYAN}The AI assistant requires API credentials to be configured as repository secrets.${NC}\n"

echo -e "${BLUE}Choose your authentication method:${NC}"
echo -e "  ${YELLOW}1. Anthropic API Key${NC} (recommended for organizations)"
echo -e "     - Requires: Anthropic account with API access"
echo -e "     - Setup: https://console.anthropic.com/"
echo -e "     - Secret name: ${CYAN}ANTHROPIC_API_KEY${NC}"
echo -e ""
echo -e "  ${YELLOW}2. Claude Code OAuth${NC} (recommended for Claude Max/Pro subscribers)"
echo -e "     - Requires: Claude Max or Pro subscription"
echo -e "     - Uses: Your existing Claude subscription"
echo -e "     - Secret name: ${CYAN}CLAUDE_CODE_OAUTH_TOKEN${NC}"
echo -e ""

echo -e "${CYAN}To configure repository secrets:${NC}"
echo -e "  1. Navigate to your repository in Gitea"
echo -e "  2. Go to: ${YELLOW}Settings → Secrets${NC}"
echo -e "  3. Click: ${YELLOW}Add Secret${NC}"
echo -e "  4. Add one of these secrets:"
echo -e "     ${CYAN}ANTHROPIC_API_KEY${NC} = your_api_key_here"
echo -e "        OR"
echo -e "     ${CYAN}CLAUDE_CODE_OAUTH_TOKEN${NC} = your_oauth_token_here"
echo -e "  5. Also add:"
echo -e "     ${CYAN}GITEA_SERVER_URL${NC} = $GITEA_URL"
echo -e ""

# Check if we can list repositories (requires admin access)
echo -e "${BLUE}Checking for repositories...${NC}"
REPO_COUNT=$(docker exec $CONTAINER_NAME gitea admin repo list 2>/dev/null | wc -l || echo "0")
if [ "$REPO_COUNT" -gt 1 ]; then
    echo -e "${GREEN}✓ Found repositories:${NC}"
    docker exec $CONTAINER_NAME gitea admin repo list 2>/dev/null | head -10
    if [ "$REPO_COUNT" -gt 10 ]; then
        echo -e "${YELLOW}  ... and $((REPO_COUNT - 10)) more${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No repositories found or unable to list${NC}"
fi

# Final status
echo -e "\n${GREEN}========================================${NC}"
if [ "$RUNNER_REGISTERED" = true ]; then
    echo -e "${GREEN}  ✓ AI Assistant Setup Complete!${NC}"
else
    echo -e "${YELLOW}  ⚠ Setup Partially Complete${NC}"
fi
echo -e "${GREEN}========================================${NC}\n"

# Next steps
echo -e "${BLUE}Next steps:${NC}"
if [ "$RUNNER_REGISTERED" = true ]; then
    echo -e "${GREEN}✓ Runner is configured and connected${NC}"
    echo -e "\n${YELLOW}To complete setup:${NC}"
    echo -e "  1. Configure repository secrets (see above)"
    echo -e "  2. Test the assistant by commenting in a PR/Issue:"
    echo -e "     ${CYAN}@qms-assistant Hello! Can you help me?${NC}"
    echo -e ""
else
    echo -e "  1. Fix runner registration issues (see errors above)"
    echo -e "  2. Re-run this script: ${CYAN}./setup-claude-assistant.sh${NC}"
    echo -e ""
fi

echo -e "${BLUE}Documentation:${NC}"
echo -e "  • Anthropic API: ${YELLOW}docs/ai-integration/gitea-actions-setup.md${NC}"
echo -e "  • Claude OAuth: ${YELLOW}docs/ai-integration/claude-code-oauth-setup.md${NC}"
echo -e "  • QMS Workflows: ${YELLOW}docs/ai-integration/qms-workflows.md${NC}"
echo -e ""

echo -e "${BLUE}Useful commands:${NC}"
echo -e "  • Check runner logs:  ${CYAN}docker logs $RUNNER_CONTAINER${NC}"
echo -e "  • Restart runner:     ${CYAN}docker restart $RUNNER_CONTAINER${NC}"
echo -e "  • View workflows:     ${CYAN}ls -la .gitea/workflows/${NC}"
echo -e "  • Test connection:    Open ${YELLOW}http://localhost:3001${NC}"
echo -e ""

if [ "$RUNNER_REGISTERED" = true ]; then
    echo -e "${GREEN}✓ Your AI assistant is ready to help with QMS workflows!${NC}\n"
else
    echo -e "${YELLOW}⚠ Please resolve the issues above and re-run this script${NC}\n"
fi
