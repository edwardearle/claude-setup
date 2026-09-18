---
name: readme
description: "Create, improve or check a repository README and the documents it links, following the recipe in RECIPE.md. Use when asked to write or improve a README, when a new repository has none, when documentation may have gone stale, or before a PR to main. Invoke manually: /flow:readme [check | <path>]"
argument-hint: "[check | path to README, default ./README.md]"
---

# README

Target: $ARGUMENTS (default `./README.md`; `check` runs the audit only)

The README is the front door to the repository. It is read most often by someone who has just cloned the code and needs to run it, and it is the one document that must never lie. The recipe in [RECIPE.md](RECIPE.md) says what belongs in it, in what order, and how to keep it true. Read that file before writing.

## Check

Run this alone for `check`, and as step 1 of the other modes when a README already exists.

1. Launch the `flow:docs-checker` agent with the base ref (`main`, or the ref the user gives). It follows every linked document and reports Broken, Stale, Missing and Unverifiable items.
2. Verify each finding against the tree before repeating it. Drop what the checker misread.
3. Score the README against the recipe's checklist: which required sections are present, which are missing, which are too long for the front door and should link out.
4. Report the verified findings and the score. Offer to fix; write nothing until asked.

## Create or improve

1. **Learn the repository.** Read the project `CLAUDE.md`, the manifest files (`package.json`, `*.csproj`, `pyproject.toml`, `Dockerfile`, `docker-compose*`, pipeline and workflow files, infrastructure directories), the top two levels of the tree, and any existing docs. Use a `sonnet` subagent when this means reading more than a handful of files, and keep only the facts: what the system is, who it serves, how it is run, tested, built, deployed and where it runs.
2. **Ask once.** Anything the tree cannot tell you (who owns the repo, where to get help, which environments exist and their addresses, what is out of scope) goes into a single `AskUserQuestion` call with concrete options. Leave a clearly marked placeholder for anything still unknown rather than inventing it.
3. **Write to the recipe.** Every section in its order. Every command, path, variable and name copied exactly from the source that defines it, never paraphrased, so that the checker can grep for it later. Anything over the length limits moves to `docs/<topic>.md` with a one-line summary and a link left in its place. Diagrams as Mermaid in the file, not images.
4. **Prose is this session's job only if it is Fable.** If this session is a cheaper model, hand the gathered facts and the recipe to a `fable` agent to write, then verify what comes back against the tree yourself.
5. **Check your own output** with the docs-checker before presenting it. A README with a broken path on day one has failed.
6. Present the result. Say what you could not determine and where the placeholders are.

## Rules

- Write only the README and files under `docs/` that it links. Do not touch code, tests or configuration to make the documentation true; report the mismatch instead.
- Never delete a section that holds information you cannot place elsewhere. Move it, link it, then delete.
- Do not add badges, images or a table of contents that the recipe does not call for.
- UK English, plain words, no emoji, no marketing.
