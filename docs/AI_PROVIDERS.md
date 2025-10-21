# AI Provider Integration Guide

This guide explains how to integrate different AI providers (Gemini, Claude, Qwen) with the Navratna DevFlow orchestrator.

## Table of Contents

1. [Overview](#overview)
2. [Gemini (Google)](#gemini-google)
3. [Claude (Anthropic)](#claude-anthropic)
4. [Qwen (Alibaba Cloud)](#qwen-alibaba-cloud)
5. [Qwen (Local/Ollama)](#qwen-local-ollama)
6. [Switching Providers](#switching-providers)
7. [Cost Comparison](#cost-comparison)

---

## Overview

The orchestrator supports multiple AI providers through a unified interface. The AI provider:
- Generates design documents
- Creates implementation plans
- Writes PR review comments
- Produces release notes

### Architecture

```
GitHub Workflow → Multi-Provider Action → AI Provider Script
                                          ├─→ Gemini API
                                          ├─→ Claude API
                                          ├─→ Qwen API (Cloud)
                                          └─→ Qwen API (Local/Ollama)
```

---

## Gemini (Google)

### Setup

1. **Get API Key**
   - Visit: https://aistudio.google.com/apikey
   - Click "Create API Key"
   - Copy the key

2. **Add Secret to GitHub**
   ```bash
   gh secret set GEMINI_API_KEY --repo your-org/your-repo
   ```

3. **Configure Workflow**
   ```yaml
   uses: your-org/navratna-workflow-step/.github/workflows/orchestrator-multi-provider.yml@main
   secrets:
     AI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
   with:
     ai_provider: gemini
     ai_model: gemini-2.0-flash-exp  # or auto
   ```

### Available Models

| Model | Speed | Quality | Cost | Context |
|-------|-------|---------|------|---------|
| `gemini-2.0-flash-exp` | ⚡⚡⚡ | ⭐⭐⭐ | $ | 1M tokens |
| `gemini-1.5-pro` | ⚡⚡ | ⭐⭐⭐⭐ | $$$ | 2M tokens |
| `gemini-1.5-flash` | ⚡⚡⚡ | ⭐⭐⭐ | $ | 1M tokens |

### Pros & Cons

✅ **Pros:**
- Large context windows (1M-2M tokens)
- Generous free tier
- Fast response times
- Good code understanding

❌ **Cons:**
- May hallucinate on complex tasks
- Less consistent than Claude

---

## Claude (Anthropic)

### Setup

1. **Get API Key**
   - Visit: https://console.anthropic.com/
   - Sign up and create an API key
   - Add credits to your account

2. **Add Secret to GitHub**
   ```bash
   gh secret set CLAUDE_API_KEY --repo your-org/your-repo
   ```

3. **Configure Workflow**
   ```yaml
   uses: your-org/navratna-workflow-step/.github/workflows/orchestrator-multi-provider.yml@main
   secrets:
     AI_API_KEY: ${{ secrets.CLAUDE_API_KEY }}
   with:
     ai_provider: claude
     ai_model: claude-3-5-sonnet-20241022  # or auto
   ```

### Available Models

| Model | Speed | Quality | Cost | Context |
|-------|-------|---------|------|---------|
| `claude-3-5-sonnet-20241022` | ⚡⚡ | ⭐⭐⭐⭐⭐ | $$ | 200K tokens |
| `claude-3-opus-20240229` | ⚡ | ⭐⭐⭐⭐⭐ | $$$ | 200K tokens |
| `claude-3-haiku-20240307` | ⚡⚡⚡ | ⭐⭐⭐ | $ | 200K tokens |

### Pros & Cons

✅ **Pros:**
- Best code quality
- Most reliable and consistent
- Excellent reasoning
- Great for complex tasks

❌ **Cons:**
- More expensive
- Smaller context window (200K vs 1M+)
- No free tier

---

## Qwen (Alibaba Cloud)

### Setup

1. **Get API Key**
   - Visit: https://dashscope.console.aliyun.com/
   - Sign up for Alibaba Cloud
   - Enable DashScope API
   - Create an API key

2. **Add Secret to GitHub**
   ```bash
   gh secret set QWEN_API_KEY --repo your-org/your-repo
   ```

3. **Configure Workflow**
   ```yaml
   uses: your-org/navratna-workflow-step/.github/workflows/orchestrator-multi-provider.yml@main
   secrets:
     AI_API_KEY: ${{ secrets.QWEN_API_KEY }}
   with:
     ai_provider: qwen
     ai_model: qwen-max  # or auto
   ```

### Available Models

| Model | Speed | Quality | Cost | Context |
|-------|-------|---------|------|---------|
| `qwen-max` | ⚡⚡ | ⭐⭐⭐⭐ | $$ | 32K tokens |
| `qwen-plus` | ⚡⚡⚡ | ⭐⭐⭐ | $ | 32K tokens |
| `qwen-turbo` | ⚡⚡⚡ | ⭐⭐ | $ | 8K tokens |

### Pros & Cons

✅ **Pros:**
- Very cost-effective
- Good code understanding
- Multilingual support
- Competitive with GPT-4

❌ **Cons:**
- Requires Alibaba Cloud account
- Smaller context window
- May require VPN in some regions

---

## Qwen (Local/Ollama)

### Setup

1. **Install Ollama** (on your self-hosted runner)
   ```bash
   curl -fsSL https://ollama.ai/install.sh | sh
   ```

2. **Pull Qwen Models**
   ```bash
   ollama pull qwen2.5:latest      # 7B (fastest)
   ollama pull qwen2.5:14b         # 14B (balanced)
   ollama pull qwen2.5:32b         # 32B (quality)
   ollama pull qwen2.5:72b         # 72B (best)
   ```

3. **Configure Workflow** (use self-hosted runner)
   ```yaml
   jobs:
     orchestrate:
       runs-on: self-hosted  # Must be self-hosted!
       uses: your-org/navratna-workflow-step/.github/workflows/orchestrator-multi-provider.yml@main
       secrets:
         AI_API_KEY: "dummy"  # Not needed but required
       with:
         ai_provider: qwen-local
         ai_model: qwen2.5:latest
   ```

### Available Models

| Model | Speed | Quality | VRAM | Context |
|-------|-------|---------|------|---------|
| `qwen2.5:7b` | ⚡⚡⚡ | ⭐⭐ | 8GB | 32K tokens |
| `qwen2.5:14b` | ⚡⚡ | ⭐⭐⭐ | 16GB | 32K tokens |
| `qwen2.5:32b` | ⚡ | ⭐⭐⭐⭐ | 32GB | 32K tokens |
| `qwen2.5:72b` | ⚡ | ⭐⭐⭐⭐⭐ | 64GB | 32K tokens |

### Pros & Cons

✅ **Pros:**
- **100% free** - no API costs
- Complete data privacy
- No rate limits
- Works offline

❌ **Cons:**
- Requires self-hosted runner
- Needs GPU/high RAM
- Slower than cloud APIs
- Model quality depends on size

---

## Switching Providers

You can easily switch between providers by changing the workflow configuration:

### Method 1: Update Workflow File

Edit `.github/workflows/devflow.yml`:

```yaml
# Change from Gemini to Claude
with:
  ai_provider: claude  # was: gemini
  ai_model: claude-3-5-sonnet-20241022

# And update the secret reference
secrets:
  AI_API_KEY: ${{ secrets.CLAUDE_API_KEY }}  # was: GEMINI_API_KEY
```

### Method 2: Use Workflow Dispatch

If using `workflow_dispatch`, you can override the provider at runtime:

```bash
gh workflow run devflow.yml \
  --field ai_provider=claude \
  --field ai_model=claude-3-5-sonnet-20241022
```

---

## Cost Comparison

Approximate costs per 1M tokens (as of January 2025):

| Provider | Model | Input | Output | Total (avg) |
|----------|-------|-------|--------|-------------|
| **Gemini** | 2.0 Flash | Free | Free | **$0** |
| **Gemini** | 1.5 Pro | $3.50 | $10.50 | **$7.00** |
| **Claude** | 3.5 Sonnet | $3.00 | $15.00 | **$9.00** |
| **Claude** | 3 Opus | $15.00 | $75.00 | **$45.00** |
| **Qwen** | Max | $0.40 | $0.80 | **$0.60** |
| **Qwen** | Plus | $0.15 | $0.30 | **$0.23** |
| **Qwen Local** | Any | $0 | $0 | **$0** |

### Recommendation by Use Case

| Use Case | Recommended Provider | Reason |
|----------|---------------------|--------|
| **Getting started** | Gemini 2.0 Flash | Free tier, fast |
| **Production (quality)** | Claude 3.5 Sonnet | Best code quality |
| **Production (cost)** | Qwen Max | Cheapest cloud option |
| **Privacy/Compliance** | Qwen Local | No data leaves your infrastructure |
| **High volume** | Qwen Plus | Very cost-effective at scale |

---

## Testing Your Integration

After setting up, test with a simple issue:

1. **Create an issue** in your repo
2. **Add labels**: `status:inception`, `feature`
3. **Wait for workflow** to complete
4. **Check output** in `ops/out/design-{issue-number}.md`

The commit message will show which provider was used:
```
chore(ops): update artifacts for #123 [claude]
```

---

## Troubleshooting

### Gemini: "API key not valid"
- Verify key at https://aistudio.google.com/apikey
- Ensure API is enabled

### Claude: "Authentication error"
- Check you have credits in your account
- Verify API key is correct

### Qwen: "Request failed"
- Ensure you're in a supported region
- Check DashScope API is enabled
- Verify billing is set up

### Qwen Local: "Connection refused"
- Ensure Ollama is running: `systemctl status ollama`
- Check model is installed: `ollama list`
- Verify runner has GPU access

---

## Next Steps

- [Setup Guide](../SETUP_GUIDE.md) - General setup instructions
- [Contributing](../CONTRIBUTING.md) - How to contribute
- [Project Structure](../PROJECT_STRUCTURE.txt) - Codebase overview
