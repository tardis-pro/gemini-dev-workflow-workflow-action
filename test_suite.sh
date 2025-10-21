#!/usr/bin/env bash
# Navratna DevFlow Test Suite
# Tests the functionality of the Navratna DevFlow orchestrator

set -euo pipefail

# Default configuration
TEST_REPO="${TEST_REPO:-test-user/navratna-test-repo}"
GEMINI_API_KEY="${GEMINI_API_KEY:-}"
TEST_BRANCH="${TEST_BRANCH:-devflow-test}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
PASSED=0
FAILED=0
SKIPPED=0

# Temporary directory for tests
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED++))
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
    ((SKIPPED++))
}

# Test runner
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo -e "\n${BLUE}Running test: $test_name${NC}"
    echo "----------------------------------------"
    
    if $test_function; then
        log_success "$test_name"
    else
        log_error "$test_name"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if [ -z "$GEMINI_API_KEY" ]; then
        log_error "GEMINI_API_KEY environment variable must be set"
        return 1
    fi
    
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed"
        return 1
    fi
    
    if ! gh auth status &> /dev/null; then
        log_error "Not authenticated with GitHub CLI"
        return 1
    fi
    
    log_success "All prerequisites met"
    return 0
}

# Test 1: Bootstrap Script Validation
test_bootstrap_script() {
    log_info "Testing bootstrap script functionality..."
    
    # Create a test repo
    if ! gh repo create "$TEST_REPO" --private --confirm 2>/dev/null; then
        log_info "Repository already exists, proceeding with existing repo"
    fi
    
    # Run bootstrap script
    if ./scripts/bootstrap.sh "$TEST_REPO"; then
        log_info "Bootstrap completed successfully"
    else
        log_error "Bootstrap script failed"
        return 1
    fi
    
    # Check if labels were created
    local labels_output
    labels_output=$(gh label list --repo "$TEST_REPO" --json name 2>/dev/null || true)
    
    if echo "$labels_output" | grep -q "status:inception"; then
        log_success "Inception label created"
    else
        log_error "Inception label not found"
        return 1
    fi
    
    if echo "$labels_output" | grep -q "status:review"; then
        log_success "Review label created"
    else
        log_error "Review label not found"
        return 1
    fi
    
    # Check if workflow file exists
    if gh repo clone "$TEST_REPO" "$TEST_DIR/repo" -- --depth=1 2>/dev/null; then
        if [ -f "$TEST_DIR/repo/.github/workflows/devflow.yml" ]; then
            log_success "DevFlow workflow file exists"
        else
            log_error "DevFlow workflow file not found"
            return 1
        fi
    else
        log_error "Could not clone test repository to check workflow file"
        return 1
    fi
    
    return 0
}

# Test 2: Add GEMINI_API_KEY secret
setup_github_secret() {
    log_info "Setting up GEMINI_API_KEY secret in test repository..."
    
    if echo "$GEMINI_API_KEY" | gh secret set GEMINI_API_KEY --repo "$TEST_REPO"; then
        log_success "GEMINI_API_KEY secret set successfully"
        return 0
    else
        log_error "Failed to set GEMINI_API_KEY secret"
        return 1
    fi
}

# Test 3: Inception State - Design Document Generation
test_inception_state() {
    log_info "Testing inception state (design document generation)..."
    
    # Create an issue for testing
    local issue_number
    issue_number=$(gh issue create --repo "$TEST_REPO" \
        --title "Test Issue for Inception" \
        --body "Testing the inception state of Navratna DevFlow. This issue should generate a design document." \
        --label "status:inception,feature" \
        --json number --jq '.number' 2>/dev/null || echo "0")
    
    if [ "$issue_number" -eq 0 ]; then
        log_error "Failed to create test issue for inception"
        return 1
    fi
    
    log_info "Created issue #$issue_number for inception test"
    
    # Wait for workflow to complete (with timeout)
    local timeout=300  # 5 minutes
    local count=0
    local workflow_completed=false
    
    while [ $count -lt $timeout ]; do
        sleep 5
        count=$((count + 5))
        
        # Check for recent workflow runs
        local runs
        runs=$(gh run list --repo "$TEST_REPO" --workflow="DevFlow" --json status,conclusion,createdAt --jq '.[0]' 2>/dev/null || echo "{}")
        
        local status
        local conclusion
        status=$(echo "$runs" | jq -r '.status // "none"')
        conclusion=$(echo "$runs" | jq -r '.conclusion // "none"')
        
        if [ "$status" = "completed" ] && [ "$conclusion" = "success" ]; then
            workflow_completed=true
            break
        fi
    done
    
    if [ "$workflow_completed" = true ]; then
        log_success "Workflow completed successfully"
    else
        log_error "Workflow did not complete within timeout period"
        return 1
    fi
    
    # Check if design file was created
    sleep 10  # Additional delay for the commit to propagate
    
    if gh repo clone "$TEST_REPO" "$TEST_DIR/inception_check" -- --depth=1 2>/dev/null; then
        if [ -f "$TEST_DIR/inception_check/ops/out/design-$issue_number.md" ]; then
            log_success "Design document ops/out/design-$issue_number.md was created"
            
            local content_size
            content_size=$(stat -c%s "$TEST_DIR/inception_check/ops/out/design-$issue_number.md" 2>/dev/null || echo "0")
            if [ "$content_size" -gt 100 ]; then
                log_success "Design document has content (size: ${content_size} bytes)"
            else
                log_error "Design document is too small or empty"
                return 1
            fi
        else
            log_error "Design document ops/out/design-$issue_number.md was not created"
            return 1
        fi
    else
        log_error "Could not clone repository to check for design document"
        return 1
    fi
    
    return 0
}

# Test 4: Discussion State - Design Revision
test_discussion_state() {
    log_info "Testing discussion state (design revision)..."
    
    # Create an issue for testing
    local issue_number
    issue_number=$(gh issue create --repo "$TEST_REPO" \
        --title "Test Issue for Discussion" \
        --body "Testing the discussion state of Navratna DevFlow. This issue should generate a revised design document." \
        --label "status:discussion,feature" \
        --json number --jq '.number' 2>/dev/null || echo "0")
    
    if [ "$issue_number" -eq 0 ]; then
        log_error "Failed to create test issue for discussion"
        return 1
    fi
    
    log_info "Created issue #$issue_number for discussion test"
    
    # Wait for workflow to complete (with timeout)
    local timeout=300  # 5 minutes
    local count=0
    local workflow_completed=false
    
    while [ $count -lt $timeout ]; do
        sleep 5
        count=$((count + 5))
        
        # Check for recent workflow runs
        local runs
        runs=$(gh run list --repo "$TEST_REPO" --workflow="DevFlow" --json status,conclusion,createdAt --jq '.[0]' 2>/dev/null || echo "{}")
        
        local status
        local conclusion
        status=$(echo "$runs" | jq -r '.status // "none"')
        conclusion=$(echo "$runs" | jq -r '.conclusion // "none"')
        
        if [ "$status" = "completed" ] && [ "$conclusion" = "success" ]; then
            workflow_completed=true
            break
        fi
    done
    
    if [ "$workflow_completed" = true ]; then
        log_success "Workflow completed successfully"
    else
        log_error "Workflow did not complete within timeout period"
        return 1
    fi
    
    # Check if revised design file was created
    sleep 10  # Additional delay for the commit to propagate
    
    if gh repo clone "$TEST_REPO" "$TEST_DIR/discussion_check" -- --depth=1 2>/dev/null; then
        if [ -f "$TEST_DIR/discussion_check/ops/out/design-$issue_number-revised.md" ]; then
            log_success "Revised design document ops/out/design-$issue_number-revised.md was created"
            
            local content_size
            content_size=$(stat -c%s "$TEST_DIR/discussion_check/ops/out/design-$issue_number-revised.md" 2>/dev/null || echo "0")
            if [ "$content_size" -gt 100 ]; then
                log_success "Revised design document has content (size: ${content_size} bytes)"
            else
                log_error "Revised design document is too small or empty"
                return 1
            fi
        else
            log_error "Revised design document ops/out/design-$issue_number-revised.md was not created"
            return 1
        fi
    else
        log_error "Could not clone repository to check for revised design document"
        return 1
    fi
    
    return 0
}

# Test 5: Build State - Implementation Plan
test_build_state() {
    log_info "Testing build state (implementation plan)..."
    
    # Create an issue for testing
    local issue_number
    issue_number=$(gh issue create --repo "$TEST_REPO" \
        --title "Test Issue for Build" \
        --body "Testing the build state of Navratna DevFlow. This issue should generate an implementation plan." \
        --label "status:build,feature" \
        --json number --jq '.number' 2>/dev/null || echo "0")
    
    if [ "$issue_number" -eq 0 ]; then
        log_error "Failed to create test issue for build"
        return 1
    fi
    
    log_info "Created issue #$issue_number for build test"
    
    # Wait for workflow to complete (with timeout)
    local timeout=300  # 5 minutes
    local count=0
    local workflow_completed=false
    
    while [ $count -lt $timeout ]; do
        sleep 5
        count=$((count + 5))
        
        # Check for recent workflow runs
        local runs
        runs=$(gh run list --repo "$TEST_REPO" --workflow="DevFlow" --json status,conclusion,createdAt --jq '.[0]' 2>/dev/null || echo "{}")
        
        local status
        local conclusion
        status=$(echo "$runs" | jq -r '.status // "none"')
        conclusion=$(echo "$runs" | jq -r '.conclusion // "none"')
        
        if [ "$status" = "completed" ] && [ "$conclusion" = "success" ]; then
            workflow_completed=true
            break
        fi
    done
    
    if [ "$workflow_completed" = true ]; then
        log_success "Workflow completed successfully"
    else
        log_error "Workflow did not complete within timeout period"
        return 1
    fi
    
    # Check if implementation plan file was created
    sleep 10  # Additional delay for the commit to propagate
    
    if gh repo clone "$TEST_REPO" "$TEST_DIR/build_check" -- --depth=1 2>/dev/null; then
        if [ -f "$TEST_DIR/build_check/ops/out/impl-plan-$issue_number.md" ]; then
            log_success "Implementation plan ops/out/impl-plan-$issue_number.md was created"
            
            local content_size
            content_size=$(stat -c%s "$TEST_DIR/build_check/ops/out/impl-plan-$issue_number.md" 2>/dev/null || echo "0")
            if [ "$content_size" -gt 100 ]; then
                log_success "Implementation plan has content (size: ${content_size} bytes)"
            else
                log_error "Implementation plan is too small or empty"
                return 1
            fi
        else
            log_error "Implementation plan ops/out/impl-plan-$issue_number.md was not created"
            return 1
        fi
    else
        log_error "Could not clone repository to check for implementation plan"
        return 1
    fi
    
    return 0
}

# Test 6: Review State - Review Comments
test_review_state() {
    log_info "Testing review state (review comments)..."
    
    # Create an issue for testing
    local issue_number
    issue_number=$(gh issue create --repo "$TEST_REPO" \
        --title "Test Issue for Review" \
        --body "Testing the review state of Navratna DevFlow. This issue should generate review comments." \
        --label "status:review,feature" \
        --json number --jq '.number' 2>/dev/null || echo "0")
    
    if [ "$issue_number" -eq 0 ]; then
        log_error "Failed to create test issue for review"
        return 1
    fi
    
    log_info "Created issue #$issue_number for review test"
    
    # Wait for workflow to complete (with timeout)
    local timeout=300  # 5 minutes
    local count=0
    local workflow_completed=false
    
    while [ $count -lt $timeout ]; do
        sleep 5
        count=$((count + 5))
        
        # Check for recent workflow runs
        local runs
        runs=$(gh run list --repo "$TEST_REPO" --workflow="DevFlow" --json status,conclusion,createdAt --jq '.[0]' 2>/dev/null || echo "{}")
        
        local status
        local conclusion
        status=$(echo "$runs" | jq -r '.status // "none"')
        conclusion=$(echo "$runs" | jq -r '.conclusion // "none"')
        
        if [ "$status" = "completed" ] && [ "$conclusion" = "success" ]; then
            workflow_completed=true
            break
        fi
    done
    
    if [ "$workflow_completed" = true ]; then
        log_success "Workflow completed successfully"
    else
        log_error "Workflow did not complete within timeout period"
        return 1
    fi
    
    # Check if review file was created
    sleep 10  # Additional delay for the commit to propagate
    
    if gh repo clone "$TEST_REPO" "$TEST_DIR/review_check" -- --depth=1 2>/dev/null; then
        if [ -f "$TEST_DIR/review_check/ops/out/review-$issue_number.md" ]; then
            log_success "Review document ops/out/review-$issue_number.md was created"
            
            local content_size
            content_size=$(stat -c%s "$TEST_DIR/review_check/ops/out/review-$issue_number.md" 2>/dev/null || echo "0")
            if [ "$content_size" -gt 50 ]; then
                log_success "Review document has content (size: ${content_size} bytes)"
            else
                log_error "Review document is too small or empty"
                return 1
            fi
        else
            log_error "Review document ops/out/review-$issue_number.md was not created"
            return 1
        fi
    else
        log_error "Could not clone repository to check for review document"
        return 1
    fi
    
    return 0
}

# Test 7: Done State - Release Notes
test_done_state() {
    log_info "Testing done state (release notes)..."
    
    # Create an issue for testing
    local issue_number
    issue_number=$(gh issue create --repo "$TEST_REPO" \
        --title "Test Issue for Done" \
        --body "Testing the done state of Navratna DevFlow. This issue should generate release notes." \
        --label "status:done,feature" \
        --json number --jq '.number' 2>/dev/null || echo "0")
    
    if [ "$issue_number" -eq 0 ]; then
        log_error "Failed to create test issue for done"
        return 1
    fi
    
    log_info "Created issue #$issue_number for done test"
    
    # Wait for workflow to complete (with timeout)
    local timeout=300  # 5 minutes
    local count=0
    local workflow_completed=false
    
    while [ $count -lt $timeout ]; do
        sleep 5
        count=$((count + 5))
        
        # Check for recent workflow runs
        local runs
        runs=$(gh run list --repo "$TEST_REPO" --workflow="DevFlow" --json status,conclusion,createdAt --jq '.[0]' 2>/dev/null || echo "{}")
        
        local status
        local conclusion
        status=$(echo "$runs" | jq -r '.status // "none"')
        conclusion=$(echo "$runs" | jq -r '.conclusion // "none"')
        
        if [ "$status" = "completed" ] && [ "$conclusion" = "success" ]; then
            workflow_completed=true
            break
        fi
    done
    
    if [ "$workflow_completed" = true ]; then
        log_success "Workflow completed successfully"
    else
        log_error "Workflow did not complete within timeout period"
        return 1
    fi
    
    # Check if release notes file was created
    sleep 10  # Additional delay for the commit to propagate
    
    if gh repo clone "$TEST_REPO" "$TEST_DIR/done_check" -- --depth=1 2>/dev/null; then
        if [ -f "$TEST_DIR/done_check/ops/out/release-notes-$issue_number.md" ]; then
            log_success "Release notes ops/out/release-notes-$issue_number.md was created"
            
            local content_size
            content_size=$(stat -c%s "$TEST_DIR/done_check/ops/out/release-notes-$issue_number.md" 2>/dev/null || echo "0")
            if [ "$content_size" -gt 50 ]; then
                log_success "Release notes have content (size: ${content_size} bytes)"
            else
                log_error "Release notes are too small or empty"
                return 1
            fi
        else
            log_error "Release notes ops/out/release-notes-$issue_number.md was not created"
            return 1
        fi
    else
        log_error "Could not clone repository to check for release notes"
        return 1
    fi
    
    return 0
}

# Test 8: Error Handling - Missing Secret
test_missing_secret_error() {
    log_info "Testing error handling with missing GEMINI_API_KEY..."
    
    # Create a temporary test repo without the secret
    local temp_repo="test-user/temp-${TEST_REPO##*/}-error"
    
    if ! gh repo create "$temp_repo" --private --confirm 2>/dev/null; then
        log_info "Temporary error test repo already exists"
    fi
    
    # Set up the workflow without the secret
    if ! ./scripts/bootstrap.sh "$temp_repo"; then
        log_error "Bootstrap script failed for error test repo"
        gh repo delete "$temp_repo" --confirm 2>/dev/null || true
        return 1
    fi
    
    # Create an issue that will fail due to missing API key
    local issue_number
    issue_number=$(gh issue create --repo "$temp_repo" \
        --title "Test Issue for Error Handling" \
        --body "Testing error handling in Navratna DevFlow when API key is missing." \
        --label "status:inception,feature" \
        --json number --jq '.number' 2>/dev/null || echo "0")
    
    if [ "$issue_number" -eq 0 ]; then
        gh repo delete "$temp_repo" --confirm 2>/dev/null || true
        log_error "Failed to create test issue for error handling"
        return 1
    fi
    
    log_info "Created issue #$issue_number for error handling test"
    
    # Wait for workflow to fail (with timeout)
    local timeout=180  # 3 minutes
    local count=0
    local workflow_failed=false
    
    while [ $count -lt $timeout ]; do
        sleep 5
        count=$((count + 5))
        
        # Check for recent workflow runs
        local runs
        runs=$(gh run list --repo "$temp_repo" --workflow="DevFlow" --json status,conclusion --jq '.[0]' 2>/dev/null || echo "{}")
        
        local status
        local conclusion
        status=$(echo "$runs" | jq -r '.status // "none"')
        conclusion=$(echo "$runs" | jq -r '.conclusion // "none"')
        
        if [ "$status" = "completed" ] && [ "$conclusion" = "failure" ]; then
            workflow_failed=true
            break
        fi
    done
    
    if [ "$workflow_failed" = true ]; then
        log_success "Workflow failed as expected (missing API key)"
    else
        log_error "Workflow did not fail as expected"
        gh repo delete "$temp_repo" --confirm 2>/dev/null || true
        return 1
    fi
    
    # Clean up
    gh repo delete "$temp_repo" --confirm 2>/dev/null || true
    
    return 0
}

# Test 9: Custom Prompt Template
test_custom_prompt() {
    log_info "Testing custom prompt template functionality..."
    
    # Clone the test repo and add a custom prompt
    if ! gh repo clone "$TEST_REPO" "$TEST_DIR/custom_prompt_test" -- --depth=1 2>/dev/null; then
        log_error "Could not clone test repository for custom prompt test"
        return 1
    fi
    
    # Create custom prompt directory and file
    mkdir -p "$TEST_DIR/custom_prompt_test/ops/prompts"
    cat > "$TEST_DIR/custom_prompt_test/ops/prompts/custom_orchestrator.md" << 'EOF'
# Custom Orchestrator Prompt

You are a custom orchestrator for testing purposes.

## Context Variables
PROJECT_STATUS: ${PROJECT_STATUS}
ISSUE_NUMBER: ${ISSUE_NUMBER}
ISSUE_TITLE: ${ISSUE_TITLE}

## Current State
Status: ${PROJECT_STATUS}
Issue: #${ISSUE_NUMBER} - ${ISSUE_TITLE}

## Output
Generate a simple test output for status: ${PROJECT_STATUS}

## Output Format
Save this output to: ops/out/custom-${PROJECT_STATUS}-${SLUG}.md
EOF
    
    # Commit the custom prompt
    pushd "$TEST_DIR/custom_prompt_test" >/dev/null
    git add .
    git config user.name "test-bot"
    git config user.email "test-bot@users.noreply.github.com"
    git commit -m "chore: add custom prompt template for testing"
    git push origin main
    popd >/dev/null
    
    # Create an issue that will use the custom prompt
    local issue_number
    issue_number=$(gh issue create --repo "$TEST_REPO" \
        --title "Test Issue for Custom Prompt" \
        --body "Testing custom prompt functionality in Navratna DevFlow." \
        --label "status:inception,feature" \
        --json number --jq '.number' 2>/dev/null || echo "0")
    
    if [ "$issue_number" -eq 0 ]; then
        log_error "Failed to create test issue for custom prompt"
        return 1
    fi
    
    log_info "Created issue #$issue_number for custom prompt test"
    
    # Wait for workflow to complete (with timeout)
    local timeout=300  # 5 minutes
    local count=0
    local workflow_completed=false
    
    while [ $count -lt $timeout ]; do
        sleep 5
        count=$((count + 5))
        
        # Check for recent workflow runs
        local runs
        runs=$(gh run list --repo "$TEST_REPO" --workflow="DevFlow" --json status,conclusion,createdAt --jq '.[0]' 2>/dev/null || echo "{}")
        
        local status
        local conclusion
        status=$(echo "$runs" | jq -r '.status // "none"')
        conclusion=$(echo "$runs" | jq -r '.conclusion // "none"')
        
        if [ "$status" = "completed" ] && [ "$conclusion" = "success" ]; then
            workflow_completed=true
            break
        fi
    done
    
    if [ "$workflow_completed" = true ]; then
        log_success "Workflow completed successfully with custom prompt"
    else
        log_error "Workflow did not complete within timeout period"
        return 1
    fi
    
    return 0
}

# Main test execution function
run_all_tests() {
    log_info "Starting Navratna DevFlow Test Suite"
    log_info "Test repository: $TEST_REPO"
    log_info "Starting tests at: $(date)"
    echo
    
    # Check prerequisites first
    if ! check_prerequisites; then
        log_error "Prerequisites check failed. Exiting."
        exit 1
    fi
    
    # Run tests
    run_test "Bootstrap Script Validation" test_bootstrap_script
    run_test "GitHub Secret Setup" setup_github_secret
    run_test "Inception State - Design Document Generation" test_inception_state
    run_test "Discussion State - Design Revision" test_discussion_state
    run_test "Build State - Implementation Plan" test_build_state
    run_test "Review State - Review Comments" test_review_state
    run_test "Done State - Release Notes" test_done_state
    run_test "Error Handling - Missing Secret" test_missing_secret_error
    run_test "Custom Prompt Template" test_custom_prompt
    
    # Print summary
    echo
    echo "========================================="
    echo "TEST SUITE COMPLETED"
    echo "========================================="
    echo "PASSED: $PASSED"
    echo "FAILED: $FAILED"
    echo "SKIPPED: $SKIPPED"
    echo "========================================="
    
    if [ $FAILED -eq 0 ]; then
        log_success "All tests passed!"
        return 0
    else
        log_error "Some tests failed!"
        return 1
    fi
}

# Cleanup function
cleanup_test_repo() {
    log_info "Cleaning up test repository: $TEST_REPO"
    if ! gh repo delete "$TEST_REPO" --confirm 2>/dev/null; then
        log_info "Test repository may not exist or could not be deleted"
    fi
}

# Help function
show_help() {
    cat << EOF
Navratna DevFlow Test Suite

This test suite validates the functionality of the Navratna DevFlow orchestrator.

Usage: $0 [OPTIONS]

Environment Variables:
  GEMINI_API_KEY    Required: Your Gemini API key
  TEST_REPO         Optional: GitHub repository for testing (default: test-user/navratna-test-repo)

Options:
  --run-tests       Run all tests
  --cleanup         Clean up test repository
  --help            Show this help message

Examples:
  # Run all tests (requires GEMINI_API_KEY environment variable)
  GEMINI_API_KEY=your_key_here ./test_suite.sh --run-tests
  
  # Clean up after tests
  ./test_suite.sh --cleanup

Requirements:
  - GitHub CLI (gh) installed and authenticated
  - GEMINI_API_KEY environment variable set
  - Access to create repositories under the specified owner

Notes:
  - The test will create and use a temporary repository
  - Tests may take 15-30 minutes to complete
  - Each test consumes GitHub Actions minutes and Gemini API quota
EOF
}

# Parse command line arguments
case "${1:-}" in
    --run-tests)
        run_all_tests
        ;;
    --cleanup)
        cleanup_test_repo
        ;;
    --help|-h)
        show_help
        ;;
    "")
        show_help
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac