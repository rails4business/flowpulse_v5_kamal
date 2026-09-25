# Contributing and Push/Deploy Policy

This repository requires PRs and reviews for changes to CI, deploy and infra-related files.

Quick setup for developers (local):

- Install the local Git hook to prevent accidental pushes to `main`/`master`:

```bash
git config core.hooksPath scripts
chmod +x scripts/pre-push-hook.sh
```

- The repository includes a `CODEOWNERS` file to request reviews on critical files.

Policy:
- Never push directly to `main`/`master` — open a Pull Request instead.
- Do not commit secrets (e.g. `.kamal/secrets` or `config/master.key`). Use GitHub Secrets for CI.
