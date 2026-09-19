---
name: pickup
description: "Take a tracker issue from the board through refinement, the spec -> plan -> implement -> review workflow, and a PR, keeping the board status current. Use when the user says 'pick up #N', 'what should I work on', or 'take the next issue'. Invoke manually: /flow:pickup [issue number]"
argument-hint: "[issue number]"
---

# Pick up an issue

Issue: $ARGUMENTS

This skill is the glue between the issue tracker and the flow workflow. It owns picking, refining, branching and board status. It does not write specs, plans or code: those belong to `/flow:spec`, `/flow:plan` and `/flow:implement`, which only the user can start. At each hand-off, stop and give the user the exact command to type.

## Board operations

If the `github-projects-v2` skill is installed, use its scripts (`show-board.sh`, `set-status.sh`). Otherwise use `gh issue` and `gh project item-edit` directly and say so. Columns are **New -> Ready -> In Progress -> Done**. Ready items were refined by the issue-refinement bot and are the recommended picks; New items need a heavier refinement step.

## Work out where the issue is

Before doing anything, find the issue's current stage and enter there. State the stage in one line so the user can correct you.

| Evidence | Stage | Next |
|---|---|---|
| No branch, board New or Ready | Pick | Steps 1-3 |
| Branch exists, no `specs/` files reference the issue | Refined | Give the `/flow:spec` lines |
| Specs exist but some are `draft` | Speccing | Name the drafts; user runs `/flow:spec <id>` to finish them |
| Specs `accepted`, no `plans/<slug>.md` | Ready to plan | User runs `/flow:plan <spec-ids>` |
| Plan exists, unticked phases | Implementing | User runs `/flow:implement <slug>` |
| Plan fully ticked, no PR | Reviewing | Run `/flow:review`, then step 5 |
| PR merged | Done | Step 6 |

## Steps

### 1. Pick

With no issue number: show the board, present Ready items as the primary picks (New as a fallback, flagged as unrefined), exclude In Progress and Done, and ask which. Stop and wait.

With an issue number, or once chosen:

```
gh issue view <N> --comments
```

Read the comments: refinement notes, decisions and later corrections live there and may supersede the body.

### 2. Branch and claim

Always branch fresh from the latest default branch. If the working tree is dirty, stop and ask; never stash or discard on the user's behalf.

```
git fetch origin main
git checkout -b <type>/<N>-<short-slug> origin/main
```

Then move the issue to In Progress.

### 3. Refine

The aim is that every `/flow:spec` run that follows can be answered from the record rather than from the user's memory.

1. Restate the problem in a few lines.
2. Survey the code the issue touches with an `Explore` agent (Sonnet): what exists, what the issue collides with, what is missing. Keep only the conclusions.
3. Propose the spec split: `specs/<area>/<slug>.md`, one behaviour per file, at most about eight scenarios each, plus any existing specs that need amending. Group them into delivery slices if the issue is large; each slice is one plan and one PR.
4. Ask the scope questions that change the shape of the work in a single `AskUserQuestion`: slicing, anything that amends an existing spec, anything the survey showed to be new rather than reuse, security or data-model choices. Leave scenario-level detail for `/flow:spec` to ask per file.
5. Write the outcome (decisions, spec split, codebase facts, questions still open) as a comment on the issue. If that write is not permitted, save it to the scratchpad and give the user the path and the text to paste.

Then stop and hand over: one `/flow:spec` line per spec file, in dependency order, each naming the issue, the section of the issue body it covers, and the refinement record. Say which slice each belongs to.

### 4. Spec, plan, implement

These stages are the user's to start. When re-entered at one of them, do the stage check above and give the single next command. Do not imitate those skills' steps here.

### 5. Review and PR

When the plan is fully ticked, run `/flow:review`. Once findings are addressed and the user asks, push and open the PR:

```
gh pr create --title "<conventional title>" --body "Closes #<N> ..."
```

The body names the specs delivered and the slice, if any. Surface the PR URL. The issue stays In Progress: review may reject it.

### 6. Done

After the PR merges, and only then, move the issue to Done. If the issue was sliced, it stays In Progress until the final slice merges; the PR bodies for earlier slices use "Part of #<N>" rather than "Closes #<N>".

## Rules

- Never commit, push or open a PR without being asked.
- Never write specs, plans or code from this skill. Hand over to the flow skill that owns the stage.
- One question round per stage. Batch, do not drip.
