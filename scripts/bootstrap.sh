#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-}"
TEMPLATE_REPO="${2:-tardis-pro/devflow-gemini}"
TEMPLATE_VERSION="${3:-v1}"

if [ -z "$REPO" ]; then
  cat <<EOF
Usage: ./scripts/bootstrap.sh <owner/repo> [template-repo] [version]

Arguments:
  owner/repo      Target repository to bootstrap (required)
  template-repo   Template repository (default: tardis-pro/devflow-gemini)
  version         Template version (default: v1)

Examples:
  ./scripts/bootstrap.sh myorg/myrepo
  ./scripts/bootstrap.sh myorg/myrepo tardis-pro/devflow-gemini v1.1

Requirements:
  - GitHub CLI (gh) installed and authenticated
  - Admin permissions on target repository
EOF
  exit 1
fi

echo "========================================="
echo "Navratna DevFlow Bootstrap"
echo "========================================="
echo "Target repo: $REPO"
echo "Template: $TEMPLATE_REPO@$TEMPLATE_VERSION"
echo ""

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
  echo "Error: GitHub CLI (gh) is not installed."
  echo "Install it from: https://cli.github.com/"
  exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
  echo "Error: Not authenticated with GitHub CLI."
  echo "Run: gh auth login"
  exit 1
fi

echo "→ Step 1: Creating labels in $REPO"
echo "-------------------------------------------"

declare -A LABELS=(
  ["status:inception"]="0366d6"
  ["status:discussion"]="fbca04"
  ["status:build"]="28a745"
  ["status:review"]="d93f0b"
  ["status:done"]="6f42c1"
  ["feature"]="84b6eb"
  ["refactor"]="5319e7"
  ["performance"]="ff6b6b"
  ["dep-bump"]="0366d6"
  ["bugfix"]="d73a4a"
  ["docs"]="0075ca"
  ["chore"]="d4c5f9"
)

for label in "${!LABELS[@]}"; do
  color="${LABELS[$label]}"
  if gh label create "$label" --color "$color" --repo "$REPO" 2>/dev/null; then
    echo "  ✓ Created: $label"
  else
    echo "  • Exists: $label"
  fi
done

echo ""
echo "→ Step 2: Creating DevFlow caller workflow"
echo "-------------------------------------------"

TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

gh repo clone "$REPO" "$TMP/repo" -- --depth=1

mkdir -p "$TMP/repo/.github/workflows"

cat > "$TMP/repo/.github/workflows/devflow.yml" <<EOF
name: DevFlow

on:
  issues:
    types: [opened, edited, labeled]
  workflow_dispatch:

jobs:
  orchestrate:
    uses: $TEMPLATE_REPO/.github/workflows/orchestrator.yml@$TEMPLATE_VERSION
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
      # Uncomment and customize if needed:
      # prompt_file: ops/prompts/navratna_orchestrator.md
EOF

pushd "$TMP/repo" >/dev/null

git checkout -b setup/devflow 2>/dev/null || git checkout setup/devflow
git add .github/workflows/devflow.yml

if git diff --cached --quiet; then
  echo "  • Workflow already exists, no changes needed"
else
  git -c user.name="devflow-bot" -c user.email="devflow-bot@users.noreply.github.com" \
    commit -m "chore: add DevFlow orchestrator caller"

  if git push -u origin setup/devflow 2>/dev/null; then
    echo "  ✓ Pushed branch: setup/devflow"
  else
    echo "  • Branch already exists remotely"
  fi
fi

popd >/dev/null

echo ""
echo "→ Step 3: Next steps"
echo "-------------------------------------------"
echo ""
echo "1. Add secret GEMINI_API_KEY to $REPO:"
echo "   gh secret set GEMINI_API_KEY --repo $REPO"
echo ""
echo "2. Open and merge the PR:"
echo "   gh pr create --repo $REPO --base main --head setup/devflow \\"
echo "     --title 'chore: add DevFlow orchestrator' \\"
echo "     --body 'Adds Navratna DevFlow orchestrator workflow.'"
echo ""
echo "3. (Optional) Install Gemini Code Assist GitHub App:"
echo "   https://github.com/apps/gemini-code-assist"
echo ""
echo "4. Start using labels on issues:"
echo "   - status:inception, status:discussion, status:build, etc."
echo "   - feature, bugfix, refactor, etc."
echo ""
echo "========================================="
echo "Bootstrap complete!"
echo "========================================="
