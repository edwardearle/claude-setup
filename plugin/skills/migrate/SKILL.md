---
name: migrate
description: "Move an existing project onto the flow workflow: slim its CLAUDE.md to project-specific content, split monolithic specification documents into specs/<area>/<slug>.md, retire hand-maintained coverage documents in favour of derived audits, write a first guide for each area, and bring in-flight plans under version control. Phased, gated, reversible. Invoke manually: /flow:migrate"
disable-model-invocation: true
---

# Migrate a project to the flow workflow

Five phases, each gated with `AskUserQuestion` and committed separately on a branch `chore/flow-migration`. Nothing is deleted until its replacement exists and has been checked. Announce the entry phase first: a partly migrated project resumes where it stopped.

Read the `flow:spec` skill's `SPEC-FORMAT.md` and the `templates/project/CLAUDE.md` shape from the setup repository before starting (the plugin root is `${CLAUDE_PLUGIN_ROOT}`; the templates sit beside it at `../templates/`).

## Phase 0: Inventory (read-only)

Collect and present in one table, then gate.

- **Instruction files**: `CLAUDE.md`, `claude.md`, `AGENTS.md`, `.claude/*.md`. Line count and section headings for each.
- **Spec material**: files containing Given/When/Then, `SPEC-` style IDs, or `Feature:` blocks. Count distinct IDs. Flag duplicates and gaps in numbering.
- **Hand-maintained coverage**: gap analyses, coverage matrices, "Tested / Not tested" tables. Note the last-updated date against the newest spec ID; the difference is the drift.
- **Plans**: `*.todo.md`, `TODO.md`, `plans/`. Whether they are gitignored, and whether any are committed regardless.
- **Backlog files**: feature lists, ideas documents.
- **Traceability in tests**: count of test files referencing spec IDs, and the reference shape used (`@covers`, `describe('SPEC-...`).
- **Settings**: `.claude/settings*.json` allowlist size and any entries carrying another machine's absolute paths.

Use `Explore` or a `haiku` agent for the counting. Keep only the table.

## Phase 1: Instruction file

Classify every section of the existing instruction file:

| Class | Action |
|-------|--------|
| Restates global rules (TDD, commit format, comment policy, ask-before-commit, small commits) | Delete; the global configuration already says it |
| Project-specific and always needed (stack, commands, layout, hard rules unique to this codebase) | Keep, tighten |
| Procedural reference (release steps, migration recipes, platform build instructions) | Move to a project skill at `.claude/skills/<name>/SKILL.md` with a one-line pointer from `CLAUDE.md` |
| Spec category tables, ID registries, test directory maps | Delete; the `specs/` layout replaces them |
| Co-author lines, ticket formats from another organisation | Delete |

Rewrite `CLAUDE.md` in the template shape. If only the case differs, rename in two steps (`git mv claude.md tmp && git mv tmp CLAUDE.md`); a direct case-only rename is a no-op on a case-insensitive filesystem. Target under 80 lines. Present the before/after line counts and the moved sections; gate; commit `chore(claude): slim instructions to project-specific content`.

## Phase 2: Specs

1. **Map.** Parse the monolith into one entry per spec heading. Derive `area` from the category prefix (`SPEC-AUTH` -> `auth`, `SPEC-SUB` -> `billing` or whatever the user prefers; ask once for the whole mapping). Derive `slug` from the title. Produce `specs/MIGRATION-MAP.md`: `old id | new id | status | note`. Resolve duplicate IDs by intent, not position. Gate on the map before writing any spec file.
2. **Write.** One file per entry in the spec format. Old ID goes in `aliases`. Scenario names are kebab-cased from the scenario titles. Status: `implemented` only if the coverage document and a live grep both agree tests exist; otherwise `accepted`. Preserve wording; do not improve the specs during migration.
3. **Rewrite test references** mechanically from the map: `describe('SPEC-AUTH-007: ...')` -> `describe('auth/sign-in', ...)`, `@covers SPEC-AUTH-007` -> `@covers auth/sign-in`. Give this to a Sonnet agent with the map and the file list. Run the full suite: only names should have changed, so anything failing is a mistake in the rewrite.
4. **Check.** Spec count in equals files out. Every old ID appears in exactly one `aliases`. Run `/flow:spec-audit`; there should be no orphan references.
5. Gate; commit `refactor(specs): one file per behaviour with legacy ids as aliases`. Delete the monolith in a **separate** commit: `chore(specs): remove superseded specification document`.
6. **Guides.** Run `/flow:guide` for every area with implemented specs. The guides describe what the migrated specs say, not what the code might do beyond them. Gate; commit `docs(specs): add area guides`.

## Phase 3: Coverage documents

Run `/flow:spec-audit` against the hand-maintained document. List every claim the audit cannot substantiate; those are the stale entries and the case for deletion. Gate; delete the document; commit `chore(specs): replace coverage document with derived audit`.

## Phase 4: Plans and backlog

- Remove `*.todo.md` from `.gitignore`. Move in-flight plans to `plans/<slug>.md` in the plan template shape (add `Specs:` and `## State`). Delete finished ones. Commit `chore(plans): track in-flight plans`.
- Backlog files: offer to turn each entry into an issue (`gh issue create`, one per entry, only after the user approves the list) and delete the file, or leave it and say so. Ideas are not specs.

## Phase 5: Settings

Strip allowlist entries that carry another machine's paths or one-off encoded commands from `.claude/settings.local.json`. Suggest which project-generic rules (test, lint, build commands) belong in a committed `.claude/settings.json`. Gate; commit `chore(claude): tidy permission allowlist`.

## Finish

Report: line counts before and after for the instruction file; spec files written; test files rewritten and the suite result; documents deleted; anything left unmigrated and why. Suggest the user open a PR from `chore/flow-migration`.

## Rules

- Never delete in the same commit that creates the replacement.
- Never rewrite spec wording during migration. Improving specs is `/flow:spec` work afterwards.
- If the test suite cannot run locally, stop at Phase 2 step 3 and give the user the commands. Do not pass the gate on assumption.
