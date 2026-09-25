#!/usr/bin/env bash
set -euo pipefail

# Prevent accidental direct pushes to protected branches (main/master).
# Install locally with:
#   git config core.hooksPath scripts
#   chmod +x scripts/pre-push-hook.sh

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
  cat <<'MSG'
Warning: you are about to push directly to 'main' or 'master'.
This repository policy requires opening a Pull Request for review before merging/deploy.

If you really need to push directly, switch to a feature branch or ask for approval.
Push aborted.
MSG
  exit 1
fi

# Allow push for non-protected branches
exit 0
