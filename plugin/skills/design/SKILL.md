---
name: design
description: "Assess whether an issue or idea has enough high-level design to be specced, and work with the user to close the gaps: problem, outcome, scope, approach, interface design, constraints, unknowns and size. Breaks large work into sub-issues. Records the design on the issue. Use before /flow:spec when work starts from an issue or a loose request. Invoke manually: /flow:design <issue number | description>"
argument-hint: "<issue number, or a description of the work>"
disable-model-invocation: true
---

# Design readiness

Input: $ARGUMENTS

High-level design is what a piece of work must settle before its behaviour can be specced: why it exists, what done looks like, where its edges are, and roughly how it fits the system. Specs and plans are the low-level design and come after. This skill judges readiness against the checklist in [READINESS.md](READINESS.md), helps the user close the gaps, and records the result on the issue. It does not write specs.

Design that happened before Claude was involved (a proposal document, a Figma file, a whiteboard) is accepted, not redone. Find it, read it, judge it against the checklist, and link it.

## Steps

1. **Read the input.** For an issue: `gh issue view <N> --comments`, and any parent or sub-issues. Comments may supersede the body. For a description: treat it as the body of an issue that does not exist yet.
2. **Read the current state.** Find the areas under `specs/` the work touches and read their guides (`specs/<area>/README.md`). The guide is what the system does today; the design only needs to describe the difference. Where there is no guide, survey the relevant code and specs with an `Explore` agent and keep the conclusions.
3. **Find existing design.** Links in the issue and its comments, the project `CLAUDE.md` `Design system` line, and for user-facing work the design files named there. See READINESS.md for how to read each source.
4. **Assess.** Mark each checklist item `ready`, `gap` or `deferred` (with the reason). One line of evidence per item. Do not pad a thin issue with invented detail: an assumption you make is a gap until the user confirms it.
5. **Decide the size.** Using the breakdown rules in READINESS.md: one slice, several slices of one design, or an outcome whose parts each need their own design.
6. **Close the gaps with the user.** Put every open question into one `AskUserQuestion` call with concrete options. Repeat only if the answers open new questions that change the shape of the work.
7. **Record.** Write the design section and the pass comment (formats in READINESS.md). Show both to the user and post only on their approval. For an outcome, propose the sub-issues as a list first, then create and link them on approval. If the project uses a board and the design is ready, move the issue to Ready.
8. **Hand over.** Ready: give the next command, `/flow:pickup <N>` if the project uses a board, otherwise one `/flow:spec` line per spec in the first slice. Not ready: say what is missing and who can answer it. Do not start a spec.

## When nobody can answer

If you cannot ask the user (running headless, or `AskUserQuestion` is unavailable), do steps 1 to 5, post the pass comment listing the gaps as questions, and stop. Do not edit the issue body, create sub-issues or change board status unattended. Not ready is a normal result; building from a thin issue is the failure this skill exists to prevent.

## Tracker operations

GitHub through `gh`:

| Operation | Command |
|-----------|---------|
| Read | `gh issue view <N> --comments`, or `gh issue view <N> --json number,title,body,labels,url,comments` for structured output |
| Update the body | Re-read the body immediately before writing, since `--body-file` replaces all of it and an edit made since the first read would be lost. Write the new body to the scratchpad, then `gh issue edit <N> --body-file <path>` |
| Comment | `gh issue comment <N> --body-file <path>` |
| Create a sub-issue | `gh issue create --title ... --body-file <path>`, then link it: `gh api repos/{owner}/{repo}/issues/<parent>/sub_issues -F sub_issue_id=$(gh api repos/{owner}/{repo}/issues/<child> --jq .id)` |
| Board status | The `github-projects-v2` skill's `set-status.sh` if it is installed. Otherwise leave status to the user and say so |

Another tracker (Azure DevOps, Jira) works the same way if its tools are connected: read, update the description, comment, create child items. If they are not, write the section and comment to the scratchpad and give the user the path.

## Rules

- Never overwrite the issue author's text. The skill owns only the text between its markers.
- Every tracker write is shown to the user before it is posted, except the unattended comment above. The permission allowlist lets `gh issue edit`, `gh issue comment`, `gh issue create` and `gh api` run without a prompt, so this approval step is the only check.
- Bugs with a reproduction and an agreed expected result skip this skill: the expected result is the design. Say so and go to `/flow:spec`.
- Write nothing to the repository. The design lives on the issue; the repository gets specs once the design is ready.
