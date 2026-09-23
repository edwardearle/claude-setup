# Spec format

Path: `specs/<area>/<slug>.md`. The spec ID is `<area>/<slug>`. Areas are short nouns for a part of the product (`auth`, `billing`, `search`, `mobile`); slugs describe one behaviour (`sign-in`, `monthly-credit-reset`).

`specs/<area>/README.md` is the area guide, never a spec. It summarises the area's implemented behaviour by journey and is written by `/flow:guide`.

```markdown
---
status: draft            # draft | accepted | implemented | superseded
created: 2026-09-15
supersedes:              # optional: spec id this replaces
aliases:                 # optional: legacy IDs, e.g. [SPEC-AUTH-007]
---

# Sign in with email and password

## Context
Why this behaviour exists and who it is for. Two to four sentences. Link the issue that prompted it if there is one.

## Scenarios

### valid-credentials
- Given a registered user on the sign-in screen
- When they submit their email and correct password
- Then they are taken to their home screen
- And a session persists across a page reload

### wrong-password
- Given a registered user on the sign-in screen
- When they submit their email and an incorrect password
- Then a generic "check your details" message is shown
- And the message does not reveal whether the email is registered

### lockout
- Given a user has failed to sign in five times within ten minutes
- When they attempt a sixth time
- Then the attempt is refused for fifteen minutes regardless of password
- And the user is told when they can retry

## Constraints
Non-functional requirements that tests should assert or reviewers should check: response time, accessibility, data handling, platform parity.

## Out of scope
Adjacent behaviour deliberately not covered here, with the spec that covers it if one exists.

## Open questions
Anything unresolved. The spec cannot be `accepted` while this section is non-empty.
```

## Status lifecycle

| Status | Meaning | Set by |
|--------|---------|--------|
| `draft` | Being written; open questions remain | `/flow:spec` |
| `accepted` | User agreed this is the behaviour; may be planned | `/flow:spec` on approval |
| `implemented` | Tests reference every scenario and pass on the default branch | `/flow:implement` in the plan's Document phase |
| `superseded` | Replaced by another spec named in that spec's `supersedes` | `/flow:spec` when writing the replacement |

## Scenario naming

Scenario names are permanent identifiers. Tests reference them as `<spec-id>#<scenario>`, and in JS/TS as the prefix of the `it` title: `it('wrong-password: shows a generic message', ...)`. Name the situation, not the outcome, so the name survives a change to the expected result.

## Test reference shapes

| Stack | Spec reference | Scenario reference |
|-------|----------------|--------------------|
| Vitest / Jest / Playwright | `describe('auth/sign-in', ...)` | `it('wrong-password: ...', ...)` |
| xUnit / NUnit | `[Trait("Spec", "auth/sign-in")]` on the class | `[Trait("Scenario", "wrong-password")]` or method name `WrongPassword_...` |
| pytest | `pytestmark = pytest.mark.spec("auth/sign-in")` or class name | `def test_wrong_password_...` |
| Go | `func TestAuthSignIn(t *testing.T)` with `t.Run("wrong-password", ...)` | subtest name |

Whatever the stack, the spec ID appears as a literal string so `/flow:spec-audit` can find it with a plain search.
