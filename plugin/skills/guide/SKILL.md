---
name: guide
description: "Write or update the guide for a spec area (specs/<area>/README.md): a readable summary of what the area does today, organised by user journey and linked to the spec scenarios behind it. Use in the document phase of a plan, after specs in an area reach implemented or are amended, or when an area has implemented specs and no guide. Invoke manually: /flow:guide [area ...]"
argument-hint: "[area ...] (default: areas whose specs changed on this branch)"
---

# Area guide

Areas: $ARGUMENTS

Specs are the detailed record of what the system does, one behaviour at a time. The guide is the same record at the level a person reads: what this part of the product lets people do, journey by journey, as it is today. It is written last, from the final specs, so that changes made during implementation are already in it. The format is in [GUIDE-FORMAT.md](GUIDE-FORMAT.md). Read that file before writing.

## Steps

1. **Pick the areas.** The arguments, or every area with a spec file changed in `git diff <default branch>...HEAD --name-only`.
2. **Read each area.** Every spec under `specs/<area>/`, its status, scenarios, constraints and out-of-scope notes. Only `implemented` specs go into the guide. An area whose only change is `draft` or `accepted` specs needs no guide change: say so and skip it.
3. **Read the existing guide**, if there is one, and the guides of related areas it links. Keep journey names that already exist: they are stable identifiers, used by `/flow:capture` and by links from other guides.
4. **Write.** Update the journeys the changed specs touch, add journeys for new capability, and remove anything a `superseded` spec described. Every journey links the scenarios that pin it down. Guides are documentation prose: if this session is not Fable, hand a `fable` agent the format, the spec paths and the existing guide, and review what comes back yourself.
5. **Check.** Every link resolves to a spec file and a scenario heading. Every implemented spec in the area is linked at least once. Nothing in the guide describes behaviour that no implemented spec covers; if it does, either a spec is missing or the guide is wrong, and you say which.
6. **Report** the areas written, the journeys added, changed or removed, and anything that could not be placed.

## Rules

- Write only `specs/<area>/README.md`. Never change a spec to make the guide easier to write; if a spec is wrong, stop and say so.
- Describe what the system does, never how it is built.
- Do not include screenshots unless the project generates them in its tests (see `/flow:capture`). A screenshot nobody regenerates goes stale without anyone noticing.
