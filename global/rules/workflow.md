### Design

- High-level design comes first and may already exist: a proposal, a Figma file, an earlier discussion. `/flow:design` judges it against a readiness checklist and records the result on the issue rather than redoing it. Specs and plans are the low-level design.
- An issue that is not ready is not specced. Close the gaps with the user, or post them on the issue and stop.
- Breakdown happens twice. Design splits work by deliverable: slices on one issue when they share a design, sub-issues when each part needs its own. Specs split a slice by behaviour. Specs never get their own issues.

### Specs

- One behaviour per file: `specs/<area>/<slug>.md`. The spec ID is the path without extension, e.g. `auth/sign-in`. No sequential numbering, so no collisions and no renumbering.
- Each scenario inside a spec has a stable kebab-case name. A scenario ID is `<spec-id>#<scenario>`, e.g. `auth/sign-in#wrong-password`.
- Frontmatter carries `status` (`draft` -> `accepted` -> `implemented` -> `superseded`), `created`, and optional `supersedes` / `aliases`. Only `accepted` specs get planned; only `implemented` specs are done.
- Specs describe behaviour and constraints, never implementation. Given/When/Then as plain bullets, not Gherkin fences: the tests are the executable form.
- The format is defined in the `flow:spec` skill. Do not invent variants.

### Guides

- Each spec area has a guide at `specs/<area>/README.md`: what the area does today, by journey, linked to the scenarios behind it. Specs are the detailed as-is record; the guide is the readable one; the design on the issue is the gap, and closes with the issue.
- Guides are written at the end of a plan, from the final specs, never while speccing. `/flow:spec-audit` and `/flow:review` report guides that have fallen behind.

### Traceability

- Every test that covers a spec names the spec ID as a literal string in a greppable place: the `describe` title in JS/TS, the test class name or a `[Trait]` in .NET, a marker or the function name in Python. The JS/TS shape is `describe('auth/sign-in', ...)` with `it('wrong-password: shows a generic error', ...)`.
- Commit bodies name the specs they touch: `Implements auth/sign-in`, `Amends auth/sign-in#lockout`.
- Coverage is **derived** from those references by `/flow:spec-audit`. Never hand-maintain a coverage matrix or gap document; it drifts the day after it is written.

### Plans

- Plans live at `plans/<slug>.md` and are committed. They are the resumable record of in-flight work across sessions and devices.
- A plan names the specs it delivers and is split into phases. Phase 0 is regression backfill when the existing behaviour being touched is thinly tested. Then red, green, refactor, document, verify.
- Each phase ends at a gate: tests green, user confirms, commit. Never skip a phase silently.
- When the work merges, the plan file is deleted in the final commit. Git history keeps it.

### Backlog

Ideas and requests are not specs, even if they include a suggested spec, that is not to be taken as is, but rather a draft that serves as a starting point. Keep them in the project's issue tracker. Something becomes a spec when you decide to build it.

### Definition of done

Spec `implemented`; tests reference it; area guide updated; full suite and lint green; reviewed by a different model; README and the documents it links still true after the change; plan deleted; commits reference the spec.
