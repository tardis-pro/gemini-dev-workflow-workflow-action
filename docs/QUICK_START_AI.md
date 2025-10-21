# Quick Start: AI Provider Integration

Get up and running with your preferred AI provider in 5 minutes.

## Choose Your Provider

### 🚀 Gemini (Easiest - Free Tier Available)

```bash
# 1. Get API key from https://aistudio.google.com/apikey
# 2. Add secret
gh secret set GEMINI_API_KEY --repo your-org/your-repo

# 3. Create .github/workflows/devflow.yml
cat > .github/workflows/devflow.yml << 'EOF'
name: DevFlow
on:
  issues:
    types: [opened, edited, labeled]
  workflow_dispatch:

jobs:
  orchestrate:
    uses: your-org/navratna-workflow-step/.github/workflows/orchestrator-multi-provider.yml@main
    secrets:
      AI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
    with:
      ai_provider: gemini
EOF

# 4. Commit and push
git add .github/workflows/devflow.yml
git commit -m "feat: add DevFlow with Gemini"
git push
```

### 🎯 Claude (Best Quality)

```bash
# 1. Get API key from https://console.anthropic.com/
# 2. Add credits to account
# 3. Add secret
gh secret set CLAUDE_API_KEY --repo your-org/your-repo

# 4. Create workflow
cat > .github/workflows/devflow.yml << 'EOF'
name: DevFlow
on:
  issues:
    types: [opened, edited, labeled]
  workflow_dispatch:

jobs:
  orchestrate:
    uses: your-org/navratna-workflow-step/.github/workflows/orchestrator-multi-provider.yml@main
    secrets:
      AI_API_KEY: ${{ secrets.CLAUDE_API_KEY }}
    with:
      ai_provider: claude
      ai_model: claude-3-5-sonnet-20241022
EOF

# 5. Commit and push
git add .github/workflows/devflow.yml
git commit -m "feat: add DevFlow with Claude"
git push
```

### 💰 Qwen (Most Cost-Effective)

```bash
# 1. Get API key from https://dashscope.console.aliyun.com/
# 2. Add secret
gh secret set QWEN_API_KEY --repo your-org/your-repo

# 3. Create workflow
cat > .github/workflows/devflow.yml << 'EOF'
name: DevFlow
on:
  issues:
    types: [opened, edited, labeled]
  workflow_dispatch:

jobs:
  orchestrate:
    uses: your-org/navratna-workflow-step/.github/workflows/orchestrator-multi-provider.yml@main
    secrets:
      AI_API_KEY: ${{ secrets.QWEN_API_KEY }}
    with:
      ai_provider: qwen
      ai_model: qwen-max
EOF

# 4. Commit and push
git add .github/workflows/devflow.yml
git commit -m "feat: add DevFlow with Qwen"
git push
```

### 🏠 Qwen Local (Free - Private)

```bash
# 1. Install Ollama on self-hosted runner
curl -fsSL https://ollama.ai/install.sh | sh

# 2. Pull model
ollama pull qwen2.5:latest

# 3. Create workflow (note: runs-on: self-hosted)
cat > .github/workflows/devflow.yml << 'EOF'
name: DevFlow
on:
  issues:
    types: [opened, edited, labeled]
  workflow_dispatch:

jobs:
  orchestrate:
    runs-on: self-hosted  # REQUIRED for local models
    uses: your-org/navratna-workflow-step/.github/workflows/orchestrator-multi-provider.yml@main
    secrets:
      AI_API_KEY: "dummy"
    with:
      ai_provider: qwen-local
      ai_model: qwen2.5:latest
EOF

# 4. Commit and push
git add .github/workflows/devflow.yml
git commit -m "feat: add DevFlow with local Qwen"
git push
```

## Create Required Labels

```bash
# Run once per repository
gh label create status:inception --color 1d76db
gh label create status:discussion --color 0e8a16
gh label create status:build --color fbca04
gh label create status:review --color d93f0b
gh label create status:done --color 6f42c1

gh label create feature --color 0075ca
gh label create bugfix --color d73a4a
gh label create refactor --color 5319e7
```

## Test It Out

1. **Create an issue**
   ```bash
   gh issue create \
     --title "Add user authentication" \
     --body "We need to add user auth with GitHub OAuth" \
     --label "status:inception,feature"
   ```

2. **Watch the workflow run**
   ```bash
   gh run watch
   ```

3. **Check the output**
   ```bash
   git pull
   cat ops/out/design-*.md
   ```

## Next Steps

- 📖 [Full AI Providers Guide](AI_PROVIDERS.md) - Detailed configuration
- 🏗️ [Setup Guide](../SETUP_GUIDE.md) - Complete setup instructions
- 💡 [Examples](../examples/workflows/) - Example configurations

## Troubleshooting

### "Workflow not found"
- Replace `your-org/navratna-workflow-step` with actual repo path
- Ensure the workflow file is committed to main/default branch

### "Secret not found"
- Verify secret name matches (case-sensitive)
- Check secret is set: `gh secret list --repo your-org/your-repo`

### "API key invalid"
- Verify API key is correct for the provider
- Check provider-specific setup instructions in [AI_PROVIDERS.md](AI_PROVIDERS.md)

### "No output generated"
- Check workflow logs: `gh run view --log`
- Verify issue has correct labels (`status:*` and work type)
- Check API quota/credits
