#!/bin/bash
#
# AtomicQMS Auto-Init Service
#
# Automatically initializes new repositories with AI assistant files
# Runs periodically to check for repos missing the required files
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${SCRIPT_DIR}/templates"
REPO_ROOT="${REPO_ROOT:-/data/git/repositories}"
GIT_USER_NAME="${GIT_USER_NAME:-AtomicQMS Auto-Init}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-autoinit@atomicqms.local}"
DRY_RUN="${DRY_RUN:-false}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running inside container or host
if [ -f "/.dockerenv" ]; then
    IS_CONTAINER=true
    log_info "Running inside container"
else
    IS_CONTAINER=false
    log_info "Running on host"
fi

# Validate template directory exists
if [ ! -d "$TEMPLATE_DIR" ]; then
    log_error "Template directory not found: $TEMPLATE_DIR"
    exit 1
fi

# Required template files
REQUIRED_FILES=(
    ".gitea/workflows/claude-qms-assistant.yml"
    ".claude/qms-context.md"
)

# Validate all required templates exist
log_info "Validating template files..."
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$TEMPLATE_DIR/$file" ]; then
        log_error "Required template file missing: $file"
        exit 1
    fi
    log_success "Found template: $file"
done

# Function to check if a repository has the AI assistant files
check_repo_has_files() {
    local repo_path="$1"
    local missing_files=()

    for file in "${REQUIRED_FILES[@]}"; do
        if ! git --git-dir="$repo_path" ls-tree -r --name-only HEAD 2>/dev/null | grep -q "^${file}$"; then
            missing_files+=("$file")
        fi
    done

    if [ ${#missing_files[@]} -eq 0 ]; then
        return 0  # All files present
    else
        echo "${missing_files[@]}"
        return 1  # Files missing
    fi
}

# Function to initialize a repository with AI assistant files
init_repository() {
    local repo_path="$1"
    local repo_name="$(basename "$repo_path" .git)"
    local user_name="$(basename "$(dirname "$repo_path")")"

    log_info "Initializing repository: $user_name/$repo_name"

    # Create a temporary working directory
    local temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" EXIT

    # Clone the repository
    if ! git clone "$repo_path" "$temp_dir" >/dev/null 2>&1; then
        log_warning "Could not clone $user_name/$repo_name (may be empty)"
        rm -rf "$temp_dir"
        trap - EXIT
        return 1
    fi

    cd "$temp_dir"

    # Configure git user
    git config user.name "$GIT_USER_NAME"
    git config user.email "$GIT_USER_EMAIL"

    # Track if we made any changes
    local changes_made=false

    # Copy missing files
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$file" ]; then
            log_info "  Adding: $file"
            mkdir -p "$(dirname "$file")"
            cp "$TEMPLATE_DIR/$file" "$file"
            git add "$file"
            changes_made=true
        fi
    done

    if [ "$changes_made" = true ]; then
        if [ "$DRY_RUN" = "true" ]; then
            log_warning "  [DRY RUN] Would commit AI assistant files"
        else
            # Commit the changes
            git commit -m "Add AI assistant integration

Automatically added by AtomicQMS Auto-Init Service:
- Gitea Actions workflow for Claude AI assistant
- QMS-specific context for AI interactions

This enables @qms-assistant mentions in issues and pull requests.

🤖 Generated with AtomicQMS Auto-Init" >/dev/null 2>&1

            # Push to origin
            if git push origin "$(git branch --show-current)" >/dev/null 2>&1; then
                log_success "  ✓ Initialized $user_name/$repo_name"
            else
                log_error "  ✗ Failed to push to $user_name/$repo_name"
                cd - >/dev/null
                rm -rf "$temp_dir"
                trap - EXIT
                return 1
            fi
        fi
    else
        log_info "  Already initialized (no changes needed)"
    fi

    cd - >/dev/null
    rm -rf "$temp_dir"
    trap - EXIT
    return 0
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  AtomicQMS Auto-Init Service${NC}"
    echo -e "${BLUE}========================================${NC}\n"

    if [ "$DRY_RUN" = "true" ]; then
        log_warning "DRY RUN MODE - No changes will be made\n"
    fi

    log_info "Scanning repositories in: $REPO_ROOT\n"

    # Find all git repositories
    local repo_count=0
    local initialized_count=0
    local already_init_count=0
    local failed_count=0

    while IFS= read -r repo_path; do
        ((repo_count++))

        # Check if repo has commits
        if ! git --git-dir="$repo_path" rev-parse HEAD >/dev/null 2>&1; then
            log_info "Skipping empty repository: $(basename "$(dirname "$repo_path")")/$(basename "$repo_path" .git)"
            continue
        fi

        # Check if repo has all required files
        if check_repo_has_files "$repo_path"; then
            ((already_init_count++))
        else
            # Initialize the repository
            if init_repository "$repo_path"; then
                ((initialized_count++))
            else
                ((failed_count++))
            fi
        fi
    done < <(find "$REPO_ROOT" -type d -name "*.git" 2>/dev/null)

    # Summary
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Summary${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    echo -e "  Total repositories scanned: ${repo_count}"
    echo -e "  ${GREEN}✓${NC} Already initialized: ${already_init_count}"
    echo -e "  ${BLUE}+${NC} Newly initialized: ${initialized_count}"
    if [ $failed_count -gt 0 ]; then
        echo -e "  ${RED}✗${NC} Failed: ${failed_count}"
    fi

    if [ "$DRY_RUN" = "true" ]; then
        echo -e "\n${YELLOW}DRY RUN completed - run without DRY_RUN=true to apply changes${NC}"
    fi

    echo ""
}

# Run main function
main
