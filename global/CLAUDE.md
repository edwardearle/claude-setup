# Working preferences

These apply in every project. A project's own `CLAUDE.md` adds stack-specific detail (commands, layout, hard rules unique to that codebase) and must not repeat anything here.

## How to work with me

- Concise, direct prose. UK English. No preamble, no filler, no industry buzzwords.
- Explain in plain terms. Do not assume specialist knowledge of the language, framework or service in hand. Spell out an acronym or term of art the first time it appears in a conversation, or choose an ordinary word instead.
- Where explaining something properly would make the answer long-winded, give the plain-terms version and offer to go deeper, rather than leaving it out or burying the answer in detail.
- Make routine judgement calls yourself. Ask only when different readings of the request would produce materially different work, and when you do ask, ask once with concrete options.
- Report faithfully: what you did, what you verified, what you did not do. If tests failed, show the output. If you could not run something, say so and give the exact command.
- If any part of this configuration is slowing you down, wasting tokens, or producing worse results, say so. Follow it anyway, but flag it.

## Default workflow: spec, then tests, then code

Non-trivial work follows **spec -> plan -> implement -> review**, driven by the `flow` plugin:

| Step | Skill | Produces |
|------|-------|----------|
| Agree what the behaviour is | `/flow:spec` | `specs/<area>/<slug>.md`, status `accepted` |
| Decide how to build it | `/flow:plan` | `plans/<slug>.md`, phased, tests first |
| Build it | `/flow:implement` | One commit per phase, tests before code |
| Check it independently | `/flow:review` | Findings from a different model |
| See what is uncovered | `/flow:spec-audit` | Coverage derived from test references |

Trivial changes (a typo, a rename, a one-line fix whose test is obvious) skip the workflow. Say so in one line and carry on.

Never write implementation code before a failing test exists for the behaviour. If you are about to, stop and write the test.

@rules/workflow.md

## Model orchestration

@rules/orchestration.md

## Source control

@rules/source-control.md

## Code style

@rules/code-style.md

## Platform

Rules for the operating system this machine runs are imported separately from `global/platform/`, selected by `bootstrap` at install time. Only the file for the current platform is loaded.
