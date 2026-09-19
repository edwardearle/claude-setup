---
name: pickup
description: "Take a tracker issue from the board through refinement, the spec -> plan -> implement -> review workflow, and a PR, keeping the board status current. Invoke manually: /flow:pickup [issue number]"
argument-hint: "[issue number]"
disable-model-invocation: true
---

# Pick up an issue

Issue: $ARGUMENTS

This skill is the glue between the issue tracker and the flow workflow. It owns picking, refining, branching and board status. It does not write specs, plans or code: those belong to `/flow:spec`, `/flow:plan` and `/flow:implement`, which only the user can start. At each hand-off, stop and give the user the exact command to type.

## Board operations

If the `github-projects-v2` skill is installed, use its scripts (`show-board.sh`, `set-status.sh`). If it is not, do not guess at `gh project` field ids: ask the user how status is tracked, or leave status to them, and say so. Columns are **New -> Ready -> In Progress -> Done**. Ready items have been through automated refinement and carry Expected/Actual, a draft spec and Assumptions/Unknowns; New items have none of that, so step 3 will have more to establish and more to ask.

## The refinement record

Step 3 ends by writing a refinement record as a comment on the issue: the decisions, the spec ids to write (grouped into slices if the issue is large), and the codebase facts. Every later stage reads the issue's comments first and keys off that record, because a spec file does not name its issue and a plan names its specs, not its issue.

## Work out where the issue is

Read the issue with its comments, `git fetch`, and look for the branch locally and on the remote. Then find the first row that matches and enter there. State the stage in one line so the user can correct you.

| Evidence | Stage | Next |
|---|---|---|
| No refinement record on the issue | Pick | Steps 1-3 |
| Record exists; no branch locally or on the remote | Claim | Step 2, then the `/flow:spec` lines for the current slice |
| Branch exists; a spec id in the record has no file, or its file is `draft` | Speccing | `/flow:spec <id>` for each such id |
| Every spec in the current slice is `accepted`; no plan names them | Ready to plan | `/flow:plan <spec ids>` |
| A plan naming them exists on the branch | Implementing | `/flow:implement <slug>` |
| That plan has been deleted on the branch (its last phase ran) and no PR is open | Ready for PR | Step 5 |
| PR open | In review | Report the PR state; nothing to do here |
| PR merged; slices remain | Next slice | Step 2 for the next slice, from the default branch |
| PR merged; no slices remain | Done | Step 6 |

The **current slice** is the first slice in the record with a spec not yet `implemented`. Rows are evaluated for that slice only. An issue already In Progress on the board with no branch anywhere was claimed elsewhere or its branch was deleted after a slice merged: say which and continue with the row that matches.

## Steps

### 1. Pick

With no issue number: show the board, present Ready items as the primary picks (New as a fallback, flagged as unrefined), exclude In Progress and Done, and ask which. Stop and wait.

With an issue number, or once chosen:

```
gh issue view <N> --comments
```

Read the comments: refinement notes, decisions and later corrections live there and may supersede the body.

### 2. Branch and claim

Branch fresh from the latest default branch. If the working tree is dirty, stop and ask; never stash or discard on the user's behalf.

```
git fetch origin
DEFAULT=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
git checkout -b <type>/<slug> origin/$DEFAULT
```

`<slug>` names the behaviour, per the source-control rules. For a sliced issue, one branch per slice. Then move the issue to In Progress if it is not already.

### 3. Refine

The aim is that every `/flow:spec` run that follows can be answered from the record rather than from the user's memory.

1. Restate the problem in a few lines.
2. Survey the code the issue touches with an `Explore` agent: what exists, what the issue collides with, what is missing. Keep only the conclusions.
3. Propose the spec split: `specs/<area>/<slug>.md`, one behaviour per file, at most about eight scenarios each, plus any existing specs that need amending. Group them into delivery slices if the issue is large; each slice is one plan and one PR.
4. Ask the scope questions that change the shape of the work in a single `AskUserQuestion`: slicing, anything that amends an existing spec, anything the survey showed to be new rather than reuse, security or data-model choices. Leave scenario-level detail for `/flow:spec` to ask per file.
5. Write the refinement record as a comment on the issue. If that write is not permitted, save it to the scratchpad, give the user the path, and ask them to paste it; later stages depend on it being on the issue.

Then stop and hand over: one `/flow:spec` line per spec file in the first slice, in dependency order, each naming the issue, the part of the issue body it covers, and the refinement record.

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

After the last PR merges, and only then, move the issue to Done.
