# Architecture

This document describes the technical architecture of Navratna DevFlow.

## Overview

Navratna DevFlow is a **reusable GitHub Actions workflow** that orchestrates AI-powered development workflows using a label-driven state machine.

## Components

### 1. Reusable Workflow (`.github/workflows/orchestrator.yml`)

**Purpose**: Entry point that consumer repos call via `workflow_call`.

**Responsibilities**:
- Accept configuration inputs (build commands, branch prefix, etc.)
- Parse GitHub issue labels to extract state and work type
- Seed prompt template if missing in consumer repo
- Delegate to composite action

**Inputs**: 10+ configuration parameters (pkg_mgr, build_cmd, etc.)

**Outputs**: None (side effects: commits to repo)

### 2. Composite Action (`.github/actions/run-gemini-orchestrator/action.yml`)

**Purpose**: Core logic that runs the AI orchestrator.

**Responsibilities**:
- Install dependencies (jq)
- Seed prompt template from `seed/` if needed
- Prepare variables for prompt injection
- Call `google-github-actions/run-gemini-cli`
- Commit and push generated artifacts

**Inputs**: 20+ variables (repo context, issue details, commands, etc.)

**Implementation**: Composite action (multiple shell steps)

### 3. Seed Prompt Template (`.github/actions/run-gemini-orchestrator/seed/ops/prompts/navratna_orchestrator.md`)

**Purpose**: Default AI prompt that drives artifact generation.

**Structure**:
- Variable injection syntax (e.g., `${ISSUE_NUMBER}`)
- State machine logic (Inception → Discussion → Build → Review → Done)
- Output format specifications
- Example outputs

**Customization**: Consumer repos can copy and modify this prompt.

### 4. Bootstrap Script (`scripts/bootstrap.sh`)

**Purpose**: Automate setup in consumer repos.

**Responsibilities**:
- Create labels via GitHub CLI
- Add DevFlow caller workflow
- Commit and push setup branch
- Print next steps (add secret, merge PR)

**Requirements**: GitHub CLI (`gh`) authenticated with admin access

### 5. Label Schema (`.github/labels.json`)

**Purpose**: Define label taxonomy programmatically.

**Structure**: JSON array of label objects (name, color, description)

**Usage**: Can be imported programmatically or used as reference

## Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. GitHub Event (issue labeled, etc.)                       │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Consumer Workflow (.github/workflows/devflow.yml)        │
│    - Triggered by event                                     │
│    - Calls reusable workflow with inputs                    │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Reusable Workflow (orchestrator.yml)                     │
│    - Parses labels → status/work-type                       │
│    - Checks if prompt exists in consumer repo               │
│    - Passes context to composite action                     │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Composite Action (run-gemini-orchestrator)               │
│    - Installs jq                                            │
│    - Seeds prompt if missing                                │
│    - Prepares variables (ISSUE_NUMBER, PROJECT_STATUS, etc.)│
│    - Calls google-github-actions/run-gemini-cli             │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Gemini CLI Action                                        │
│    - Reads prompt file                                      │
│    - Injects variables                                      │
│    - Sends to Gemini API                                    │
│    - Returns generated text                                 │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. Composite Action (continued)                             │
│    - Writes output to ops/out/design-123.md                 │
│    - Commits changes                                        │
│    - Pushes to repo                                         │
└─────────────────────────────────────────────────────────────┘
```

## State Machine

### States (via `status:*` labels)

| State | Label | Trigger | Output |
|-------|-------|---------|--------|
| Inception | `status:inception` | Issue labeled | `ops/out/design-{N}.md` |
| Discussion | `status:discussion` | Issue labeled | `ops/out/design-{N}-revised.md` |
| Build | `status:build` | Issue labeled | `ops/out/impl-plan-{N}.md` |
| Review | `status:review` | Issue labeled | `ops/out/review-{N}.md` |
| Done | `status:done` | Issue labeled | `ops/out/release-notes-{N}.md` |

### Work Types (via labels)

Labels: `feature`, `bugfix`, `refactor`, `performance`, `dep-bump`, `docs`, `chore`

Used for:
- Commit message prefixes: `feature(core): add authentication`
- Branch naming: `nav/123-feature-authentication`
- Output customization (future)

## Customization Points

### 1. Build Commands

Consumer repos override via workflow inputs:

```yaml
with:
  build_cmd: npm run build
  test_cmd: npm test
```

### 2. Prompt Template

Consumer repos copy and modify:

```bash
mkdir -p ops/prompts
cp seed/ops/prompts/navratna_orchestrator.md ops/prompts/
# Edit ops/prompts/navratna_orchestrator.md
```

Workflow automatically uses custom prompt if it exists.

### 3. Branch Prefix

```yaml
with:
  branch_prefix: myprefix  # Generates myprefix/123-feature-auth
```

### 4. Scope

```yaml
with:
  scope: api  # Generates feature(api): ...
```

## Security Considerations

### Secrets

- `GEMINI_API_KEY`: Required. Consumer repos add this as GitHub Actions secret.
- Accessed via `${{ secrets.GEMINI_API_KEY }}` in workflow.
- Never logged or exposed.

### Permissions

Workflow requires:
- `contents: write` - To commit/push generated artifacts
- `pull-requests: write` - To create/comment on PRs (future)
- `issues: write` - To comment on issues (future)
- `actions: read` - To read workflow status

### Code Execution

- No arbitrary code execution
- All commands are configurable strings (build_cmd, test_cmd, etc.)
- Prompt template is markdown (no execution)

## Extensibility

### Adding New States

1. Add label to `.github/labels.json`
2. Update bootstrap script to create label
3. Update reusable workflow to parse label
4. Update prompt template with new state logic

### Adding Custom Variables

1. Add input to reusable workflow (`orchestrator.yml`)
2. Pass to composite action
3. Add to `vars:` in composite action
4. Use `${CUSTOM_VAR}` in prompt template

Example:

```yaml
# orchestrator.yml
inputs:
  custom_var:
    required: false
    type: string
    default: "value"

# Pass to composite action
with:
  custom_var: ${{ inputs.custom_var }}

# action.yml
vars: |
  CUSTOM_VAR=${{ inputs.custom_var }}
```

## Performance

- **Cold start**: ~30-60s (checkout, seed, Gemini API call)
- **Warm start**: ~20-40s (if prompt already seeded)
- **Concurrency**: Multiple issues can be processed in parallel
- **Rate limits**: Subject to Gemini API limits (check quota)

## Error Handling

- Missing prompt: Seeded automatically from template
- Missing secret: Workflow fails with clear error
- API errors: Logged in workflow output
- Commit conflicts: Push may fail (safe, no data loss)

## Future Enhancements

- [ ] PR comment integration (review comments on diff)
- [ ] Slack/Discord notifications
- [ ] Multi-repo orchestration (monorepo packages → separate PRs)
- [ ] Dependency graph analysis (which packages affected)
- [ ] Cost tracking (Gemini API usage)
- [ ] Caching layer (avoid re-generating same artifacts)
