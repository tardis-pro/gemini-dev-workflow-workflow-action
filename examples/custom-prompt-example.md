# Example: Custom Prompt

This example shows how to customize the orchestrator prompt for your specific needs.

## Step 1: Copy the seed prompt to your repo

```bash
mkdir -p ops/prompts
cp .github/actions/run-gemini-orchestrator/seed/ops/prompts/navratna_orchestrator.md \
   ops/prompts/navratna_orchestrator.md
```

## Step 2: Edit the prompt

Edit `ops/prompts/navratna_orchestrator.md` to customize behavior. For example:

### Add custom state logic

```markdown
### 3. Build (Enhanced for React)
- Generate a detailed implementation plan
- Include React component structure
- Identify hooks and state management needs
- Plan for Storybook stories
- Output: `ops/out/impl-plan-${SLUG}.md`
```

### Add custom output sections

```markdown
## Example Output (Enhanced)

For an issue in "Build" state:

\`\`\`markdown
# Implementation Plan: Issue #${ISSUE_NUMBER}

## Component Structure
- ComponentName.tsx
- ComponentName.test.tsx
- ComponentName.stories.tsx
- types.ts

## State Management
- Local state: useState for X
- Global state: Redux slice for Y

## Testing Strategy
- Unit tests: Jest + React Testing Library
- Integration tests: Playwright
- Storybook stories: All variants

## PR Checklist
- [ ] Tests passing
- [ ] Storybook updated
- [ ] Types exported
- [ ] Docs updated
\`\`\`
```

### Add domain-specific variables

You can add custom variables by modifying the composite action:

1. Fork/edit `.github/actions/run-gemini-orchestrator/action.yml`
2. Add new inputs
3. Pass them to the Gemini CLI via `vars:`

```yaml
- name: Run Gemini CLI
  uses: google-github-actions/run-gemini-cli@v0
  with:
    vars: |
      # ... existing vars ...
      CUSTOM_VAR=${{ inputs.custom_var }}
```

## Step 3: Use your custom prompt

The workflow will automatically detect and use `ops/prompts/navratna_orchestrator.md` if it exists.

Alternatively, explicitly reference it in your workflow:

```yaml
jobs:
  orchestrate:
    uses: tardis-pro/devflow-gemini/.github/workflows/orchestrator.yml@v1
    secrets: inherit
    with:
      prompt_file: ops/prompts/my-custom-orchestrator.md
```

## Example: Domain-Specific Prompts

### For Backend APIs

```markdown
### 3. Build (Backend API)
- Generate OpenAPI/Swagger spec
- Identify database migrations needed
- Plan for error handling & validation
- Define logging & monitoring strategy
- Output: `ops/out/impl-plan-${SLUG}.md`
```

### For Data Pipelines

```markdown
### 3. Build (Data Pipeline)
- Define data schemas (input/output)
- Identify transformations needed
- Plan for data quality checks
- Define monitoring & alerting
- Estimate resource requirements
- Output: `ops/out/impl-plan-${SLUG}.md`
```

### For DevOps/Infrastructure

```markdown
### 3. Build (Infrastructure)
- Generate Terraform/CloudFormation plan
- Identify security considerations
- Plan for high availability & disaster recovery
- Define cost estimates
- Output: `ops/out/impl-plan-${SLUG}.md`
```

## Tips

1. **Keep the structure**: Maintain the same variable names and output file patterns
2. **Test incrementally**: Make small changes and test with a real issue
3. **Version control**: Commit your custom prompt to your repo
4. **Document changes**: Add comments explaining custom behavior
5. **Share improvements**: Consider contributing back useful patterns to the template
