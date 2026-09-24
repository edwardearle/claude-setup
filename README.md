# claude-setup

My personal Claude Code configuration, versioned so it follows me between machines. Two things live here and reach Claude Code by two different routes:

| Layer | What | How it reaches Claude Code |
|-------|------|----------------------------|
| **Global preferences** (`global/`) | Always-on `CLAUDE.md` rules: working style, spec-first TDD, model orchestration, source control, code style, plus the rules for this machine's operating system. A baseline permission allowlist and the default main-session model (Opus). | `~/.claude/CLAUDE.md` imports `global/CLAUDE.md` and one file from `global/platform/`. `bootstrap` writes those lines and merges the settings. |
| **`flow` plugin** (`plugin/`) | Skills, agents and hooks for the workflow. | This repo is a plugin marketplace. `claude plugin install flow@ede`. Updates via `claude plugin update flow`. |

Plugins cannot carry always-on memory or `settings.json`, which is why the global layer needs the import. Everything else goes through the plugin so it is versioned and updated by the plugin system rather than by hand.

## Install on a new machine

```powershell
git clone https://github.com/edwardearle/claude-setup C:\code\claude-setup
C:\code\claude-setup\bootstrap.ps1
```

macOS, Linux or WSL: `./bootstrap.sh` (needs `jq` for the settings merge).

Restart Claude Code. `/memory` should list the global import; `/plugin` should show `flow`.

`bootstrap` is idempotent. It appends the import if `~/.claude/CLAUDE.md` already exists, adds permission rules without removing yours, and never overwrites a setting you already have. It merges settings after the plugin step and warns if any merged setting is missing afterwards.

## Update

```powershell
git -C C:\code\claude-setup pull
claude plugin update flow
```

The global layer is live as soon as the pull lands because it is read from the clone. Re-run `bootstrap.ps1` only if `global/settings.json` changed.

## The workflow

Non-trivial work goes **design -> spec -> plan -> implement -> review**.

| Skill | Purpose | Writes |
|-------|---------|--------|
| `/flow:design <issue \| description>` | Judge whether the high-level design is ready to spec: problem, outcome, scope, approach, interface (including where the design system lives), constraints, unknowns, size. Closes the gaps with you, accepts design done elsewhere rather than redoing it, and splits large work by deliverable. When nobody can answer, it posts the gaps and stops. | design section on the issue, one comment per pass, sub-issues, board status |
| `/flow:spec <behaviour>` | Agree what should happen before anything is built. Plain Given/When/Then, one behaviour per file, stable scenario names. | `specs/<area>/<slug>.md` |
| `/flow:plan <spec-id>` | Phased, test-first plan in plan mode. Phase 0 backfills regression tests where existing coverage is thin. | `plans/<slug>.md` |
| `/flow:implement <slug>` | Executes the plan phase by phase. Red before green, gate and commit per phase, plan checkboxes kept current. Deletes the plan on completion. | commits |
| `/flow:guide [area]` | What an area does today, journey by journey, linked to the spec scenarios behind it. Only implemented behaviour. Written in a plan's Document phase, never while speccing. | `specs/<area>/README.md` |
| `/flow:review [base]` | Review by a model that did not write the code, plus Codex as a second opinion when installed, plus a check that the README, everything it links and the guides of the areas changed are still true. Findings verified before they are reported. | nothing |
| `/flow:spec-audit [area]` | Coverage derived from spec references in test titles, and guides that have fallen behind their specs. Replaces hand-maintained gap documents. | nothing |
| `/flow:capture <area> [journey]` | Runs the app, follows the guide's journeys with Playwright and saves a screenshot at each step, as input to design tools or a UX fix. Nothing is committed. | screenshots outside the repo |
| `/flow:readme [check \| path]` | Create, improve or check a README and the documents it links against the recipe in `plugin/skills/readme/RECIPE.md`. `check` runs the `flow:docs-checker` agent alone. | `README.md`, `docs/` |
| `/flow:migrate` | Moves an existing project onto this layout in five gated phases, including a first guide for each area. | branch `chore/flow-migration` |
| `/flow:pickup [issue]` | Takes a tracker issue from the board through design readiness and branching, hands over to `/flow:design` and the flow skills at each stage, and keeps board status current. Board moves need the `github-projects-v2` skill (kept outside this repo, in `~/.claude/skills`); without it the skill leaves status to you. | branch, board status, PR on request |

Design choices worth knowing:

- **Spec IDs are paths**, not sequence numbers (`auth/sign-in`, not `SPEC-AUTH-007`). No registry to keep, no collisions, renames are greppable. Legacy IDs survive as `aliases` in frontmatter.
- **Coverage is derived**, never recorded. Tests carry the spec ID in their title; the audit greps for it. A hand-maintained matrix is stale by construction.
- **Plans are committed.** They are the resumable state of in-flight work across sessions and devices. Git history keeps them after the file is deleted on merge.
- **Reviews cross models.** The value of a review is independence; the same model re-reading its own diff has little.
- **Documentation is reviewed with the code.** A PR to `main` carries a `Docs:` line stating what the check found and what changed. Checking whether a sentence is still true is cheap and goes to the checker, which never rewrites; writing the replacement is prose and goes to the prose writer.
- **Design readiness lives on the issue**, not in the repository. `/flow:design` owns one marked section of the issue body and adds a comment per pass, so the issue carries the current design and how it got there. Design that already exists (a proposal, a Figma file) is linked and judged, not redone. An issue that is not ready is not specced.
- **Breakdown happens twice.** Design splits work by deliverable: slices on one issue when they share a design, sub-issues when each part needs its own. Specs split a slice by behaviour. Specs never get their own issues; an issue per spec would duplicate `specs/` and drift.
- **Guides are the readable as-is record, written last.** Specs are the detail, `specs/<area>/README.md` is the summary by journey, and the design on the issue is the gap between them, which closes with the issue. A guide is written in a plan's Document phase from the final specs, so it describes what was built rather than what was intended. The audit and the review report guides that have fallen behind.

## Model orchestration

`global/rules/orchestration.md` holds two tables. The first rates Haiku, Sonnet, Opus, Fable and GPT-5.6 and GPT-6 via Codex on cost, intelligence and taste; the numbers are starting estimates, so edit them as you learn what each model is worth to you. The second assigns a model to each named role: lead, explorer, executor, UI builder, prose writer, illustrator, checker, reviewer and second opinion. Skills and agents name a role, never a model, so that table is the only place a model is chosen and changing a route is an edit to one file. Claude models are the default: Codex is for independent review, for a problem two Claude attempts have failed, and for load-bearing changes, because briefing a model that holds none of the session's context costs more than the table suggests. Codex routes apply only when `codex` is on PATH; `bootstrap` tells you whether it is.

SVG is the one place Codex wins on craft rather than independence: Astra draws better static and animated SVG than any Claude model, so drawing one goes to it. Editing an SVG that already exists is just a code change and stays where it would otherwise go. Imagery is opt-in in every format: a picture you did not ask for gets proposed in one line and waits for your answer.

When Codex is installed, `bootstrap` also writes `~/.codex/config.toml` and `~/.codex/api.config.toml`: a profile that bills the OpenAI API from `OPENAI_API_KEY` instead of ChatGPT plan credits. Plan credits stay the default (a stored ChatGPT login wins over the environment variable); `codex exec --profile api` is the fallback when they run out, and `/flow:review` retries on it once if Codex stops on a usage limit. Codex has no automatic billing failover of its own.

## Layout

```
.claude-plugin/marketplace.json   marketplace manifest (name: ede)
plugin/                           the flow plugin
  .claude-plugin/plugin.json
  skills/{design,spec,plan,implement,guide,capture,review,spec-audit,readme,migrate,pickup}/
  agents/{reviewer,spec-checker,docs-checker}.md
  hooks/hooks.json, guard-git.sh  blocks git add -A, force push, --no-verify, hard reset
global/
  CLAUDE.md                       imported by ~/.claude/CLAUDE.md
  rules/*.md                      imported by global/CLAUDE.md, always loaded
  platform/{windows,macos}.md     one selected per machine by bootstrap
  settings.json                   permission baseline and default model, merged by bootstrap
templates/project/                starting CLAUDE.md and specs/README.md for a new project
bootstrap.ps1, bootstrap.sh
```

## Conventions for editing this repo

- The dependency between layers is one way: `global/` may name skills; skills never reference `global/` or any machine path.
- Always-on text costs tokens in every session. Anything procedural belongs in a skill, not in `global/`.
- Guidance that is true of one operating system goes in `global/platform/<os>.md`, never in `global/rules/`. Only the current machine's platform file is loaded, so the others cost nothing.
- Keep `.ps1` files ASCII-only (Windows PowerShell 5.1 misreads UTF-8 without a BOM).
- Bump `version` in both `plugin.json` and `marketplace.json` when the plugin changes.

## Licence

MIT. See [LICENSE](LICENSE).

Initial scaffold generated with Claude Code (Fable 5.1), 15 September 2026.
