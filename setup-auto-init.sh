#!/bin/bash
#
# Setup Auto-Init Service for AtomicQMS
#
# Automatically initializes new repositories with AI assistant files
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
echo -e "${BLUE}  AtomicQMS Auto-Init Setup${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Load container names
if [ -f .env ]; then
    source .env
fi
CONTAINER_NAME="${ATOMICQMS_CONTAINER:-atomicqms}"
AUTO_INIT_CONTAINER="${ATOMICQMS_AUTO_INIT_CONTAINER:-atomicqms-auto-init}"

# Check 1: AtomicQMS running
echo -e "${BLUE}[1/5] Checking prerequisites...${NC}"
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}✗ AtomicQMS container is not running${NC}"
    echo -e "${YELLOW}  Start it with: docker compose up -d${NC}\n"
    exit 1
fi
echo -e "${GREEN}✓ AtomicQMS container is running${NC}\n"

# Check 2: Verify template files exist
echo -e "${BLUE}[2/5] Verifying template files...${NC}"
if [ ! -f "auto-init-service/templates/.gitea/workflows/claude-qms-assistant.yml" ]; then
    echo -e "${RED}✗ Workflow template file missing${NC}"
    exit 1
fi
if [ ! -f "auto-init-service/templates/.claude/qms-context.md" ]; then
    echo -e "${RED}✗ QMS context template file missing${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Template files verified${NC}\n"

# Check 3: Update .env if needed
echo -e "${BLUE}[3/5] Checking environment configuration...${NC}"
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠ No .env file found, creating from template...${NC}"
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${GREEN}✓ Created .env from template${NC}"
    else
        echo -e "${RED}✗ .env.example not found${NC}"
        exit 1
    fi
fi

# Add auto-init vars if missing
if ! grep -q "AUTO_INIT_CHECK_INTERVAL" .env; then
    echo -e "${YELLOW}⚠ Adding auto-init configuration to .env...${NC}"
    cat >> .env << 'EOF'

# Auto-Init Service Configuration
ATOMICQMS_AUTO_INIT_CONTAINER=atomicqms-auto-init
AUTO_INIT_GIT_USER_NAME=AtomicQMS Auto-Init
AUTO_INIT_GIT_USER_EMAIL=autoinit@atomicqms.local
AUTO_INIT_CHECK_INTERVAL=300
EOF
    echo -e "${GREEN}✓ Auto-init configuration added${NC}"
else
    echo -e "${GREEN}✓ Auto-init already configured in .env${NC}"
fi
echo ""

# Check 4: Build and start service
echo -e "${BLUE}[4/5] Building and starting auto-init service...${NC}"

# Check if service is already running
if docker ps | grep -q "$AUTO_INIT_CONTAINER"; then
    echo -e "${YELLOW}⚠ Auto-init service already running, restarting...${NC}"
    docker compose --profile auto-init down auto-init >/dev/null 2>&1 || true
fi

# Build and start
echo -e "${BLUE}  Building Docker image...${NC}"
if docker compose --profile auto-init build auto-init >/dev/null 2>&1; then
    echo -e "${GREEN}  ✓ Image built${NC}"
else
    echo -e "${RED}  ✗ Build failed${NC}"
    echo -e "${YELLOW}  Check logs with: docker compose logs auto-init${NC}\n"
    exit 1
fi

echo -e "${BLUE}  Starting service...${NC}"
if docker compose --profile auto-init up -d auto-init; then
    echo -e "${GREEN}  ✓ Service started${NC}\n"
else
    echo -e "${RED}  ✗ Failed to start service${NC}\n"
    exit 1
fi

# Check 5: Verify service is running
echo -e "${BLUE}[5/5] Verifying service status...${NC}"
sleep 3

if docker ps | grep -q "$AUTO_INIT_CONTAINER"; then
    echo -e "${GREEN}✓ Auto-init service is running${NC}\n"

    # Show recent logs
    echo -e "${BLUE}Recent logs:${NC}"
    docker logs --tail 20 "$AUTO_INIT_CONTAINER" 2>&1 | tail -15
else
    echo -e "${RED}✗ Service failed to start${NC}"
    echo -e "${YELLOW}  Check logs with: docker logs $AUTO_INIT_CONTAINER${NC}\n"
    exit 1
fi

# Final instructions
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ Auto-Init Service Running!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}What happens now:${NC}"
echo -e "  • Every 5 minutes, the service scans all repositories"
echo -e "  • New repositories get AI assistant files automatically"
echo -e "  • Existing repositories with files are left unchanged"
echo -e "  • All operations are logged\n"

echo -e "${BLUE}Files automatically added to new repos:${NC}"
echo -e "  ${CYAN}.gitea/workflows/claude-qms-assistant.yml${NC} - AI assistant workflow"
echo -e "  ${CYAN}.claude/qms-context.md${NC} - QMS-specific context\n"

echo -e "${BLUE}Useful commands:${NC}"
echo -e "  • View logs:         ${CYAN}docker logs $AUTO_INIT_CONTAINER${NC}"
echo -e "  • Follow logs:       ${CYAN}docker logs -f $AUTO_INIT_CONTAINER${NC}"
echo -e "  • Restart service:   ${CYAN}docker compose --profile auto-init restart auto-init${NC}"
echo -e "  • Stop service:      ${CYAN}docker compose --profile auto-init down auto-init${NC}"
echo -e "  • Manual trigger:    ${CYAN}docker compose --profile auto-init exec auto-init /app/auto-init.sh${NC}\n"

echo -e "${BLUE}Configuration:${NC}"
echo -e "  • Check interval: ${CYAN}$(grep AUTO_INIT_CHECK_INTERVAL .env | cut -d'=' -f2) seconds${NC}"
echo -e "  • Customize in .env file\n"

echo -e "${YELLOW}Test it:${NC}"
echo -e "  1. Create a new repository in Gitea"
echo -e "  2. Push some initial content"
echo -e "  3. Wait up to 5 minutes (or trigger manually)"
echo -e "  4. Check repository - AI assistant files will be added!\n"
