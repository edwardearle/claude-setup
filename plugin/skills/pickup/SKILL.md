---
name: pickup
description: "Take a tracker issue from the board through design readiness, the spec -> plan -> implement -> review workflow, and a PR, keeping the board status current. Invoke manually: /flow:pickup [issue number]"
argument-hint: "[issue number]"
disable-model-invocation: true
---

# Pick up an issue

Issue: $ARGUMENTS

This skill is the glue between the issue tracker and the flow workflow. It owns picking, branching and board status. It does not assess design or write specs, plans or code: those belong to `/flow:design`, `/flow:spec`, `/flow:plan` and `/flow:implement`, which only the user can start. At each hand-off, stop and give the user the exact command to type.

## Board operations

If the `github-projects-v2` skill is installed, use its scripts (`show-board.sh`, `set-status.sh`). If it is not, do not guess at `gh project` field ids: ask the user how status is tracked, or leave status to them, and say so. Columns are **New -> Ready -> In Progress -> Done**. An item is Ready when its design section says `Readiness: ready`; `/flow:design` moves it there. A New item has not been assessed. Anything an automated refinement left on a New item (Expected/Actual, a draft spec, Assumptions/Unknowns) is input to `/flow:design`, not a substitute for it.

## The design section

`/flow:design` writes a design section at the end of the issue body, between `<!-- flow:design -->` markers: readiness, problem, outcome, scope, approach, interface, constraints, and the slices with the spec ids each will write or amend. Every later stage reads the issue first and keys off that section, because a spec file does not name its issue and a plan names its specs, not its issue. The pass comments beneath record how the design got there.

## Work out where the issue is

Read the issue with its comments, `git fetch`, and look for the branch locally and on the remote. Then find the first row that matches and enter there. State the stage in one line so the user can correct you.

| Evidence | Stage | Next |
|---|---|---|
| No design section, or it says not ready, and the issue is not a bug with a reproduction and an agreed expected result | Design | Step 1, then step 2 |
| Issue is an outcome with sub-issues | Outcome | Pick a sub-issue; each goes through this table on its own |
| Design ready, or a bug with a reproduction and an agreed expected result; no branch locally or on the remote | Claim | Step 3, then the `/flow:spec` lines for the current slice |
| Branch exists; a spec id in the current slice has no file, or its file is `draft` | Speccing | `/flow:spec <id>` for each such id |
| Every spec in the current slice is `accepted`; no plan names them | Ready to plan | `/flow:plan <spec ids>` |
| A plan naming them exists on the branch | Implementing | `/flow:implement <slug>` |
| That plan has been deleted on the branch (its last phase ran) and no PR is open | Ready for PR | Step 5 |
| PR open | In review | Report the PR state; nothing to do here |
| PR merged; slices remain | Next slice | Step 3 for the next slice, from the default branch |
| PR merged; no slices remain | Done | Step 6 |

The **current slice** is the first slice in the design section with a spec not yet `implemented`; for a bug with no design section, it is the bug itself. Rows are evaluated for that slice only. An issue already In Progress on the board with no branch anywhere was claimed elsewhere or its branch was deleted after a slice merged: say which and continue with the row that matches.

## Steps

### 1. Pick

With no issue number: show the board, present Ready items as the primary picks (New as a fallback, flagged as not yet assessed: picking one leads to `/flow:design`), exclude In Progress and Done, and ask which. Stop and wait.

With an issue number, or once chosen:

```
gh issue view <N> --comments
```

Read the comments: decisions and later corrections live there and may supersede the body.

### 2. Design

A bug with a reproduction and an agreed expected result needs no design: its expected result is the design, and it has a single slice. Go to step 3. Otherwise, if the issue has no design section, or it says not ready, stop and hand over `/flow:design <N>`. Do not claim the issue or branch until the design is ready: an unready issue claimed on the board blocks anyone else from shaping it.

### 3. Branch and claim

Branch fresh from the latest default branch. If the working tree is dirty, stop and ask; never stash or discard on the user's behalf.

```
git fetch origin
DEFAULT=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
git checkout -b <type>/<slug> origin/$DEFAULT
```

`<slug>` names the behaviour, per the source-control rules. For a sliced issue, one branch per slice. Then move the issue to In Progress if it is not already.

Then hand over: one `/flow:spec` line per spec in the current slice, in dependency order, each naming the issue and the part of the design section it covers.

### 4. Spec, plan, implement

These stages are the user's to start. When re-entered at one of them, do the stage check above and give the single next command. Do not imitate those skills' steps here. Review is the plan's final phase, run by `/flow:implement`; do not run it again from here.

### 5. Open the PR

Only when the user asks. Push the branch and open the PR against the default branch. The body names the specs delivered, carries the `Docs:` line from the plan's review phase, and closes the issue only if this is the last slice:

```
gh pr create --title "<conventional title>" --body "<Closes | Part of> #<N>

Specs: <spec ids>
Docs: <outcome of the documentation review>"
```

Surface the PR URL. The issue stays In Progress: review may reject it.

### 6. Done

After the last PR merges, and only then, move the issue to Done. A parent outcome is Done when its last sub-issue is; say so rather than moving it when one child finishes.
