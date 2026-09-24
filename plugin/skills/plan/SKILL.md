---
name: plan
description: "Turn one or more accepted specs into a phased, test-first implementation plan saved at plans/<slug>.md. Use after /flow:spec, when the user says 'plan this', or when an accepted spec has no plan. Invoke manually: /flow:plan <spec-id> [<spec-id>...]"
argument-hint: "<spec-id> [more spec ids] [extra context]"
disable-model-invocation: true
---

# Plan the work

Input: $ARGUMENTS

Read the spec(s) first. If any is not `accepted`, stop and say which; the user can run `/flow:spec` to finish it. Do not plan against a draft.

## Steps

1. **Enter plan mode.** Use `EnterPlanMode`. Exploration and design happen there; nothing is written until the user approves.
2. **Explore.** Find the code the spec touches, the tests that exist for it, the test runner and lint commands (read the project `CLAUDE.md` and package manifest). Delegate wide reads to the explorer role and keep only the conclusions.
3. **Regression gate.** Judge the existing test coverage of the behaviour this change will alter. If it is thin, Phase 0 backfills tests that pin current behaviour before anything changes. This is not TDD for the new behaviour; it is insurance for the old. Skip Phase 0 only when coverage is already adequate or the code is being deleted, and say which.
4. **Design the phases.** Use the template below. Each phase is independently committable and leaves the suite green. Each test task names the scenario it covers. Prefer more unit tests and fewer end-to-end tests where both give the same confidence.
5. **Route the work.** For each phase, note which orchestration role should do it (executor; executor escalated where decisions remain; lead for design or judgement). This is a suggestion `/flow:implement` follows.
6. **Present via `ExitPlanMode`.** On approval, write `plans/<slug>.md`, then stop. Do not implement. Tell the user to run `/flow:implement <slug>`.

## Plan template

```markdown
# <Title>

Specs: auth/sign-in, auth/lockout
Branch: feat/sign-in-lockout
Created: 2026-09-15

## State
- Current phase: 0
- Gates passed: none
- Updated: 2026-09-15

## Phase 0: Regression backfill (skip if coverage is adequate: say why)
- [ ] test: pins current sign-in redirect behaviour (`reg` commit)
Gate: suite green, commit `reg(auth): pin existing sign-in behaviour`

## Phase 1: Red
- [ ] test: auth/sign-in#valid-credentials
- [ ] test: auth/sign-in#wrong-password
- [ ] test: auth/lockout#sixth-attempt-refused
Gate: new tests fail for the right reason, existing tests green, commit `test(auth): specify sign-in and lockout`

## Phase 2: Green
Route: executor
- [ ] minimum implementation to pass Phase 1 tests
Gate: full suite green, lint green, commit `feat(auth): implement sign-in lockout`

## Phase 3: Refactor
- [ ] remove duplication introduced in Phase 2; no behaviour change
Gate: suite green, commit `refactor(auth): ...` (omit the phase if nothing to do)

## Phase 4: Document
- [ ] set spec status to implemented
- [ ] /flow:guide auth (every area whose specs changed status or were amended)
Gate: commit `docs(auth): guide for sign-in lockout`, so the review sees the status change and the guide

## Phase 5: Verify
- [ ] full suite, lint, type check
- [ ] manual check: <what the user should click through, if anything>
- [ ] /flow:review
- [ ] delete this plan file
Gate: commit `chore(auth): complete sign-in lockout`

## Deviations
Record here anything that departed from the plan or the spec, with the reason. If the spec itself is wrong, stop and amend it with /flow:spec before continuing.
```

## Rules

- Tests are named for scenarios, never for implementation units, so the plan reads as a checklist against the spec.
- A phase with no test task is suspect. Documentation and pure-refactor phases are the exception; say so.
- Keep the plan short. It is a checklist, not a design document. Design rationale goes in the plan-mode discussion and the commit messages.
- The Document phase always names the areas for `/flow:guide`. A plan that delivers no spec (a pure refactor or documentation change) omits the phase and says why.
- The plan is committed with the Phase 1 commit at the latest, so it is resumable from another session or device.
