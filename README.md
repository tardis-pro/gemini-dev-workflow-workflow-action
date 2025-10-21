# Navratna DevFlow - AI Orchestrator

A drop-in, repo-agnostic, AI-powered workflow orchestrator that uses GitHub labels as a state machine to automate software development workflows.

## Overview

**Navratna DevFlow** provides:

- **Label-driven state machine**: Issues move through `Inception` → `Discussion` → `Build` → `Review` → `Done`
- **Multi-provider AI**: Support for Gemini, Claude, Qwen, and local models
- **Visual dashboard**: Next.js frontend with Kanban board, issue drawer, and workflow controls
- **GitHub App integration**: Seamless authentication and repo access
- **Zero-coupling deployment**: Consumer repos add one tiny workflow file + one secret
- **Versioned & upgradeable**: Update the template, cut a tag, consumers upgrade with one line change
- **Monorepo-aware**: Handles affected packages, workspace commands, and scoped commits

## Components

- **Workflow Orchestrator**: Reusable GitHub Actions workflows for AI-powered development automation
- **Frontend Dashboard** (`frontend/`): Next.js app with Kanban board, issue tracking, and workflow triggers
- **Multi-provider Support**: Gemini, Claude, Qwen, and local AI models

## GitHub App Setup (Required for Frontend)

### 1. Create GitHub App

1. Go to `https://github.com/settings/apps/new`
2. Fill in the details:
   - **Name**: `Navratna Orchestrator` (or your choice)
   - **Homepage URL**: Your deployment URL or repo URL
   - **Webhook**: Uncheck "Active" (or configure for live updates)
   - **Permissions**:
     - Issues: Read & Write
     - Pull Requests: Read & Write
     - Contents: Read
     - Workflows: Read & Write
     - Metadata: Read
   - **Where can this app be installed**: "Only on this account" (or "Any account")
3. Click "Create GitHub App"

### 2. Generate Private Key

1. On the app settings page, scroll to "Private keys"
2. Click "Generate a private key"
3. A `.pem` file will download
4. Convert to base64: `cat your-app.pem | base64 -w 0`
5. Save this base64 string as `GITHUB_APP_PRIVATE_KEY`

### 3. Install App on Repositories

1. In your app settings, click "Install App" in the left sidebar
2. Choose your account/organization
3. Select "All repositories" or "Only select repositories"
4. Click "Install"
5. Note the Installation ID from the URL: `https://github.com/settings/installations/12345678`
   - The number `12345678` is your `GITHUB_INSTALLATION_ID`

### 4. Configure Environment Variables

For the frontend dashboard, you'll need:

```bash
# GitHub App
GITHUB_APP_ID=123456                    # From app settings page
GITHUB_APP_PRIVATE_KEY=base64string     # Generated in step 2
GITHUB_INSTALLATION_ID=12345678         # From installation URL

# Repository (optional, can be configured in UI)
GITHUB_OWNER=your-username
GITHUB_REPO=your-repo
ORCHESTRATOR_WORKFLOW=.github/workflows/orchestrator-multi-provider.yml

# NextAuth
NEXTAUTH_URL=https://your-deployment.com
NEXTAUTH_SECRET=generate-random-string
```

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
    uses: your-org/navratna-workflow-step/.github/workflows/orchestrator-multi-provider.yml@main
    with:
      ai_provider: gemini  # Options: gemini, claude, qwen, qwen-local
      ai_model: auto       # Model name or 'auto' for best available
      default_branch: main
      pkg_mgr: pnpm
      install_cmd: pnpm i
      build_cmd: pnpm -w build
      test_cmd: pnpm -w test -- --ci
      lint_cmd: pnpm -w lint
      typecheck_cmd: pnpm -w typecheck
      branch_prefix: nav
      scope: core
    secrets:
      AI_API_KEY: ${{ secrets.GEMINI_API_KEY }}  # Or CLAUDE_API_KEY, QWEN_API_KEY
```

2. **Create labels** (via GitHub UI or CLI):
   - `status:inception`, `status:discussion`, `status:build`, `status:review`, `status:done`
   - `feature`, `bugfix`, `refactor`, `performance`, `dep-bump`, `docs`, `chore`

3. **Add AI provider secret**:
   - For Gemini: `GEMINI_API_KEY`
   - For Claude: `CLAUDE_API_KEY`
   - For Qwen: `QWEN_API_KEY`

## Configuration

### Workflow Inputs

Customize behavior by overriding inputs in your consumer workflow:

| Input | Default | Description |
|-------|---------|-------------|
| `ai_provider` | `gemini` | AI provider: `gemini`, `claude`, `qwen`, `qwen-local` |
| `ai_model` | `auto` | Model name or `auto` for best available |
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

### AI Provider Configuration

Different providers require different API keys:

- **Gemini**: Set `GEMINI_API_KEY` secret (get one at https://aistudio.google.com/apikey)
- **Claude**: Set `CLAUDE_API_KEY` secret (get one at https://console.anthropic.com/)
- **Qwen**: Set `QWEN_API_KEY` secret (for Alibaba Cloud)
- **Qwen Local**: No API key needed (uses local deployment)

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

## Frontend Dashboard

Navratna includes a visual dashboard (`frontend/`) built with Next.js that provides:

- **Kanban Board**: Drag-and-drop issues between status columns
- **Issue Drawer**: View artifacts, diffs, PR health, and CI runs
- **Workflow Controls**: Trigger orchestrator workflows with one click
- **GitHub Integration**: Seamless authentication via GitHub App

### Running Locally

```bash
cd frontend
pnpm install
pnpm dev
```

Open `http://localhost:3000` - see `frontend/README.md` for full setup.

### Deployment Options

**Cloudflare Pages** (recommended):
```bash
cd frontend
pnpm cf:build   # Build for Cloudflare
pnpm cf:deploy  # Deploy to Cloudflare
```

**Vercel**: Connect repo and deploy with environment variables configured.

See `frontend/README.md` for detailed deployment instructions.

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
