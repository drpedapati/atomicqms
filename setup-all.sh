#!/bin/bash
#
# AtomicQMS Complete Setup Orchestrator
#
# This script guides you through the complete AtomicQMS setup process
# by calling individual setup scripts in the correct order.
#
# Usage: ./setup-all.sh [--minimal|--full|--clean]
#
# Options:
#   --minimal : Server + Admin user only (no AI, no GitHub OAuth)
#   --full    : Complete setup including AI assistant and organization
#   --clean   : Force clean installation (wipe all data first)
#   (default) : Interactive - asks what you want to set up
#
# Admin Password:
#   Default: atomicqms123 (automatically set, change after first login)
#   Override: export ATOMICQMS_ADMIN_PASSWORD="your-password"
#
# On repeated runs, the script will detect existing installations and
# offer to either continue or perform a clean install.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  AtomicQMS Complete Setup${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Parse arguments first to determine what to check
SETUP_MODE="interactive"
FORCE_CLEAN="false"
if [ "$1" == "--minimal" ]; then
    SETUP_MODE="minimal"
elif [ "$1" == "--full" ]; then
    SETUP_MODE="full"
elif [ "$1" == "--standard" ]; then
    SETUP_MODE="standard"
elif [ "$1" == "--clean" ]; then
    FORCE_CLEAN="true"
fi

# For interactive mode, we need to check if AI credentials exist
# to inform the user upfront what modes are available
CHECK_AI_CREDENTIALS="false"
CHECK_GITHUB_OAUTH="false"
AI_CREDENTIALS_AVAILABLE="false"  # Default to false
GITHUB_OAUTH_AVAILABLE="false"    # Default to false

if [ "$SETUP_MODE" == "interactive" ]; then
    CHECK_AI_CREDENTIALS="true"
    CHECK_GITHUB_OAUTH="true"
elif [ "$SETUP_MODE" == "standard" ] || [ "$SETUP_MODE" == "full" ]; then
    CHECK_AI_CREDENTIALS="true"
fi

# Full mode requires GitHub OAuth
if [ "$SETUP_MODE" == "full" ]; then
    CHECK_GITHUB_OAUTH="true"
fi

#============================================
# Prerequisite Checking
#============================================

echo -e "${BLUE}Checking Prerequisites...${NC}\n"

PREREQ_FAILED="false"

# Check 1: Docker installed and running
echo -n "  Docker daemon............ "
if docker info > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo -e "    ${RED}Error: Docker is not running${NC}"
    echo -e "    Please start Docker Desktop and try again"
    PREREQ_FAILED="true"
fi

# Check 2: Docker Compose available
echo -n "  Docker Compose........... "
if docker compose version > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo -e "    ${RED}Error: Docker Compose not found${NC}"
    echo -e "    Install Docker Desktop or docker-compose-plugin"
    PREREQ_FAILED="true"
fi

# Check 3: Port 3001 availability
echo -n "  Port 3001 (Gitea)........ "
if lsof -Pi :3001 -sTCP:LISTEN -t > /dev/null 2>&1; then
    # Port is in use - check if it's our container
    if docker ps --filter "name=atomicqms" --filter "status=running" --format "{{.Names}}" | grep -q "atomicqms"; then
        echo -e "${YELLOW}⚠ (already in use by AtomicQMS)${NC}"
    else
        echo -e "${RED}✗${NC}"
        echo -e "    ${RED}Error: Port 3001 is already in use by another process${NC}"
        echo -e "    ${YELLOW}Find the process: lsof -i :3001${NC}"
        PREREQ_FAILED="true"
    fi
else
    echo -e "${GREEN}✓${NC}"
fi

# Check 4: Port 222 availability (SSH)
echo -n "  Port 222 (Git SSH)....... "
if lsof -Pi :222 -sTCP:LISTEN -t > /dev/null 2>&1; then
    # Port is in use - check if it's our container
    if docker ps --filter "name=atomicqms" --filter "status=running" --format "{{.Names}}" | grep -q "atomicqms"; then
        echo -e "${YELLOW}⚠ (already in use by AtomicQMS)${NC}"
    else
        echo -e "${RED}✗${NC}"
        echo -e "    ${RED}Error: Port 222 is already in use by another process${NC}"
        echo -e "    ${YELLOW}Find the process: lsof -i :222${NC}"
        PREREQ_FAILED="true"
    fi
else
    echo -e "${GREEN}✓${NC}"
fi

# Check 5: Disk space (need at least 2GB free)
echo -n "  Disk space (min 2GB)..... "
if command -v df > /dev/null 2>&1; then
    # Get available space in KB, works on both macOS and Linux
    AVAILABLE_KB=$(df -k . | tail -1 | awk '{print $4}')
    AVAILABLE_GB=$((AVAILABLE_KB / 1024 / 1024))

    if [ "$AVAILABLE_GB" -ge 2 ]; then
        echo -e "${GREEN}✓ (${AVAILABLE_GB}GB available)${NC}"
    else
        echo -e "${RED}✗${NC}"
        echo -e "    ${RED}Error: Only ${AVAILABLE_GB}GB available (need at least 2GB)${NC}"
        PREREQ_FAILED="true"
    fi
else
    echo -e "${YELLOW}⚠ (unable to check)${NC}"
fi

# Check 6: Required files exist
echo -n "  Configuration files...... "
MISSING_FILES=""
if [ ! -f "docker-compose.yml" ]; then
    MISSING_FILES="$MISSING_FILES docker-compose.yml"
fi
if [ ! -f "gitea/gitea/conf/app.ini" ]; then
    MISSING_FILES="$MISSING_FILES gitea/gitea/conf/app.ini"
fi

if [ -z "$MISSING_FILES" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo -e "    ${RED}Error: Missing required files:${MISSING_FILES}${NC}"
    echo -e "    ${YELLOW}Are you in the correct directory?${NC}"
    PREREQ_FAILED="true"
fi

# Check 7: AI credentials (check for interactive/standard/full modes)
if [ "$CHECK_AI_CREDENTIALS" == "true" ]; then
    echo -n "  Claude AI credentials.... "
    HAS_OAUTH_TOKEN="false"
    HAS_API_KEY="false"

    # Check environment variables
    if [ -n "${CLAUDE_CODE_OAUTH_TOKEN}" ]; then
        HAS_OAUTH_TOKEN="true"
    fi
    if [ -n "${ANTHROPIC_API_KEY}" ]; then
        HAS_API_KEY="true"
    fi

    # Check .env file
    if [ -f ".env" ]; then
        if grep -q "^CLAUDE_CODE_OAUTH_TOKEN=" .env && [ -n "$(grep "^CLAUDE_CODE_OAUTH_TOKEN=" .env | cut -d'=' -f2-)" ]; then
            HAS_OAUTH_TOKEN="true"
        fi
        if grep -q "^ANTHROPIC_API_KEY=" .env && [ -n "$(grep "^ANTHROPIC_API_KEY=" .env | cut -d'=' -f2-)" ]; then
            HAS_API_KEY="true"
        fi
    fi

    if [ "$HAS_OAUTH_TOKEN" == "true" ] || [ "$HAS_API_KEY" == "true" ]; then
        echo -e "${GREEN}✓${NC}"
        AI_CREDENTIALS_AVAILABLE="true"
    else
        if [ "$SETUP_MODE" == "interactive" ]; then
            # For interactive mode, just note it - user can still choose minimal
            echo -e "${YELLOW}⚠ (not found - minimal mode only)${NC}"
            AI_CREDENTIALS_AVAILABLE="false"
        else
            # For standard/full modes, this is an error
            echo -e "${RED}✗${NC}"
            echo -e "    ${RED}Error: No Claude AI credentials found${NC}\n"
            echo -e "    ${YELLOW}To fix this, create a .env file with your credentials:${NC}\n"
            echo -e "    ${CYAN}1. Copy the example file:${NC}"
            echo -e "       ${CYAN}cp .env.example .env${NC}\n"
            echo -e "    ${CYAN}2. Edit .env and add ONE of these:${NC}"
            echo -e "       ${CYAN}CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-...${NC}  (from https://claude.ai/code)"
            echo -e "       ${CYAN}ANTHROPIC_API_KEY=sk-ant-api03-...${NC}       (from https://console.anthropic.com)\n"
            echo -e "    ${CYAN}3. Run setup again:${NC}"
            echo -e "       ${CYAN}./setup-all.sh --${SETUP_MODE}${NC}\n"
            PREREQ_FAILED="true"
        fi
    fi
fi

# Check 8: GitHub OAuth credentials (for full setup)
if [ "$CHECK_GITHUB_OAUTH" == "true" ]; then
    echo -n "  GitHub OAuth (SSO)....... "
    HAS_GITHUB_CLIENT_ID="false"
    HAS_GITHUB_CLIENT_SECRET="false"

    # Check environment variables
    if [ -n "${GITHUB_CLIENT_ID}" ]; then
        HAS_GITHUB_CLIENT_ID="true"
    fi
    if [ -n "${GITHUB_CLIENT_SECRET}" ]; then
        HAS_GITHUB_CLIENT_SECRET="true"
    fi

    # Check .env file
    if [ -f ".env" ]; then
        if grep -q "^GITHUB_CLIENT_ID=" .env && [ -n "$(grep "^GITHUB_CLIENT_ID=" .env | cut -d'=' -f2- | grep -v xxxx)" ]; then
            HAS_GITHUB_CLIENT_ID="true"
        fi
        if grep -q "^GITHUB_CLIENT_SECRET=" .env && [ -n "$(grep "^GITHUB_CLIENT_SECRET=" .env | cut -d'=' -f2- | grep -v xxxx)" ]; then
            HAS_GITHUB_CLIENT_SECRET="true"
        fi
    fi

    if [ "$HAS_GITHUB_CLIENT_ID" == "true" ] && [ "$HAS_GITHUB_CLIENT_SECRET" == "true" ]; then
        echo -e "${GREEN}✓${NC}"
        GITHUB_OAUTH_AVAILABLE="true"
    else
        if [ "$SETUP_MODE" == "interactive" ]; then
            # For interactive mode, just note it - user can choose standard instead
            echo -e "${YELLOW}⚠ (not found - SSO disabled)${NC}"
            GITHUB_OAUTH_AVAILABLE="false"
        else
            # For full mode, this is a warning but not fatal
            echo -e "${YELLOW}⚠${NC}"
            echo -e "    ${YELLOW}GitHub OAuth not configured (Single Sign-On will be disabled)${NC}"
            echo -e "    ${CYAN}To enable GitHub SSO, add to .env:${NC}"
            echo -e "       ${CYAN}GITHUB_CLIENT_ID=Iv1.xxx${NC}       (from https://github.com/settings/developers)"
            echo -e "       ${CYAN}GITHUB_CLIENT_SECRET=ghp_xxx${NC}    (OAuth App client secret)\n"
            GITHUB_OAUTH_AVAILABLE="false"
        fi
    fi
fi

# Check 9: curl available (needed for API calls)
echo -n "  curl utility............. "
if command -v curl > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo -e "    ${RED}Error: curl command not found${NC}"
    echo -e "    ${YELLOW}Install curl to continue${NC}"
    PREREQ_FAILED="true"
fi

# Summary
echo ""
if [ "$PREREQ_FAILED" == "true" ]; then
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}  Prerequisite Check Failed${NC}"
    echo -e "${RED}========================================${NC}\n"
    echo -e "${YELLOW}Please fix the errors above and try again.${NC}\n"
    exit 1
else
    echo -e "${GREEN}✓ All prerequisites met${NC}\n"
fi

# Check for existing installation
EXISTING_INSTALL="false"
if [ -d "gitea/gitea" ] && [ -f "gitea/gitea/gitea.db" ]; then
    EXISTING_INSTALL="true"
fi

# Detect if containers are already running with data
if docker compose ps | grep -q "Up"; then
    if [ "$EXISTING_INSTALL" == "true" ]; then
        echo -e "${YELLOW}⚠ Warning: Existing AtomicQMS installation detected${NC}\n"
        echo "Running setup again may cause conflicts because:"
        echo "  - Admin user might already exist in database"
        echo "  - Organization/repositories might already be created"
        echo "  - Runner might already be registered"
        echo ""
        echo -e "${CYAN}What would you like to do?${NC}"
        echo "1) Continue (skip existing steps)"
        echo "2) Clean install (wipe database and start fresh)"
        echo "3) Cancel"
        echo ""
        read -p "Choose [1-3]: " reset_choice

        case $reset_choice in
            1)
                echo -e "\n${YELLOW}Continuing with existing installation...${NC}"
                ;;
            2)
                echo -e "\n${RED}⚠ WARNING: This will delete ALL data!${NC}"
                echo "  - All repositories will be deleted"
                echo "  - All users will be deleted"
                echo "  - All issues, PRs, and comments will be deleted"
                echo "  - Configuration will be reset"
                echo ""
                read -p "Type 'DELETE' to confirm: " confirm

                if [ "$confirm" != "DELETE" ]; then
                    echo -e "${YELLOW}Cancelled${NC}"
                    exit 0
                fi

                echo -e "\n${BLUE}Performing clean installation...${NC}"
                docker compose down --volumes

                # Remove data but preserve configuration
                rm -rf gitea/git gitea/ssh runner-data
                rm -f gitea/gitea/gitea.db gitea/gitea/*.log
                rm -rf gitea/gitea/indexers gitea/gitea/sessions gitea/gitea/queues
                rm -f .env

                echo -e "${GREEN}✓ Cleaned up existing installation${NC}"
                echo -e "${CYAN}  Preserved: gitea/gitea/conf/app.ini${NC}\n"
                ;;
            3)
                echo -e "${YELLOW}Setup cancelled${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                exit 1
                ;;
        esac
    fi
fi

# Determine setup mode
if [ "$SETUP_MODE" == "interactive" ]; then
    echo -e "${CYAN}What would you like to set up?${NC}\n"

    if [ "$AI_CREDENTIALS_AVAILABLE" == "true" ]; then
        # All options available
        echo "1) Minimal    - Just AtomicQMS server (no AI assistant)"
        echo "2) Standard   - Server + AI assistant"
        echo "3) Full       - Server + AI + GitHub OAuth + Organization"
        echo ""
        read -p "Choose [1-3]: " choice

        case $choice in
            1) SETUP_MODE="minimal" ;;
            2) SETUP_MODE="standard" ;;
            3) SETUP_MODE="full" ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                exit 1
                ;;
        esac
    else
        # Only minimal mode available
        echo -e "${YELLOW}⚠ No AI credentials detected${NC}"
        echo ""
        echo "1) Minimal    - Just AtomicQMS server (no AI assistant)"
        echo ""
        echo -e "${YELLOW}Note: To enable AI features, create .env file with credentials:${NC}\n"
        echo -e "  ${CYAN}1. Copy example:${NC} cp .env.example .env"
        echo -e "  ${CYAN}2. Edit .env and add ONE of these:${NC}"
        echo -e "     CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-...  ${YELLOW}(from https://claude.ai/code)${NC}"
        echo -e "     ANTHROPIC_API_KEY=sk-ant-api03-...       ${YELLOW}(from https://console.anthropic.com)${NC}"
        echo -e "  ${CYAN}3. Run setup again${NC}\n"
        read -p "Continue with minimal setup? [y/N]: " confirm

        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            echo -e "\n${YELLOW}Setup cancelled.${NC}"
            echo -e "After creating .env with credentials, run: ${CYAN}./setup-all.sh${NC}\n"
            exit 0
        fi

        SETUP_MODE="minimal"
    fi
fi

echo -e "\n${BLUE}Setup Mode: ${SETUP_MODE}${NC}\n"

# Step 1: Start Docker Compose
echo -e "${BLUE}[Step 1/4] Starting Docker containers...${NC}"
if ! docker compose ps | grep -q "Up"; then
    docker compose up -d
    echo -e "${GREEN}✓ Containers started${NC}"
    echo "Waiting 10 seconds for Gitea to initialize..."
    sleep 10
else
    echo -e "${YELLOW}Containers already running${NC}"
fi

# Step 2: Check if admin user exists
echo -e "\n${BLUE}[Step 2/4] Checking admin user...${NC}"
if docker exec atomicqms gitea admin user list 2>/dev/null | grep -q admin; then
    echo -e "${GREEN}✓ Admin user already exists${NC}"
else
    echo -e "${YELLOW}Creating admin user...${NC}"

    # Use default password (can be overridden with environment variable)
    ADMIN_PASSWORD="${ATOMICQMS_ADMIN_PASSWORD:-atomicqms123}"

    docker exec -u git atomicqms gitea admin user create \
        --username admin \
        --password "$ADMIN_PASSWORD" \
        --email admin@atomicqms.local \
        --admin \
        --must-change-password=false

    echo -e "${GREEN}✓ Admin user created${NC}"
    echo -e "${CYAN}  Username: admin${NC}"
    echo -e "${CYAN}  Password: atomicqms123${NC}"
    echo -e "${YELLOW}  ⚠ Change password after first login!${NC}"
fi

# Step 3: AI Assistant Setup (if not minimal)
if [ "$SETUP_MODE" != "minimal" ]; then
    echo -e "\n${BLUE}[Step 3/4] Setting up AI Assistant...${NC}"

    if [ ! -f .env ] || ! grep -q "CLAUDE_CODE_OAUTH_TOKEN" .env; then
        echo -e "${YELLOW}Running AI assistant setup...${NC}\n"
        ./setup-claude-assistant.sh
    else
        echo -e "${GREEN}✓ AI assistant already configured (found .env)${NC}"
        echo -e "${YELLOW}To reconfigure, delete .env and run again${NC}"
    fi
fi

# Step 4: GitHub OAuth Setup (if full and credentials available)
if [ "$SETUP_MODE" == "full" ] && [ "$GITHUB_OAUTH_AVAILABLE" == "true" ]; then
    echo -e "\n${BLUE}[Step 4/5] Setting up GitHub OAuth (Single Sign-On)...${NC}"

    # Check if GitHub OAuth already configured
    if docker exec atomicqms gitea admin auth list 2>/dev/null | grep -q "github"; then
        echo -e "${GREEN}✓ GitHub OAuth already configured${NC}"
    else
        echo -e "${YELLOW}Configuring GitHub OAuth...${NC}\n"
        ./setup-github-oauth.sh
    fi
fi

# Step 5: Organization Setup (if full)
if [ "$SETUP_MODE" == "full" ]; then
    STEP_NUM="4"
    if [ "$GITHUB_OAUTH_AVAILABLE" == "true" ]; then
        STEP_NUM="5"
    fi
    echo -e "\n${BLUE}[Step ${STEP_NUM}/5] Setting up Organization...${NC}"

    # Check if organization exists
    if curl -s http://localhost:3001/api/v1/orgs/atomicqms-lab 2>/dev/null | grep -q '"username":"atomicqms-lab"'; then
        echo -e "${GREEN}✓ Organization 'atomicqms-lab' already exists${NC}"
    else
        echo -e "${YELLOW}Creating organization and setting up secrets...${NC}\n"
        ./setup-organization.sh
    fi
fi

# Summary
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "🌐 Access AtomicQMS: ${CYAN}http://localhost:3001${NC}"
echo -e "👤 Admin user: ${CYAN}admin${NC}"

if [ "$SETUP_MODE" != "minimal" ]; then
    echo -e "\n${BLUE}AI Assistant Status:${NC}"
    if [ -f .env ] && grep -q "CLAUDE_CODE_OAUTH_TOKEN" .env; then
        echo -e "  ${GREEN}✓ Configured and ready${NC}"
        echo -e "  📝 Test by mentioning ${CYAN}@qms-assistant${NC} in any issue"
    else
        echo -e "  ${YELLOW}⚠ Not fully configured${NC}"
        echo -e "  Run ${CYAN}./setup-claude-assistant.sh${NC} to complete setup"
    fi
fi

if [ "$SETUP_MODE" == "full" ]; then
    if [ "$GITHUB_OAUTH_AVAILABLE" == "true" ]; then
        echo -e "\n${BLUE}GitHub OAuth (SSO):${NC}"
        echo -e "  ${GREEN}✓ GitHub Single Sign-On enabled${NC}"
        echo -e "  🔐 Users can login with GitHub accounts"
    fi

    echo -e "\n${BLUE}Organization Setup:${NC}"
    echo -e "  ${GREEN}✓ atomicqms-lab organization ready${NC}"
    echo -e "  📁 Create new repos from template: ${CYAN}atomicqms-lab/atomicqms-template${NC}"
fi

echo -e "\n${YELLOW}Next Steps:${NC}"
if [ "$SETUP_MODE" == "minimal" ]; then
    echo "  1. Login at http://localhost:3001"
    echo "  2. Create your first repository"
    echo "  3. (Optional) Run ${CYAN}./setup-claude-assistant.sh${NC} to add AI assistant"
elif [ "$SETUP_MODE" == "standard" ]; then
    echo "  1. Login at http://localhost:3001"
    echo "  2. Create a repository"
    echo "  3. Create an issue and mention @qms-assistant"
    echo "  4. (Optional) Run ${CYAN}./setup-organization.sh${NC} to create atomicqms-lab org"
else
    echo "  1. Login at http://localhost:3001"
    echo "  2. Go to http://localhost:3001/atomicqms-lab"
    echo "  3. Create new repository using atomicqms-template"
    echo "  4. Mention @qms-assistant in an issue to test AI"
fi

echo -e "\n${CYAN}📖 Documentation: ./docs/${NC}"
echo -e "${CYAN}❓ Troubleshooting: See TROUBLESHOOTING.md${NC}\n"
