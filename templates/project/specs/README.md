# Specs

One behaviour per file: `specs/<area>/<slug>.md`. The spec ID is the path without the extension (`auth/sign-in`). Scenarios inside a spec have stable kebab-case names; tests reference them as `<spec-id>#<scenario>` and carry the spec ID as a literal string in the test title.

Lifecycle: `draft` -> `accepted` -> `implemented` -> `superseded`.

Create or amend a spec with `/flow:spec`. See coverage with `/flow:spec-audit`. Coverage is derived from test references; nothing here is maintained by hand.
