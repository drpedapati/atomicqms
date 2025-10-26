# Repository Guidelines

This guide helps contributors extend the AtomicQMS Claude integration safely and consistently. Follow these practices before submitting changes.

## Project Structure & Module Organization
- `docs/` holds VuePress source; author user content under `docs/guide/` and keep shared assets in `docs/.vuepress/public/`.
- `.gitea/workflows/` contains the Claude QMS workflow; adjust runner logic here when workflows change.
- `auto-init-service/` provides bootstrap scripts and templates for seeding new instances; treat `templates/` as authoritative.
- `gitea/` and `runner-data/` mirror container volumes for local Gitea + runner stacks; avoid manual edits unless debugging deployments.

## Build, Test, and Development Commands
- `npm install` ensures VuePress dependencies match `package-lock.json`.
- `npm run docs:dev` serves docs with hot reload at `http://localhost:8080`, useful for previewing navigation and component changes.
- `npm run docs:build` generates the static site to `docs/.vuepress/dist`; run before commits touching docs to catch build regressions.
- `./check-ai-assistant.sh` runs the end-to-end environment diagnostics (containers, runner, workflow); use after compose changes or setup scripts.
- `docker compose up -d` starts the full AtomicQMS stack defined in `docker-compose.yml`.

## Coding Style & Naming Conventions
- Write Markdown with semantic headings and front-matter keys in lower-case hyphenated form (see `docs/README.md`).
- Use two-space indentation for YAML and VuePress config blocks; keep shell scripts POSIX-compliant with `set -e` where appropriate.
- Environment variables are uppercase with underscores (`RUNNER_TOKEN`, `ATOMICQMS_CONTAINER`); document defaults in `.env.example`.

## Testing Guidelines
- Treat `npm run docs:build` as the minimum regression gate; failures must be resolved before review.
- For workflow updates, trigger a dry run via `./check-ai-assistant.sh` and capture any warnings in the PR.
- Verify new setup scripts with `shellcheck` locally and note any ignored warnings inline.

## Commit & Pull Request Guidelines
- Follow the existing imperative, topic-first messages (`Fix:`, `Add`, `Update`) as seen in `git log --oneline`.
- Limit commits to one logical change; include context in the body when touching deployment assets or workflows.
- PRs should link the related issue, summarize environment impact, and include screenshots or logs when modifying UI or runner behavior.
- Checkbox outstanding tasks and call out required secrets or configuration migrations explicitly.

## Security & Configuration Tips
- Never commit real credentials; copy required entries into `.env.example` or document them in `docs/authentication/`.
- Keep secrets synchronized between local `.env` and Gitea repository secrets (`ANTHROPIC_API_KEY`, `QMS_SERVER_URL`).
- When adjusting Docker services, validate port exposure and network aliases to match runner expectations before merging.
