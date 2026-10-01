---
name: review
description: "Independent review of the current branch's changes against their specs by a model that did not write the code, sized to the change: one Claude reviewer for a small change, Codex plus a Claude reviewer for a meaningful one. Use before a PR, at the end of /flow:implement, or whenever the user asks for a review or second opinion. Invoke manually: /flow:review [base-branch]"
argument-hint: "[base branch, default main]"
---

# Independent review

Base: $ARGUMENTS (default `main`)

## Steps

1. **Scope the change.** `git diff <base>...HEAD --stat`, with the full diff saved to the scratchpad. Read `plans/*.md` for the specs in play; otherwise take spec IDs from commit bodies and test titles in the diff.
2. **Size the change.** Total the added and deleted lines from `git diff <base>...HEAD --numstat`, skipping the lockfiles, generated files and binary files (shown as `-`) the orchestration rules exclude, and read the issue's design section, if there is one, for risk flags. Classify the change as small or meaningful by those rules, and state the class and the count in one line.
3. **Pick the reviewers.** Take the reviewer and cross-family reviewer roles' models for this session's model and the change's size. Launch the `flow:reviewer` agent with the reviewer's `model`, giving it: the base ref, the spec file paths, the plan path, and the test command. It produces the diff itself.
   For a meaningful change with `codex` on PATH, in the same message launch the cross-family reviewer's wrapper agent, which writes a self-contained brief (spec text, diff path, what to look for), runs `codex exec -s read-only` with the role's model pinned, and returns findings in the same shape. A small change gets no cross-family review.
   If Codex stops on a usage limit or exhausted credits, retry once with `codex exec --profile api -s read-only`, which bills the OpenAI API rather than the plan, and say so in the report. If the retry fails too, say so, apply the reviewer role's fallback, and report both Claude reviews; never drop the cross-family review silently.
4. **Documentation.** In the same message, launch the `flow:docs-checker` agent with the base ref and the spec areas the diff touches. It reads the README, every document it links, and those areas' guides, and reports broken paths, statements the diff made untrue, and additions the docs do not mention. This step is not optional: a PR to `main` cannot be opened until its findings are fixed or accepted.
5. **Verify before reporting.** For each finding, open the code and confirm it. Drop anything you cannot reproduce or that the reviewer misread. Reviewers get line numbers wrong and invent APIs; you are the filter.
6. **Report**, most severe first:
   - **Blocker**: incorrect behaviour, a spec scenario with no test, a test that passes for the wrong reason, a security issue.
   - **Should fix**: missing edge case, misleading name, duplicated logic, a test coupled to implementation.
   - **Nit**: style. Keep these to three.
   Then **spec drift**: behaviour in the diff no spec describes, and spec scenarios the diff should have covered but did not.
   Then **docs**: the checker's Broken, Stale and Missing items, verified. Broken and Stale are Should fix; Missing is Should fix when a new engineer would need it, otherwise a Nit. End with the one-line `Docs:` statement for the PR body.
   Each finding: `file:line`, one sentence, the failing input or state.
7. Offer to fix blockers. Do not fix anything without being asked. Documentation fixes are prose: hand them to the prose writer role with the checker's findings and the recipe in `/flow:readme`. Guide fixes go through `/flow:guide`.

## Rules

- Never review your own diff alone. If no other model is available, say so and give the user the brief to run elsewhere.
- Findings from two reviewers that disagree are reported as a disagreement; do not silently pick one.
- Do not restate the diff. The user has it.
