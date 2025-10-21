# Navratna DevFlow Test Suite Documentation

## Overview

The Navratna DevFlow test suite is a comprehensive set of tests designed to validate the functionality of the Navratna DevFlow GitHub Actions orchestrator. The tests validate the entire workflow from issue creation through to artifact generation.

## Test Suite Components

The test suite includes:

1. **Bootstrap Tests**: Verify the bootstrap script correctly sets up labels and workflow files
2. **State Machine Tests**: Validate each state in the workflow (Inception → Discussion → Build → Review → Done)
3. **Integration Tests**: End-to-end testing of the complete workflow
4. **Error Handling Tests**: Verify proper error handling when configurations are missing
5. **Customization Tests**: Validate custom prompt functionality

## Prerequisites

Before running the tests, ensure you have:

1. **GitHub CLI (gh)** installed and authenticated:
   ```bash
   gh auth login
   ```

2. **A Gemini API Key** from [Google AI Studio](https://aistudio.google.com/apikey)

3. **Repository Creation Permissions**: The ability to create repositories in the organization/username you specify

4. **Sufficient GitHub Actions Minutes**: Each test consumes GitHub Actions minutes

5. **Sufficient Gemini API Quota**: Each test consumes Gemini API quota

## Setup Instructions

### 1. Environment Setup

Set the required environment variables:

```bash
export GEMINI_API_KEY="your-gemini-api-key-here"
export TEST_REPO="your-username/test-repo-name"  # Optional, defaults to test-user/navratna-test-repo
```

### 2. Repository Configuration

- The test suite will create a temporary repository for testing
- Ensure you have permission to create repositories in the specified owner/organization
- The test repository will be private by default

## Running the Tests

### Basic Usage

```bash
# Make the test suite executable
chmod +x test_suite.sh

# Run all tests
GEMINI_API_KEY="your-api-key" ./test_suite.sh --run-tests
```

### With Custom Repository

```bash
GEMINI_API_KEY="your-api-key" TEST_REPO="myorg/my-test-repo" ./test_suite.sh --run-tests
```

## Test Execution Details

### Test Duration

- Total execution time: Approximately 15-30 minutes
- Each individual test may take 3-5 minutes to complete
- Tests include wait periods to allow GitHub Actions workflows to complete

### Test Process

Each test follows this general process:

1. Create a GitHub issue with appropriate labels
2. Wait for the DevFlow workflow to trigger and complete
3. Verify that the expected output file was created
4. Validate the content of the output file

### Test States Validated

The suite validates these workflow states:

- **Inception**: Creates `ops/out/design-{issue_number}.md`
- **Discussion**: Creates `ops/out/design-{issue_number}-revised.md`
- **Build**: Creates `ops/out/impl-plan-{issue_number}.md`
- **Review**: Creates `ops/out/review-{issue_number}.md`
- **Done**: Creates `ops/out/release-notes-{issue_number}.md`

## Expected Output

The test suite will display:

- Individual test results with PASS/FAIL status
- Summary of all tests at the end
- Detailed logs for each test step

Example output:
```
[INFO] Starting Navratna DevFlow Test Suite
[INFO] Test repository: test-user/navratna-test-repo

Running test: Bootstrap Script Validation
----------------------------------------
[PASS] Bootstrap Script Validation

Running test: Inception State - Design Document Generation
----------------------------------------
[PASS] Inception State - Design Document Generation

...

=========================================
TEST SUITE COMPLETED
=========================================
PASSED: 9
FAILED: 0
SKIPPED: 0
=========================================
[PASS] All tests passed!
```

## Cleanup

After tests are complete, you can clean up the test repository:

```bash
./test_suite.sh --cleanup
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**:
   - Ensure GitHub CLI is authenticated: `gh auth login`
   - Verify credentials have appropriate permissions

2. **API Key Errors**:
   - Verify GEMINI_API_KEY is set and valid
   - Check that the API key has appropriate permissions

3. **Repository Creation Errors**:
   - Verify repository owner/name is accessible
   - Ensure you have permissions to create repositories

4. **Timeout Errors**:
   - GitHub Actions may take longer than expected
   - Verify the repository is private to ensure proper permissions

### Debugging Tips

- Check the output of `gh auth status` to verify authentication
- Verify repository exists and you have write access
- Look at GitHub Actions logs in the repository for failed workflow runs
- Ensure sufficient API quota for Gemini API calls

## Test Coverage

The test suite covers:

- ✅ Bootstrap script functionality
- ✅ All workflow states (Inception, Discussion, Build, Review, Done)
- ✅ Error handling for missing secrets
- ✅ Custom prompt template functionality
- ✅ GitHub secret management
- ✅ Output file generation and content validation

## Security Considerations

- The test suite creates repositories with the GitHub API key
- API keys are not stored or logged by the test suite
- Test repositories should be cleaned up after testing
- Use test-specific API keys when possible

## Extending the Test Suite

The test suite is designed to be extensible. To add new tests:

1. Define a new test function following the pattern of existing tests
2. Add the test to the `run_all_tests` function
3. Update this documentation to reflect the new test

The test suite provides a solid foundation for ensuring the reliability and correctness of the Navratna DevFlow orchestrator.