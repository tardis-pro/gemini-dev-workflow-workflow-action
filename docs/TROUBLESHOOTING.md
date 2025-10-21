# Troubleshooting

Common issues and solutions for Navratna DevFlow.

## Setup Issues

### Bootstrap Script Fails: "gh: command not found"

**Problem**: GitHub CLI is not installed.

**Solution**:
```bash
# macOS
brew install gh

# Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Windows
choco install gh
```

Then authenticate:
```bash
gh auth login
```

### Bootstrap Script Fails: "Permission denied"

**Problem**: No admin access to target repo.

**Solution**: Request admin access or ask an admin to run the script.

### Labels Already Exist

**Problem**: Bootstrap script warns labels exist.

**Solution**: This is fine! The script skips existing labels. Verify with:
```bash
gh label list --repo your-org/your-repo
```

## Workflow Issues

### Workflow Doesn't Trigger

**Problem**: Issue labeled but workflow doesn't run.

**Checklist**:
1. Workflow file exists: `.github/workflows/devflow.yml`
2. Workflow is enabled: **Actions** tab → **DevFlow** → Enable
3. Secret is set: **Settings** → **Secrets** → `GEMINI_API_KEY`
4. Issue has required labels: `status:*` and work type

**Debug**:
```bash
gh workflow view devflow --repo your-org/your-repo
gh run list --workflow=devflow --repo your-org/your-repo
```

### Workflow Fails: "GEMINI_API_KEY not found"

**Problem**: Secret not configured.

**Solution**:
```bash
gh secret set GEMINI_API_KEY --repo your-org/your-repo
# Paste your API key when prompted
```

Or via UI: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

### Workflow Fails: "prompt file not found"

**Problem**: Custom prompt_file specified but doesn't exist.

**Solution**:
1. Remove custom `prompt_file` input (use default)
2. Or create the file at specified path

### Workflow Runs but No Output

**Problem**: Workflow succeeds but `ops/out/` is empty.

**Checklist**:
1. Check workflow logs: **Actions** → **DevFlow** → Latest run
2. Verify Gemini API key is valid
3. Check prompt template syntax
4. Verify issue has required context (title, body)

**Debug**: Look for errors in Gemini CLI step.

## Output Issues

### No Commit/Push After Workflow

**Problem**: Workflow runs but no new commit.

**Possible Causes**:
1. No changes detected (output file unchanged)
2. Git push failed (conflicts, branch protection)

**Solution**:
- Check workflow logs for "No changes to commit"
- Check branch protection rules allow bot commits
- Verify bot has write permissions

### Output File in Wrong Location

**Problem**: Expecting `ops/out/design-123.md` but not there.

**Checklist**:
1. Verify prompt template uses correct output path
2. Check if file was renamed in commit
3. Verify issue number matches

**Debug**:
```bash
gh run view --log --repo your-org/your-repo
```

Search for "Writing" or "Commit" in logs.

## Label Issues

### Labels Not Parsed Correctly

**Problem**: Wrong state/work-type detected.

**Solution**: Ensure labels match exactly:
- Status: `status:inception`, `status:discussion`, etc. (lowercase, with colon)
- Work type: `feature`, `bugfix`, etc. (lowercase, no prefix)

**Debug**: Check workflow logs for "Resolved status: X, work_type: Y"

### Multiple Status Labels

**Problem**: Issue has multiple `status:*` labels.

**Behavior**: Workflow uses first match. Remove conflicting labels.

## Gemini API Issues

### Rate Limit Exceeded

**Problem**: Workflow fails with "quota exceeded" or "rate limit".

**Solution**:
1. Check quota: https://aistudio.google.com/
2. Reduce workflow triggers (e.g., only on `labeled`, not `edited`)
3. Implement caching (future enhancement)

### API Returns Empty Response

**Problem**: Gemini returns no output.

**Possible Causes**:
1. Prompt too long (exceeds token limit)
2. Content policy violation
3. API key invalid

**Solution**:
1. Simplify prompt
2. Check issue body for problematic content
3. Verify API key

## Permission Issues

### Bot Can't Push

**Problem**: "Permission denied" when pushing.

**Solution**:
1. Verify workflow has `contents: write` permission
2. Check branch protection rules (allow bot pushes)
3. Verify repo settings: **Settings** → **Actions** → **Workflow permissions** → **Read and write permissions**

### Bot Can't Comment (Future)

**Problem**: Bot should comment on issue but doesn't.

**Solution**:
1. Verify `issues: write` permission in workflow
2. Check if bot is blocked or has restricted access

## Customization Issues

### Custom Prompt Not Used

**Problem**: Modified `ops/prompts/navratna_orchestrator.md` but changes not reflected.

**Solution**:
1. Verify file path matches workflow input (default: `ops/prompts/navratna_orchestrator.md`)
2. Check for syntax errors in prompt
3. Trigger workflow again (may be cached)

### Build Commands Don't Work

**Problem**: `build_cmd` fails in workflow.

**Solution**:
1. Verify command works locally
2. Check if dependencies need to be installed first
3. Update `install_cmd` to install required tools

Example:
```yaml
with:
  install_cmd: pnpm i && pnpm build:deps
  build_cmd: pnpm -w build
```

## Debugging Tips

### View Workflow Logs

```bash
gh run list --workflow=devflow --repo your-org/your-repo
gh run view <run-id> --log
```

### Test Workflow Manually

```bash
gh workflow run devflow --repo your-org/your-repo
```

### Check Workflow Status

```bash
gh workflow view devflow --repo your-org/your-repo
```

### Inspect Issue Labels

```bash
gh issue view 123 --repo your-org/your-repo --json labels
```

### Dry Run Bootstrap

Test bootstrap script without making changes:

```bash
# Fork the script and add: set -x (verbose mode)
bash -x scripts/bootstrap.sh your-org/your-repo 2>&1 | tee bootstrap.log
```

## Getting Help

If none of these solutions work:

1. Check [GitHub Issues](https://github.com/tardis-pro/devflow-gemini/issues)
2. Open a new issue with:
   - Error message
   - Workflow logs
   - Steps to reproduce
   - Environment details (repo type, labels used, etc.)
3. Tag with `help wanted` label

## Common Errors Reference

| Error | Cause | Solution |
|-------|-------|----------|
| `GEMINI_API_KEY not set` | Missing secret | Add secret via `gh secret set` |
| `prompt file not found` | Custom path wrong | Fix path or use default |
| `Permission denied (push)` | No write access | Enable workflow permissions |
| `Label not found` | Typo in label | Use exact label names |
| `Quota exceeded` | API rate limit | Check quota, reduce triggers |
| `Workflow not found` | File path wrong | Verify `.github/workflows/devflow.yml` |

## Reporting Bugs

When reporting bugs, include:

1. **Workflow file**: `.github/workflows/devflow.yml`
2. **Workflow logs**: From GitHub Actions UI
3. **Issue labels**: Used to trigger workflow
4. **Expected behavior**: What should happen
5. **Actual behavior**: What actually happens
6. **Environment**: Repo type (monorepo, single package, etc.)

Template:

```markdown
## Bug Report

**Template Version**: v1.0.0 (check uses: line in workflow)
**Consumer Repo**: your-org/your-repo
**Issue Number**: #123

**Labels Applied**:
- status:inception
- feature

**Expected**: Design doc generated at ops/out/design-123.md
**Actual**: Workflow fails with error "..."

**Workflow Logs**:
\`\`\`
[paste relevant logs]
\`\`\`

**Additional Context**:
[any other relevant info]
```
