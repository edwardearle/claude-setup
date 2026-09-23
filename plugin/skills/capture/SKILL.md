---
name: capture
description: "Run the app, follow the journeys in an area guide, and save a screenshot at each step, so there is an up-to-date picture of how the product looks and behaves today to feed into design tools or a UX fix. Use when the user asks for screenshots of current behaviour, wants to redesign or fix a flow, or asks to capture journeys. Invoke manually: /flow:capture <area> [journey ...] [--to <dir>]"
argument-hint: "<area> [journey ...] [--to <directory>]"
disable-model-invocation: true
---

# Capture journeys

Request: $ARGUMENTS

Screenshots of how the product works today are the best input to a design change. They go stale whenever anything visual changes, including things no spec in the area touches, such as a design system update or a new navigation item. So this skill captures on demand, from the running app, and nothing it saves is committed.

## Steps

1. **Read the journeys.** Open `specs/<area>/README.md` and take the named journeys, or all of them. Each numbered step is a capture point. If the area has no guide, say so and offer `/flow:guide <area>` first; do not guess at journeys.
2. **Read how to run and reach the app.** The project `CLAUDE.md` `Capture` section (see the project template) names how to start the app or which environment to use, the reference data or tenant to capture against, and how the test suite signs in. If the section is missing, ask once for those three things and offer to add the section.
3. **Start the app** with the command the project gives, or use the named environment. Wait until it answers.
4. **Drive it with Playwright.** Write a throwaway script in the scratchpad. Node resolves packages from the script's own folder, so load the project's Playwright by path: `require(require.resolve('@playwright/test', { paths: ['<project root>'] }))`, or `playwright` if that is the package installed. If the project has no Playwright, ask once before installing it in the scratchpad (`npm install playwright`, then `npx playwright install chromium`), since that downloads a browser. For each journey, follow the steps and save a full-page screenshot after each one. Default viewport 1440 by 900; add 390 by 844 if the user asks for mobile.
5. **Sign in without handling a password.** Load the saved sign-in state file the test suite already produces, if the project `CLAUDE.md` names one. Otherwise open a visible browser at the sign-in page, ask the user to sign in themselves, and save the state for the rest of the run. Never type a password, have the script fill one in, or read one from the environment.
6. **Save** to `--to <dir>` if given, otherwise `<scratchpad>/capture/<area>/`. Files are `<journey>/<nn>-<step>.png`. Write `capture.md` beside them: for each file, the journey, the step text from the guide, the URL, the time, and the commit it was taken at.
7. **Report** the folder, the journeys captured, and every step that could not be followed. A step that does not match the app means the guide is stale or the app has a defect. Capture what is on screen and say which you think it is. Warn that the scratchpad does not outlive the session, so suggest `--to` for anything worth keeping.

If the user wants the screenshots in Figma and the Figma connector is available, upload them there on request.

## Making capture repeatable

When the same journeys get captured often, the project can take screenshots in its end-to-end tests at the steps the guide names, named `<journey>/<nn>-<step>.png`, and publish them from CI. Those can be committed under `specs/<area>/screens/` and embedded in the guide, because they are regenerated whenever the tests run. This is a change to the project's tests. Propose it through `/flow:spec` and `/flow:plan`; do not make it from this skill.

## Rules

- Read-only against the app: follow journeys, never submit anything that changes real data outside the reference data or tenant the project names. If a journey ends in an irreversible action, capture up to the confirmation and stop.
- Web apps only, unless the project `CLAUDE.md` names another capture tool. For a mobile or desktop app with none named, say so and stop.
- Nothing this skill writes goes into the repository, except, with the user's agreement, the `Capture` section of the project `CLAUDE.md`.
