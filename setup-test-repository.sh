#!/bin/bash
#
# Setup Test Repository for AtomicQMS AI Assistant
#
# This script helps you push the test repository to Gitea
# and configure the required secrets.
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
echo -e "${BLUE}  Test Repository Setup${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check if test repo exists
if [ ! -d "/tmp/qms-test-repo" ]; then
    echo -e "${BLUE}Extracting test repository...${NC}"
    cd /tmp
    tar -xzf /Users/ernie/Documents/Sandbox/atomicqms-claude-integration/qms-test-repo.tar.gz
    echo -e "${GREEN}✓ Test repository extracted to /tmp/qms-test-repo${NC}\n"
fi

echo -e "${BLUE}Repository Contents:${NC}"
echo -e "  ${CYAN}.gitea/workflows/claude-qms-assistant.yml${NC} - AI assistant workflow"
echo -e "  ${CYAN}.claude/qms-context.md${NC} - QMS-specific context"
echo -e "  ${CYAN}docs/sops/SOP-001-sample-processing.md${NC} - Sample SOP for testing"
echo -e "  ${CYAN}README.md${NC} - Repository documentation\n"

echo -e "${YELLOW}To push this repository to Gitea:${NC}\n"

echo -e "${BLUE}Option 1: Push via Git (Recommended)${NC}"
echo -e "1. Navigate to the test repository:"
echo -e "   ${CYAN}cd /tmp/qms-test-repo${NC}"
echo -e ""
echo -e "2. Add your Gitea repository as remote:"
echo -e "   ${CYAN}git remote remove origin 2>/dev/null || true${NC}"
echo -e "   ${CYAN}git remote add origin http://localhost:3001/YOUR_USERNAME/YOUR_REPO.git${NC}"
echo -e ""
echo -e "3. Push to Gitea:"
echo -e "   ${CYAN}git push -u origin main${NC}"
echo -e "   (You'll be prompted for your Gitea username and password)\n"

echo -e "${BLUE}Option 2: Upload via Web Interface${NC}"
echo -e "1. Create a new repository in Gitea"
echo -e "2. Initialize with README"
echo -e "3. Upload files through the web UI\n"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Next: Configure Repository Secrets${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "After pushing the repository, configure these secrets:"
echo -e "${CYAN}Repository Settings → Secrets → Add Secret${NC}\n"

echo -e "Required secrets:"
echo -e "  ${YELLOW}ANTHROPIC_API_KEY${NC}"
echo -e "    Your Claude API key from https://console.anthropic.com/"
echo -e "    Format: sk-ant-api03-...\n"

echo -e "  ${YELLOW}GITEA_SERVER_URL${NC}"
echo -e "    Your AtomicQMS URL (default: http://localhost:3001)\n"

echo -e "Optional (if using Claude Code OAuth instead):"
echo -e "  ${YELLOW}CLAUDE_CODE_OAUTH_TOKEN${NC}"
echo -e "    Your Claude Code OAuth token\n"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Test the AI Assistant${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "1. Create an issue in your repository"
echo -e "2. Add a comment:"
echo -e "   ${CYAN}@qms-assistant Please review the sample SOP for compliance${NC}"
echo -e "3. Check the Actions tab to see the workflow running"
echo -e "4. The AI assistant will respond with a comment\n"

echo -e "${BLUE}Troubleshooting:${NC}"
echo -e "  • Check runner status: ${CYAN}docker logs atomicqms-runner${NC}"
echo -e "  • View workflow runs: Repository → Actions tab"
echo -e "  • Verify secrets: Repository → Settings → Secrets\n"
