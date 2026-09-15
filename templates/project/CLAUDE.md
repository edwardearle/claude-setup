# <Project name>

<One sentence: what it is and who it is for.>

Global working preferences and the spec -> plan -> implement -> review workflow are loaded from user-level configuration. Do not restate them here; this file holds only what is specific to this codebase.

## Stack

- <Language, framework, runtime version>
- <Data store, hosting, anything with operational consequences>

## Commands

| Purpose | Command |
|---------|---------|
| Unit tests | `npm test` |
| End-to-end tests | `npm run test:e2e` |
| Lint | `npm run lint` |
| Type check | `npx tsc --noEmit` |
| Build | `npm run build` |
| Run locally | `npm run dev` |

## Layout

- `specs/` behaviour specs, one per file; see `specs/README.md`
- `plans/` in-flight implementation plans (deleted on merge)
- `src/` ...
- `e2e/` ...

## Project rules

Hard rules unique to this codebase. Anything the global rules already cover does not belong here.

- <e.g. Schema changes go through `db/migrations/`, never by editing `schema.sql`>
- <e.g. Every user-visible change ships to the mobile wrapper: see `/release-mobile`>

## Procedures

Multi-step procedures live as project skills under `.claude/skills/` so they load only when needed:

- `/release-mobile` - <one line>
