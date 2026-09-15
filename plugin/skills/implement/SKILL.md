---
name: implement
description: "Execute an approved plan at plans/<slug>.md phase by phase: tests first, gate at each phase, commit on confirmation, keep the plan's checkboxes and state current. Use to start or resume implementation. Invoke manually: /flow:implement <slug>"
argument-hint: "<plan slug or path>"
disable-model-invocation: true
---

# Implement a plan

Plan: $ARGUMENTS

## Entry

1. Read the plan and every spec it names. Read the project `CLAUDE.md` for the test and lint commands.
2. Work out where you are from the checkboxes and the `## State` block, and from `git log` and `git status` if the plan is stale. **State the entry phase in one line before doing anything else** so the user can correct you.
3. Confirm you are on the plan's branch. If not, ask before switching or creating it.

## Each phase

1. Do the tasks in order, ticking each checkbox in the plan file as it completes.
2. **Red before green.** In a test phase, run the new tests and confirm they fail for the reason the scenario describes, not because of a typo or a missing import. In a code phase, write no line of implementation that a failing test does not demand.
3. Route the work as the plan suggests. Bulk mechanical phases go to a Codex or Sonnet agent with a self-contained brief: the spec text, the failing tests, the files to touch, the command that must go green. Judgement stays in this session.
4. Run the tests relevant to the phase as you go, and the full suite plus lint at the gate.
5. **Gate.** Update `## State`, then use `AskUserQuestion` with two options: commit and continue to the next phase, or stay in this phase. Commit only on the first. Stage paths by name. Commit body names the specs.
6. If you learn the spec is wrong, stop. Record it under `## Deviations`, and ask whether to amend the spec with `/flow:spec` before continuing. Do not quietly build something the spec does not describe.

## Finishing

- Phase 4 includes `/flow:review`. Address blockers before the final commit; list anything deliberately left.
- Set each spec's `status: implemented` once every scenario has a passing test that references it.
- Delete the plan file in the final commit. Say so; git history keeps it.
- Report: commits made, tests added (count and the scenarios they cover), anything not done and why.

## If tests cannot run here

Say so explicitly, give the exact commands, and wait for the user to confirm the result before passing a gate. Never assume green.
