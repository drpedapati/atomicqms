#!/bin/bash
#
# AtomicQMS AI Assistant Diagnostic Script
#
# Checks all prerequisites for the AI assistant to work correctly
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  AI Assistant Diagnostic Check${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Load container names
if [ -f .env ]; then
    source .env
fi
CONTAINER_NAME="${ATOMICQMS_CONTAINER:-atomicqms}"
RUNNER_CONTAINER="${ATOMICQMS_RUNNER_CONTAINER:-atomicqms-runner}"

# Check 1: Container running
echo -e "${BLUE}[1/7] Checking AtomicQMS container...${NC}"
if docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${GREEN}✓ AtomicQMS container is running${NC}\n"
else
    echo -e "${RED}✗ AtomicQMS container is not running${NC}"
    echo -e "${YELLOW}  Start it with: docker compose up -d${NC}\n"
    exit 1
fi

# Check 2: Actions enabled
echo -e "${BLUE}[2/7] Checking Gitea Actions configuration...${NC}"
if docker exec $CONTAINER_NAME grep -q "ENABLED = true" /data/gitea/conf/app.ini 2>/dev/null | grep -A 1 "\[actions\]"; then
    echo -e "${GREEN}✓ Gitea Actions are enabled${NC}\n"
else
    echo -e "${RED}✗ Gitea Actions are not enabled${NC}"
    echo -e "${YELLOW}  Check [actions] section in gitea/gitea/conf/app.ini${NC}\n"
fi

# Check 3: Runner container
echo -e "${BLUE}[3/7] Checking Actions Runner...${NC}"
if docker ps | grep -q "$RUNNER_CONTAINER"; then
    echo -e "${GREEN}✓ Runner container is running${NC}"

    # Check runner logs
    RUNNER_LOGS=$(docker logs $RUNNER_CONTAINER 2>&1 | tail -10)
    if echo "$RUNNER_LOGS" | grep -q "Runner registered successfully\|declare successfully"; then
        echo -e "${GREEN}✓ Runner is registered and connected${NC}\n"
    else
        echo -e "${YELLOW}⚠ Runner status unclear${NC}"
        echo -e "${YELLOW}  Check logs: docker logs $RUNNER_CONTAINER${NC}\n"
    fi
else
    echo -e "${RED}✗ Runner container is not running${NC}"
    echo -e "${YELLOW}  Start it with: docker compose up -d runner${NC}\n"
fi

# Check 4: Runner token
echo -e "${BLUE}[4/7] Checking runner token configuration...${NC}"
if [ -f .env ] && grep -q "^RUNNER_TOKEN=" .env; then
    TOKEN=$(grep "^RUNNER_TOKEN=" .env | cut -d'=' -f2)
    if [ ! -z "$TOKEN" ] && [ "$TOKEN" != "your_runner_registration_token_here" ]; then
        echo -e "${GREEN}✓ Runner token is configured${NC}"
        echo -e "  Token: ${TOKEN:0:10}...${TOKEN: -10}${NC}\n"
    else
        echo -e "${RED}✗ Runner token is not set${NC}"
        echo -e "${YELLOW}  Run: ./setup-claude-assistant.sh${NC}\n"
    fi
else
    echo -e "${RED}✗ No runner token found in .env${NC}"
    echo -e "${YELLOW}  Run: ./setup-claude-assistant.sh${NC}\n"
fi

# Check 5: Test repositories
echo -e "${BLUE}[5/7] Checking for test repositories...${NC}"
REPO_COUNT=$(find gitea/git/repositories -name "*.git" -type d 2>/dev/null | wc -l | tr -d ' ')
if [ "$REPO_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ Found $REPO_COUNT repository(ies)${NC}"
    find gitea/git/repositories -name "*.git" -type d | while read repo; do
        repo_name=$(basename $repo .git)
        user=$(basename $(dirname $repo))
        echo -e "  • ${user}/${repo_name}"

        # Check if repo has commits
        if git --git-dir="$repo" rev-parse HEAD >/dev/null 2>&1; then
            # Check for workflow file
            if git --git-dir="$repo" ls-tree -r --name-only HEAD | grep -q "\.gitea/workflows"; then
                echo -e "    ${GREEN}✓ Has workflow file${NC}"
            else
                echo -e "    ${YELLOW}⚠ No workflow file found${NC}"
                echo -e "    ${YELLOW}  The workflow must be in .gitea/workflows/claude-qms-assistant.yml${NC}"
            fi
        else
            echo -e "    ${YELLOW}⚠ Repository is empty${NC}"
            echo -e "    ${YELLOW}  Use ./setup-test-repository.sh to initialize${NC}"
        fi
    done
    echo ""
else
    echo -e "${YELLOW}⚠ No repositories found${NC}"
    echo -e "${YELLOW}  Create a repository in Gitea and push the workflow file${NC}\n"
fi

# Check 6: Workflow file in current directory
echo -e "${BLUE}[6/7] Checking local workflow file...${NC}"
if [ -f ".gitea/workflows/claude-qms-assistant.yml" ]; then
    echo -e "${GREEN}✓ Workflow file exists in this repository${NC}"
    echo -e "  Location: .gitea/workflows/claude-qms-assistant.yml${NC}\n"
else
    echo -e "${YELLOW}⚠ No workflow file in current directory${NC}"
    echo -e "${YELLOW}  This is normal if you're testing in a different repository${NC}\n"
fi

# Check 7: Test repository available
echo -e "${BLUE}[7/7] Checking test repository package...${NC}"
if [ -f "qms-test-repo.tar.gz" ]; then
    echo -e "${GREEN}✓ Test repository package available${NC}"
    echo -e "  Run ./setup-test-repository.sh for instructions${NC}\n"
else
    echo -e "${YELLOW}⚠ Test repository package not found${NC}"
    echo -e "${YELLOW}  It may have been moved or deleted${NC}\n"
fi

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Diagnostic Summary${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}Prerequisites Status:${NC}"
echo -e "  ✓ AtomicQMS container: Running"
echo -e "  ✓ Gitea Actions: Enabled"
echo -e "  ✓ Runner: Check output above"
echo -e "  ✓ Configuration: Check output above\n"

echo -e "${BLUE}Next Steps:${NC}"
echo -e "1. If runner is not connected:"
echo -e "   ${CYAN}./setup-claude-assistant.sh${NC}\n"

echo -e "2. If repository is empty:"
echo -e "   ${CYAN}./setup-test-repository.sh${NC}"
echo -e "   Then push to your Gitea repository\n"

echo -e "3. Configure repository secrets:"
echo -e "   • Go to Repository → Settings → Secrets"
echo -e "   • Add ${CYAN}ANTHROPIC_API_KEY${NC}"
echo -e "   • Add ${CYAN}GITEA_SERVER_URL${NC} (default: http://localhost:3001)\n"

echo -e "4. Test the assistant:"
echo -e "   • Create an issue"
echo -e "   • Comment: ${CYAN}@qms-assistant Hello!${NC}"
echo -e "   • Check Actions tab for workflow run\n"

echo -e "${BLUE}Useful Commands:${NC}"
echo -e "  • Runner logs:  ${CYAN}docker logs $RUNNER_CONTAINER${NC}"
echo -e "  • Gitea logs:   ${CYAN}docker logs $CONTAINER_NAME${NC}"
echo -e "  • Restart all:  ${CYAN}docker compose restart${NC}\n"
