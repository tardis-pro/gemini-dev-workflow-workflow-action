# Navratna DevFlow - Gemini Orchestrator

A drop-in, repo-agnostic, AI-powered workflow orchestrator that uses GitHub labels as a state machine to automate software development workflows.

## Overview

**Navratna DevFlow** provides:

- **Label-driven state machine**: Issues move through `Inception` → `Discussion` → `Build` → `Review` → `Done`
- **AI-powered orchestration**: Gemini generates design docs, implementation plans, review comments, and release notes
- **Zero-coupling deployment**: Consumer repos add one tiny workflow file + one secret
- **Versioned & upgradeable**: Update the template, cut a tag, consumers upgrade with one line change
- **Monorepo-aware**: Handles affected packages, workspace commands, and scoped commits

## Quick Start (Consumer Repos)

### 1. Bootstrap (Automated)

```bash
# Clone this template repo
gh repo clone tardis-pro/devflow-gemini
cd devflow-gemini

# Run bootstrap script for your target repo
./scripts/bootstrap.sh your-org/your-repo
```

This will:
- Create all required labels (`status:*`, `feature`, `bugfix`, etc.)
- Add a DevFlow caller workflow to your repo
- Push a branch `setup/devflow` with the changes

### 2. Add Secret

```bash
gh secret set GEMINI_API_KEY --repo your-org/your-repo
```

Or via GitHub UI: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

### 3. Merge the PR

```bash
gh pr create --repo your-org/your-repo --base main --head setup/devflow \
  --title "chore: add DevFlow orchestrator" \
  --body "Adds Navratna DevFlow orchestrator workflow."

gh pr merge setup/devflow --repo your-org/your-repo --squash
```

### 4. Start Using It

Create an issue, add labels like:
- `status:inception` (or `status:discussion`, `status:build`, etc.)
- `feature` (or `bugfix`, `refactor`, etc.)

The workflow will trigger on `issues` events (`opened`, `edited`, `labeled`) and generate artifacts in `ops/out/`.

## Manual Setup (Alternative)

If you prefer manual setup:

1. **Add workflow file** to your repo at `.github/workflows/devflow.yml`:

```yaml
name: DevFlow

on:
  issues:
    types: [opened, edited, labeled]
  workflow_dispatch:

jobs:
  orchestrate:
    uses: tardis-pro/devflow-gemini/.github/workflows/orchestrator.yml@v1
    secrets: inherit
    with:
      default_branch: main
      pkg_mgr: pnpm
      install_cmd: pnpm i
      build_cmd: pnpm -w build
      test_cmd: pnpm -w test -- --ci
      lint_cmd: pnpm -w lint
      typecheck_cmd: pnpm -w typecheck
      branch_prefix: nav
      scope: core
```

2. **Create labels** (via GitHub UI or CLI):
   - `status:inception`, `status:discussion`, `status:build`, `status:review`, `status:done`
   - `feature`, `bugfix`, `refactor`, `performance`, `dep-bump`, `docs`, `chore`

3. **Add secret** `GEMINI_API_KEY`

## Configuration

### Workflow Inputs

Customize behavior by overriding inputs in your consumer workflow:

| Input | Default | Description |
|-------|---------|-------------|
| `default_branch` | `main` | Default branch name |
| `pkg_mgr` | `pnpm` | Package manager (`npm`, `pnpm`, `yarn`) |
| `install_cmd` | `pnpm i` | Install command |
| `build_cmd` | `pnpm -w build` | Build command |
| `test_cmd` | `pnpm -w test -- --ci` | Test command |
| `lint_cmd` | `pnpm -w lint` | Lint command |
| `typecheck_cmd` | `pnpm -w typecheck` | Type check command |
| `branch_prefix` | `nav` | Prefix for generated branches |
| `scope` | `core` | Scope for commit messages |
| `prompt_file` | `ops/prompts/navratna_orchestrator.md` | Path to prompt template |

### Custom Prompts

To customize the AI behavior:

1. Copy the default prompt to your repo:
```bash
mkdir -p ops/prompts
cp .github/actions/run-gemini-orchestrator/seed/ops/prompts/navratna_orchestrator.md \
   ops/prompts/navratna_orchestrator.md
```

2. Edit `ops/prompts/navratna_orchestrator.md` to your needs

3. The workflow will use your custom prompt automatically

## State Machine

### Status Labels

| Label | Stage | Outputs |
|-------|-------|---------|
| `status:inception` | Initial design | `ops/out/design-{issue}.md` |
| `status:discussion` | Refinement | `ops/out/design-{issue}-revised.md` |
| `status:build` | Implementation planning | `ops/out/impl-plan-{issue}.md` |
| `status:review` | PR review | `ops/out/review-{issue}.md` |
| `status:done` | Completion | `ops/out/release-notes-{issue}.md` |

### Work Type Labels

Used to classify the type of work:
- `feature`: New functionality
- `bugfix`: Bug fixes
- `refactor`: Code restructuring
- `performance`: Performance improvements
- `dep-bump`: Dependency updates
- `docs`: Documentation changes
- `chore`: Maintenance tasks

## Outputs

All generated artifacts are written to `ops/out/` in your repository:

```
ops/
├── prompts/
│   └── navratna_orchestrator.md  # Custom prompt (optional)
└── out/
    ├── design-123.md              # Design doc for issue #123
    ├── impl-plan-123.md           # Implementation plan
    └── review-123.md              # Review comments
```

These files are automatically committed by the `navratna-bot` user.

## Upgrading

To upgrade to a newer version of the template:

1. Check available versions:
```bash
gh release list --repo tardis-pro/devflow-gemini
```

2. Update your workflow file:
```yaml
uses: tardis-pro/devflow-gemini/.github/workflows/orchestrator.yml@v1.1  # Change version
```

3. Commit and push the change

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Consumer Repo: your-org/your-repo                      │
│                                                           │
│  .github/workflows/devflow.yml                          │
│    └─> calls reusable workflow (workflow_call)         │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  Template Repo: tardis-pro/devflow-gemini               │
│                                                           │
│  .github/workflows/orchestrator.yml (reusable)          │
│    ├─> Resolves labels → state/work-type               │
│    └─> Calls composite action                          │
│                                                           │
│  .github/actions/run-gemini-orchestrator/               │
│    ├─> Seeds prompt template (if missing)              │
│    ├─> Runs google-github-actions/run-gemini-cli       │
│    └─> Commits & pushes generated artifacts            │
│                                                           │
│  seed/ops/prompts/navratna_orchestrator.md             │
│    └─> Default prompt template                         │
└─────────────────────────────────────────────────────────┘
```

## Example Workflow

1. **Create issue**: "Add user authentication"
2. **Add labels**: `status:inception`, `feature`
3. **Workflow triggers**: Generates `ops/out/design-456.md` with:
   - Requirements analysis
   - Technical approach
   - Affected packages
   - Proposed branch name
4. **Review & refine**: Add `status:discussion`, workflow updates design
5. **Start build**: Add `status:build`, workflow generates implementation plan
6. **Create PR**: Add `status:review`, workflow analyzes diff and adds comments
7. **Merge**: Add `status:done`, workflow generates release notes snippet

## Requirements

- GitHub repository (public or private)
- Gemini API key (get one at https://aistudio.google.com/apikey)
- GitHub Actions enabled
- (Optional) Gemini Code Assist GitHub App for PR reviews

## License

MIT

## Contributing

Issues and PRs welcome! This is a template repo, so feel free to fork and customize for your needs.

## Credits

Built by [Tardis Pro](https://github.com/tardis-pro) for streamlined AI-powered development workflows.
