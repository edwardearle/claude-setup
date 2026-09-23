# Specs

One behaviour per file: `specs/<area>/<slug>.md`. The spec ID is the path without the extension (`auth/sign-in`). Scenarios inside a spec have stable kebab-case names; tests reference them as `<spec-id>#<scenario>` and carry the spec ID as a literal string in the test title.

Lifecycle: `draft` -> `accepted` -> `implemented` -> `superseded`.

Each area has a guide at `specs/<area>/README.md`: what the area does today, journey by journey, linked to the scenarios behind it. Guides describe only implemented behaviour and are updated by `/flow:guide` when a plan finishes.

Create or amend a spec with `/flow:spec`. See coverage, and guides that have fallen behind their specs, with `/flow:spec-audit`. Coverage is derived from test references; nothing here is maintained by hand.
