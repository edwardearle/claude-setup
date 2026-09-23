---
name: spec
description: "Write or amend a behaviour spec before anything is planned or coded. Use when the user describes a feature, a behaviour change, or a bug whose expected behaviour is not yet written down. Invoke manually: /flow:spec <what should happen>"
argument-hint: "<behaviour to specify, or an existing spec id to amend>"
disable-model-invocation: true
---

# Write a spec

Request: $ARGUMENTS

A spec answers "what should the system do, and how will we know?" It never answers "how is it built?". The output is one file per behaviour under `specs/`, in the format defined in [SPEC-FORMAT.md](SPEC-FORMAT.md). Read that file before writing.

## Steps

1. **Check there is a design behind it.** If the request names an issue, read its design section (`<!-- flow:design -->`); the slice's spec list is the starting point and its approach, interface and constraints bound what the spec may say. If there is no design, and the request is larger than one behaviour or changes what users see without an interface design, stop and suggest `/flow:design`. A bug with a reproduction and an agreed expected result needs no design.
2. **Find what exists.** Search `specs/` for related behaviour (Grep for key nouns, list the area directory). Decide whether this is a new spec, an amendment to an existing one, or a replacement (`supersedes`). Say which in one line.
3. **Learn the current behaviour.** Read the area guide (`specs/<area>/README.md`) if there is one, then enough code and tests to know what the system does today in this area. Use a subagent if it means reading more than a handful of files. Do not read the whole codebase.
4. **Draft.** Fill the template. Every scenario gets a stable kebab-case name that will appear in test titles, so name for the behaviour (`wrong-password`), not the outcome (`shows-error`). Cover the happy path, each failure mode, boundaries, and any non-functional constraint that matters (latency, accessibility, data retention). Note what is explicitly out of scope.
5. **Ask once.** Gather every question the draft raised and put them to the user in a single `AskUserQuestion` call with concrete options. Unanswered items go in `## Open questions`, and the spec stays `draft`.
6. **Present.** Show the spec. On approval set `status: accepted` and offer `/flow:plan <spec-id>`. Do not plan or implement in this skill.

## Rules

- One behaviour per file. If the draft has more than about eight scenarios, it is probably two specs.
- Plain-bullet Given/When/Then. No Gherkin fences, no `Feature:` blocks, no code.
- No implementation detail: no component names, table names, function names, library choices. Interface-level nouns the user would recognise are fine.
- Never change a scenario's name once a test references it. Add a new scenario and mark the old one superseded within the file if the behaviour changes.
- If amending an `implemented` spec, list the affected scenarios so the plan knows which tests must change.
- Write nothing outside `specs/`, and never the area guide: `/flow:guide` writes that once the spec is implemented. Do not touch tests, plans or code.
