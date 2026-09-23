# Readiness checklist

An issue is ready when every item below is `ready`, or `deferred` with a reason the user has agreed. `gap` on any item means not ready. The design section's `Readiness:` line is `ready` or `not ready`, nothing else; a deferred item is marked where it appears, with its reason.

| Item | Ready when |
|------|------------|
| **Problem** | It says who has the problem, what it costs them today, and why it matters now. |
| **Outcome** | It says what is true when the work is done and how anyone would tell, in terms a user or operator would recognise. Not "implement X". |
| **Scope** | What is in, what is out, and what is adjacent and deliberately left alone. |
| **Approach** | Which parts of the system change, at the level of components and boundaries. Any new external call, new service, schema change, or auth change is named. Where there was a real choice, the options and the reason for this one. |
| **Interface** | For user-facing work: the design exists, uses the design system, and covers the states below. For work with no user-facing change: say so, and the item is ready. |
| **Constraints** | Non-functional requirements that will become spec constraints: performance, accessibility, data handling, compatibility, platform parity. "None beyond the project's usual" is a valid answer if said explicitly. |
| **Unknowns** | Anything that must be learned before it can be specced has a spike with a question and a time box, or has been resolved. |
| **Size** | The breakdown below has been applied and the slices named. |

## Interface design

**Where the design system lives.** Read the project `CLAUDE.md` for a `Design system:` line. It names one or more of: a Figma library or file, a Claude design project, a component library in the repository (a package, a Storybook, a tokens file). If there is no line, look for Figma links in the README and the issue, then for tokens, Storybook or a components directory in the tree. Failing both, ask once, and offer to add the line to `CLAUDE.md` so the next run does not ask.

**Reading a design.**

- Figma links: use the Figma connector (`get_design_context`, `get_screenshot`, `search_design_system`) if it is connected. Otherwise ask the user for an export.
- Claude design: use the design tools if connected, otherwise ask for a link or export.
- Code-side design systems: read the component inventory and tokens with an `Explore` agent.

**Judging a design.** Check for each screen or flow in scope:

- Every element is an existing design system component, or is explicitly marked as new.
- Empty, loading, error and permission-denied states exist where they can occur.
- Behaviour at narrow and wide widths is shown, or the design says the work is fixed-width.
- Accessibility: keyboard order, focus, contrast, and text alternatives for non-text content are addressed or delegated to the design system.
- Copy is final. Scenarios quote copy, so placeholder text is a gap.

**No design is not automatically a gap.** A change that only rearranges existing components can be ready on the strength of one sentence naming them and where they go. A new screen, a new flow, or a new component without a design is a gap.

## Breakdown

Work breaks down at two levels, for different reasons.

- **By deliverable, here.** A slice is a piece that ships in one pull request and leaves the product coherent. Several slices of one design stay on one issue as a numbered list. When the parts are independently valuable, or each needs its own design decisions, the issue is an outcome: each part becomes a sub-issue, and each sub-issue goes through this skill on its own. The parent keeps the problem and outcome and links its children.
- **By behaviour, in `/flow:spec`.** Each slice lists the specs it expects to write or amend (`specs/<area>/<slug>.md`, about eight scenarios at most each). Specs never get their own issues: spec IDs are the traceability, and an issue per spec would duplicate the specs directory and drift.

## The design section

The skill owns one section at the end of the issue body, between markers, and replaces it on every pass. Everything above the opening marker belongs to the author and is left alone.

```markdown
<!-- flow:design -->
## Design

Readiness: ready | not ready (2 gaps)
Assessed: 2026-09-23

**Problem.** ...
**Outcome.** ...
**Scope.** In: ... Out: ... Left alone: ...
**Approach.** ...
**Interface.** <link to design> ... or "No user-facing change."
**Constraints.** ...
**Unknowns.** ...

### Slices
1. <name>: specs `auth/sign-in` (amend), `auth/lockout` (new)
2. <name>: specs ...

### Sources
- <proposal document, Figma file, prior discussion>
<!-- /flow:design -->
```

For an outcome, `### Slices` becomes `### Sub-issues` with a link to each child.

This section is what `/flow:pickup` and `/flow:spec` read. It is the current design; the comments are how it got there.

## The pass comment

Each assessment posts one comment, so the issue carries the history of decisions that the body section does not:

```markdown
**Design readiness: not ready** (pass 2)

| Item | State | Note |
|------|-------|------|
| Problem | ready | |
| Interface | gap | No design for the empty state; copy for the error banner is placeholder |
| ... | | |

Decided this pass:
- <decision and who made it>

Still open:
- <question, and who can answer it>
```
