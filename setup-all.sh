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

# Parse arguments
SETUP_MODE="interactive"
FORCE_CLEAN="false"
if [ "$1" == "--minimal" ]; then
    SETUP_MODE="minimal"
elif [ "$1" == "--full" ]; then
    SETUP_MODE="full"
elif [ "$1" == "--clean" ]; then
    FORCE_CLEAN="true"
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running${NC}"
    echo "Please start Docker and try again"
    exit 1
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
                rm -rf gitea/git gitea/gitea gitea/ssh runner-data
                rm -f .env
                echo -e "${GREEN}✓ Cleaned up existing installation${NC}\n"
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

# Step 4: Organization Setup (if full)
if [ "$SETUP_MODE" == "full" ]; then
    echo -e "\n${BLUE}[Step 4/4] Setting up Organization...${NC}"

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
