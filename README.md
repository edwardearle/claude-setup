# claude-setup

My personal Claude Code configuration, versioned so it follows me between machines. Two things live here and reach Claude Code by two different routes:

| Layer | What | How it reaches Claude Code |
|-------|------|----------------------------|
| **Global preferences** (`global/`) | Always-on `CLAUDE.md` rules: working style, spec-first TDD, model orchestration, source control, code style, plus the rules for this machine's operating system. A baseline permission allowlist. | `~/.claude/CLAUDE.md` imports `global/CLAUDE.md` and one file from `global/platform/`. `bootstrap` writes those lines and merges the settings. |
| **`flow` plugin** (`plugin/`) | Skills, agents and hooks for the workflow. | This repo is a plugin marketplace. `claude plugin install flow@ede`. Updates via `claude plugin update flow`. |

Plugins cannot carry always-on memory or `settings.json`, which is why the global layer needs the import. Everything else goes through the plugin so it is versioned and updated by the plugin system rather than by hand.

## Install on a new machine

```powershell
git clone https://github.com/edwardearle/claude-setup C:\code\claude-setup
C:\code\claude-setup\bootstrap.ps1
```

macOS, Linux or WSL: `./bootstrap.sh` (needs `jq` for the settings merge).

Restart Claude Code. `/memory` should list the global import; `/plugin` should show `flow`.

`bootstrap` is idempotent. It appends the import if `~/.claude/CLAUDE.md` already exists, adds permission rules without removing yours, and never overwrites a setting you already have.

## Update

```powershell
git -C C:\code\claude-setup pull
claude plugin update flow
```

The global layer is live as soon as the pull lands because it is read from the clone. Re-run `bootstrap.ps1` only if `global/settings.json` changed.

## The workflow

Non-trivial work goes **spec -> plan -> implement -> review**.

| Skill | Purpose | Writes |
|-------|---------|--------|
| `/flow:spec <behaviour>` | Agree what should happen before anything is built. Plain Given/When/Then, one behaviour per file, stable scenario names. | `specs/<area>/<slug>.md` |
| `/flow:plan <spec-id>` | Phased, test-first plan in plan mode. Phase 0 backfills regression tests where existing coverage is thin. | `plans/<slug>.md` |
| `/flow:implement <slug>` | Executes the plan phase by phase. Red before green, gate and commit per phase, plan checkboxes kept current. Deletes the plan on completion. | commits |
| `/flow:review [base]` | Review by a model that did not write the code, plus Codex as a second opinion when installed. Findings verified before they are reported. | nothing |
| `/flow:spec-audit [area]` | Coverage derived from spec references in test titles. Replaces hand-maintained gap documents. | nothing |
| `/flow:migrate` | Moves an existing project onto this layout in five gated phases. | branch `chore/flow-migration` |

Design choices worth knowing:

- **Spec IDs are paths**, not sequence numbers (`auth/sign-in`, not `SPEC-AUTH-007`). No registry to keep, no collisions, renames are greppable. Legacy IDs survive as `aliases` in frontmatter.
- **Coverage is derived**, never recorded. Tests carry the spec ID in their title; the audit greps for it. A hand-maintained matrix is stale by construction.
- **Plans are committed.** They are the resumable state of in-flight work across sessions and devices. Git history keeps them after the file is deleted on merge.
- **Reviews cross models.** The value of a review is independence; the same model re-reading its own diff has little.

## Model orchestration

`global/rules/orchestration.md` holds a cost, intelligence and taste table for the Claude models and for Codex, with rules for which work goes where, how much reasoning effort to spend, and how to drive Codex. The numbers are estimates: edit them as you learn what each model is worth to you.

### Effort

Levels are `low`, `medium`, `high` (the default), `xhigh` and `max`. `settings.json` accepts the first four; `max` is session-only, set with `/effort max`. Individual skills and agents pin their own level with `effort:` in frontmatter, which is why `flow:spec-checker` runs cheap and `flow:reviewer` does not drop below `high` even in a low-effort session.

### Codex setup

The Codex rows apply only when `codex` is on PATH, and `bootstrap` reports whether it is. To enable them, billed against an OpenAI API key rather than a ChatGPT plan:

```bash
npm install -g @openai/codex
printenv OPENAI_API_KEY | codex login --with-api-key
```

Set `OPENAI_API_KEY` in the shell profile so Claude Code's Bash tool inherits it: a user environment variable on Windows, `.zprofile` on macOS. Never put the key in this repository or on a command line. Defaults live in `~/.codex/config.toml`.

Billing is metered per token with no subscription ceiling, so the rules require every run to be bounded and wrapped in a subagent. Read-only runs are on the permission allowlist; anything that writes to the working tree asks first.

## Layout

```
.claude-plugin/marketplace.json   marketplace manifest (name: ede)
plugin/                           the flow plugin
  .claude-plugin/plugin.json
  skills/{spec,plan,implement,review,spec-audit,migrate}/
  agents/{reviewer,spec-checker}.md
  hooks/hooks.json, guard-git.sh  blocks git add -A, force push, --no-verify, hard reset
global/
  CLAUDE.md                       imported by ~/.claude/CLAUDE.md
  rules/*.md                      imported by global/CLAUDE.md, always loaded
  platform/{windows,macos}.md     one selected per machine by bootstrap
  settings.json                   permission baseline merged by bootstrap
templates/project/                starting CLAUDE.md and specs/README.md for a new project
bootstrap.ps1, bootstrap.sh
```

## Conventions for editing this repo

- The dependency between layers is one way: `global/` may name skills; skills never reference `global/` or any machine path.
- Always-on text costs tokens in every session. Anything procedural belongs in a skill, not in `global/`.
- Guidance that is true of one operating system goes in `global/platform/<os>.md`, never in `global/rules/`. Only the current machine's platform file is loaded, so the others cost nothing.
- Keep `.ps1` files ASCII-only (Windows PowerShell 5.1 misreads UTF-8 without a BOM).
- Bump `version` in both `plugin.json` and `marketplace.json` when the plugin changes.

Initial scaffold generated with Claude Code (Fable 5.1), 15 September 2026.
