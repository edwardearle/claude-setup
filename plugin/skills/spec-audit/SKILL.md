---
name: spec-audit
description: "Derive spec coverage from test references: which specs have tests, which scenarios are uncovered, which tests reference specs that do not exist, and which specs are stuck in draft. Read-only. Use when asked about coverage, gaps, what is untested, or before marking a spec implemented. Invoke manually: /flow:spec-audit [area]"
argument-hint: "[area to limit the audit to]"
---

# Spec coverage audit

Scope: $ARGUMENTS (default: all of `specs/`)

Coverage is derived, never recorded by hand. This skill writes nothing unless the user asks for the report to be saved.

## Steps

1. **Inventory specs.** Glob `specs/**/*.md` (excluding `README.md` and `MIGRATION-MAP.md`). For each: spec ID from the path, `status` and `aliases` from frontmatter, scenario names from `### ` headings under `## Scenarios`.
2. **Find references.** Identify test directories from the project `CLAUDE.md` or by convention (`__tests__`, `*.test.*`, `*.spec.*`, `e2e/`, `tests/`, `*Tests/`). For each spec ID and each alias, Grep for the literal string. For each scenario, Grep for `<scenario>:` within files that reference the parent spec.
3. **Find orphans.** Grep test directories for anything shaped like a spec reference (`describe('<word>/<word>`, `Trait("Spec"`, legacy `SPEC-[A-Z]+-[0-9]+`) and check each resolves to a spec file or an alias.
4. **Report.**

```markdown
## Coverage: <area or all>

| Spec | Status | Test files | Scenarios covered | Note |
|------|--------|-----------:|------------------:|------|
| auth/sign-in | implemented | 3 | 4/4 | |
| auth/lockout | accepted | 0 | 0/3 | no tests; run /flow:plan |
| billing/refund | implemented | 1 | 1/5 | marked implemented but 4 scenarios untested |

### Needs attention
- Implemented specs with uncovered scenarios: ...
- Accepted specs with no tests: ...
- Tests referencing unknown specs: `<file>:<line>` -> `<reference>`
- Drafts older than 30 days: ...
```

5. Suggest next actions, one line each. Do not create specs, tests or plans from this skill.

## Rules

- Scenario coverage is by name prefix in the test title. `it('handles wrong password')` does not count for `wrong-password`; report it as a naming fix.
- Delegate the grepping to the `flow:spec-checker` agent when the project has more than a few dozen test files, and keep only the table.
- If a project has a hand-maintained coverage document, compare it and list the claims this audit cannot substantiate. That is the argument for deleting the document.
