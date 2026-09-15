#!/usr/bin/env bash
# PreToolUse guard for Bash. Denies a small set of git commands that are hard to undo
# or that bypass review. Fails open: if the payload cannot be parsed, the command runs.

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
elif command -v python >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | python -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null)
else
  exit 0
fi

[ -z "$cmd" ] && exit 0

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}

if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+add[[:space:]]+(-A|--all|\.)([[:space:]]|$)'; then
  deny "Blanket staging is blocked. Run git status --short and stage the paths you intend to commit."
fi

if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push([[:space:]].*)?[[:space:]](-f|--force|--force-with-lease)([[:space:]]|$)'; then
  deny "Force pushes are blocked. If the user wants a history rewrite pushed, ask them to run it by hand."
fi

if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+commit[[:space:]].*--no-verify'; then
  deny "Skipping commit hooks is blocked. Fix what the hook is complaining about instead."
fi

if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+(reset[[:space:]]+--hard|checkout[[:space:]]+--[[:space:]]|clean[[:space:]]+-[a-zA-Z]*f)'; then
  deny "This discards uncommitted work. State what you want to discard and ask the user to run it."
fi

exit 0
