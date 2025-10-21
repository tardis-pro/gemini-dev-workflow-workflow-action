# Setup Guide - Navratna DevFlow Template

This guide walks you through deploying this template repository and using it across your organization.

## Repository Structure

```
devflow-gemini/                          # This template repo
├── .github/
│   ├── workflows/
│   │   └── orchestrator.yml             # Reusable workflow (main entry point)
│   ├── actions/
│   │   └── run-gemini-orchestrator/
│   │       ├── action.yml               # Composite action (core logic)
│   │       └── seed/
│   │           └── ops/
│   │               ├── prompts/
│   │               │   └── navratna_orchestrator.md  # Default AI prompt
│   │               └── out/
│   │                   └── .gitkeep
│   ├── labels.json                      # Label schema (programmatic reference)
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── CODEOWNERS
│
├── scripts/
│   └── bootstrap.sh                     # One-command setup automation
│
├── examples/
│   ├── devflow-consumer.yml             # Example consumer workflow
│   └── custom-prompt-example.md         # Customization guide
│
├── docs/
│   ├── ARCHITECTURE.md                  # Technical architecture
│   ├── TROUBLESHOOTING.md               # Common issues & solutions
│   └── VERSIONING.md                    # Version upgrade guide
│
├── README.md                            # Main documentation
├── CONTRIBUTING.md                      # Contribution guidelines
├── CHANGELOG.md                         # Version history
├── LICENSE                              # MIT License
└── .gitignore
```

## Step 1: Publish This Template

### Option A: GitHub Organization (Recommended)

```bash
# 1. Create the template repo
gh repo create tardis-pro/devflow-gemini --public --source=. --remote=origin

# 2. Push all files
git init
git add -A
git commit -m "feat: initial template scaffold"
git branch -M main
git remote add origin https://github.com/tardis-pro/devflow-gemini.git
git push -u origin main

# 3. Tag v1
git tag v1
git push origin v1

# 4. Create GitHub release
gh release create v1 --title "v1.0.0 - Initial Release" --notes "Initial stable release of Navratna DevFlow orchestrator template."
```

### Option B: Private/Enterprise

```bash
# Same as above, but use --private flag
gh repo create tardis-pro/devflow-gemini --private --source=. --remote=origin
```

## Step 2: Bootstrap a Consumer Repo

Once the template is published, bootstrap any target repo:

```bash
# From this directory
./scripts/bootstrap.sh your-org/target-repo

# Or specify custom template location
./scripts/bootstrap.sh your-org/target-repo tardis-pro/devflow-gemini v1
```

This will:
1. Create all required labels
2. Add `.github/workflows/devflow.yml` to target repo
3. Push a branch `setup/devflow`

## Step 3: Add Secret to Consumer Repo

```bash
# Set GEMINI_API_KEY secret
gh secret set GEMINI_API_KEY --repo your-org/target-repo

# Or for organization-level (all repos)
gh secret set GEMINI_API_KEY --org your-org
```

Get your Gemini API key: https://aistudio.google.com/apikey

## Step 4: Merge Setup PR

```bash
# Create PR
gh pr create --repo your-org/target-repo \
  --base main \
  --head setup/devflow \
  --title "chore: add DevFlow orchestrator" \
  --body "Adds Navratna DevFlow orchestrator workflow. Once merged, issues labeled with \`status:*\` will trigger AI-powered artifact generation."

# Review and merge
gh pr view setup/devflow --repo your-org/target-repo
gh pr merge setup/devflow --repo your-org/target-repo --squash
```

## Step 5: Test the Workflow

```bash
# 1. Create a test issue
gh issue create --repo your-org/target-repo \
  --title "Add user authentication" \
  --body "We need to add authentication using OAuth 2.0" \
  --label "status:inception,feature"

# 2. Watch workflow run
gh run watch --repo your-org/target-repo

# 3. Check generated artifact
git pull
cat ops/out/design-*.md
```

## Upgrading Consumer Repos

When you release a new version of the template:

```bash
# 1. Tag new version in template repo
git tag v1.1
git push origin v1.1
gh release create v1.1 --title "v1.1.0 - Feature X" --notes "Added feature X..."

# 2. Consumer repos update their workflow:
# Edit .github/workflows/devflow.yml
# Change: uses: tardis-pro/devflow-gemini/.github/workflows/orchestrator.yml@v1
# To:     uses: tardis-pro/devflow-gemini/.github/workflows/orchestrator.yml@v1.1

# 3. Commit and push
git commit -am "chore: upgrade devflow to v1.1"
git push
```

## Customization

### Custom Build Commands

Consumer repos override via workflow inputs:

```yaml
jobs:
  orchestrate:
    uses: tardis-pro/devflow-gemini/.github/workflows/orchestrator.yml@v1
    secrets: inherit
    with:
      build_cmd: npm run build
      test_cmd: npm test -- --coverage
      # ... other overrides
```

### Custom Prompt Template

```bash
# In consumer repo
mkdir -p ops/prompts
cp <path-to-template>/seed/ops/prompts/navratna_orchestrator.md ops/prompts/

# Edit ops/prompts/navratna_orchestrator.md
# Workflow automatically uses it
```

## Common Tasks

### Add Labels to Existing Repo

```bash
gh label create status:inception --color 0366d6 --repo your-org/repo
gh label create status:discussion --color fbca04 --repo your-org/repo
gh label create status:build --color 28a745 --repo your-org/repo
gh label create status:review --color d93f0b --repo your-org/repo
gh label create status:done --color 6f42c1 --repo your-org/repo

gh label create feature --color 84b6eb --repo your-org/repo
gh label create bugfix --color d73a4a --repo your-org/repo
gh label create refactor --color 5319e7 --repo your-org/repo
# ... etc (or use bootstrap.sh)
```

### Check Workflow Status

```bash
gh run list --workflow=devflow --repo your-org/repo
gh run view <run-id> --log --repo your-org/repo
```

### Re-run Failed Workflow

```bash
gh run rerun <run-id> --repo your-org/repo
```

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for detailed solutions.

Quick checks:
1. Secret set? `gh secret list --repo your-org/repo | grep GEMINI`
2. Workflow enabled? Check Actions tab
3. Labels exact? `status:inception` not `Status: Inception`
4. Logs: `gh run view --log --repo your-org/repo`

## Next Steps

1. **Deploy template**: Push to GitHub
2. **Bootstrap repos**: Run `./scripts/bootstrap.sh` for each target repo
3. **Add secrets**: `gh secret set GEMINI_API_KEY`
4. **Create issues**: Add `status:*` and work type labels
5. **Profit**: Watch AI generate artifacts automatically

## Support

- **Issues**: https://github.com/tardis-pro/devflow-gemini/issues
- **Discussions**: https://github.com/tardis-pro/devflow-gemini/discussions
- **Docs**: See [README.md](README.md) and [docs/](docs/)

## License

MIT - See [LICENSE](LICENSE)
