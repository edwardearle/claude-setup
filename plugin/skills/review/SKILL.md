---
name: review
description: "Independent review of the current branch's changes against their specs by a model that did not write the code, with a second opinion from Codex when it is installed. Use before a PR, at the end of /flow:implement, or whenever the user asks for a review or second opinion. Invoke manually: /flow:review [base-branch]"
argument-hint: "[base branch, default main]"
---

# Independent review

Base: $ARGUMENTS (default `main`)

## Steps

1. **Scope the change.** `git diff <base>...HEAD --stat`, with the full diff saved to the scratchpad. Read `plans/*.md` for the specs in play; otherwise take spec IDs from commit bodies and test titles in the diff.
2. **Pick the reviewer.** It must be a different model from the one that wrote the code. If this session is Fable, use `opus`; if Opus, use `fable`; if Sonnet, use `opus`. Launch the `flow:reviewer` agent with that `model`, giving it: the base ref, the spec file paths, the plan path, and the test command. It produces the diff itself.
3. **Second opinion.** If `codex` is on PATH, in the same message launch a thin `sonnet` agent that writes a self-contained brief (spec text, diff path, what to look for), runs `codex exec -s read-only`, and returns findings in the same shape. If not, skip without comment.
   If Codex stops on a usage limit or exhausted credits, retry once with `codex exec --profile api -s read-only`, which bills the OpenAI API rather than the plan, and say so in the report. If the retry fails too, report the second opinion as unavailable; never drop it silently.
4. **Documentation.** In the same message, launch the `flow:docs-checker` agent with the base ref. It reads the README and every document it links and reports broken paths, statements the diff made untrue, and additions the docs do not mention. This step is not optional: a PR to `main` cannot be opened until its findings are fixed or accepted.
5. **Verify before reporting.** For each finding, open the code and confirm it. Drop anything you cannot reproduce or that the reviewer misread. Reviewers get line numbers wrong and invent APIs; you are the filter.
6. **Report**, most severe first:
   - **Blocker**: incorrect behaviour, a spec scenario with no test, a test that passes for the wrong reason, a security issue.
   - **Should fix**: missing edge case, misleading name, duplicated logic, a test coupled to implementation.
   - **Nit**: style. Keep these to three.
   Then **spec drift**: behaviour in the diff no spec describes, and spec scenarios the diff should have covered but did not.
   Then **docs**: the checker's Broken, Stale and Missing items, verified. Broken and Stale are Should fix; Missing is Should fix when a new engineer would need it, otherwise a Nit. End with the one-line `Docs:` statement for the PR body.
   Each finding: `file:line`, one sentence, the failing input or state.
7. Offer to fix blockers. Do not fix anything without being asked. Documentation fixes are prose: write them here if this session is Fable, otherwise hand them to a `fable` agent with the checker's findings and the recipe in `/flow:readme`.

## Rules

- Never review your own diff alone. If no other model is available, say so and give the user the brief to run elsewhere.
- Findings from two reviewers that disagree are reported as a disagreement; do not silently pick one.
- Do not restate the diff. The user has it.
