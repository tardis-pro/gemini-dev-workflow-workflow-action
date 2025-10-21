# Contributing to Navratna DevFlow

Thank you for your interest in contributing! This document provides guidelines and instructions.

## How to Contribute

### Reporting Issues

1. Check if the issue already exists
2. Use a clear, descriptive title
3. Provide:
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - Environment details (OS, GitHub Actions runner, etc.)

### Suggesting Enhancements

1. Check if the enhancement has already been suggested
2. Explain the use case clearly
3. Provide examples of how it would be used
4. Consider implementation complexity

### Pull Requests

1. Fork the repo
2. Create a branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Test thoroughly:
   - Test the bootstrap script
   - Test the reusable workflow in a real repo
   - Verify seed files are copied correctly
5. Commit with clear messages: `feat: add custom variable support`
6. Push and create a PR
7. Link related issues

## Development Setup

### Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- Gemini API key for testing
- A test repository to deploy to

### Testing Changes

1. **Test bootstrap script**:
```bash
./scripts/bootstrap.sh your-test-org/test-repo
```

2. **Test reusable workflow**:
   - Push changes to your fork
   - Update a consumer repo to use your fork:
   ```yaml
   uses: your-username/devflow-gemini/.github/workflows/orchestrator.yml@your-branch
   ```
   - Create a test issue with labels
   - Verify outputs in `ops/out/`

3. **Test seed prompt**:
   - Delete `ops/prompts/` in consumer repo
   - Trigger workflow
   - Verify prompt is seeded correctly

### Project Structure

```
.
├── .github/
│   ├── workflows/
│   │   └── orchestrator.yml          # Reusable workflow
│   ├── actions/
│   │   └── run-gemini-orchestrator/
│   │       ├── action.yml            # Composite action
│   │       └── seed/                 # Seed files for consumers
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── CODEOWNERS
├── scripts/
│   └── bootstrap.sh                  # Setup automation
├── examples/                         # Example configs
├── README.md
├── CONTRIBUTING.md
└── LICENSE
```

## Coding Standards

### Shell Scripts

- Use `set -euo pipefail`
- Quote all variables: `"$VAR"`
- Provide help text
- Use descriptive variable names
- Add comments for complex logic

### YAML (Workflows/Actions)

- Use consistent indentation (2 spaces)
- Add descriptions to all inputs
- Provide sensible defaults
- Comment non-obvious behavior

### Markdown (Documentation)

- Use ATX-style headings (`#`, `##`, etc.)
- Include code examples
- Link to related resources
- Keep line length reasonable (<100 chars)

## Release Process

Maintainers will:

1. Update CHANGELOG.md
2. Tag release: `git tag v1.x`
3. Push tag: `git push origin v1.x`
4. Create GitHub release with notes

## Label Conventions

Use these labels on issues/PRs:

- `enhancement`: New feature or improvement
- `bug`: Something isn't working
- `documentation`: Docs changes
- `question`: Further information requested
- `wontfix`: This will not be worked on
- `good first issue`: Good for newcomers

## Code of Conduct

Be respectful, constructive, and inclusive. We're all here to learn and improve.

## Questions?

Open an issue with the `question` label or reach out to maintainers.

---

Thank you for contributing!
