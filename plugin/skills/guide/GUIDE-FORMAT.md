# Guide format

Path: `specs/<area>/README.md`, one per area. `README.md` is never a spec: tooling that inventories specs skips it. GitHub shows it when someone opens the area's folder.

Audience: anyone who needs to know what this part of the product does today without reading every spec. A new team member, a designer planning a change, a support engineer, `/flow:design` working out the gap between today and the proposal.

```markdown
# Sign-in and accounts

People sign in with an email address and password, stay signed in across visits, and recover access when they forget their password. Accounts are created by an administrator; there is no self-registration.

## Journeys

### sign-in
A registered user signs in from the sign-in screen.

1. They enter their email and password.
2. On success they land on their home screen and stay signed in until they sign out or thirty days pass.
3. On a wrong password they see a generic message that does not reveal whether the email is registered.

Specs: [auth/sign-in#valid-credentials](sign-in.md#valid-credentials), [auth/sign-in#wrong-password](sign-in.md#wrong-password)

### recover-password
...

## Rules and limits

- Five failed attempts in ten minutes lock sign-in for fifteen minutes. ([auth/lockout#lockout](lockout.md#lockout))
- Sessions last thirty days. ([auth/session#expiry](session.md#expiry))

## Not supported

- Signing in with a third-party identity provider.

## Related areas

- [Administration](../admin/README.md): creating accounts and resetting them on a user's behalf.
```

## Sections

| Section | Contents |
|---------|----------|
| Title and purpose | What the area lets people do and for whom. One paragraph. |
| Journeys | One `###` per journey, named in stable kebab-case for the situation (`sign-in`, `recover-password`). Who, their goal, numbered steps in plain language with what they see at each, then a `Specs:` line linking the scenarios. About ten lines each. |
| Rules and limits | Constraints a person will run into, each linked to the scenario or constraint that sets it. |
| Not supported | Things people might reasonably expect and will not find. Only firm answers; open ideas belong in the issue tracker. |
| Related areas | Links to neighbouring guides, one line each on what lives there. |

## Rules

- Only behaviour covered by an `implemented` spec. Planned work lives on its issue until it ships.
- Link scenarios as `[<spec-id>#<scenario>](<slug>.md#<scenario>)` so the links resolve on GitHub and `/flow:spec-audit` can find them with a plain search.
- Journey names are permanent once other guides or captures use them. Rename by adding the new journey and removing the old one in the same change, and fix the links.
- For an area with no user interface (an API, a background job), journeys are the jobs a caller or operator does: "request a refund", "rerun a failed import".
- UK English, plain words, no emoji, no marketing.
