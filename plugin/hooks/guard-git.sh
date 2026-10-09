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

without_git_global_options() {
  sed -E 's/git(([[:space:]]+-[Cc][[:space:]]*[^[:space:]]+)|([[:space:]]+--(git-dir|work-tree|namespace|super-prefix|config-env)[[:space:]]+[^[:space:]]+)|([[:space:]]+-[^[:space:]]+))+([[:space:]])/git\6/g'
}

as_git_bash_path() {
  local path=${1//\\//}
  if [[ "$path" =~ ^([A-Za-z]):(/.*)$ ]]; then
    path="/${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
  fi
  printf '%s' "$path" | tr '[:upper:]' '[:lower:]'
}

worktree_path_allowed() {
  local path=${1//\\//}
  case "$path" in
    /*|[A-Za-z]:/*|'$'*) ;;
    *) return 1 ;;
  esac
  case "$path" in
    '$PWD'*|'${PWD}'*|'$(pwd)'*|'$HOME'*|'${HOME}'*) return 1 ;;
  esac
  case "/$path/" in
    */../*|*/./*) return 1 ;;
  esac
  [[ "$path" =~ /\.claude/worktrees/[^/]+/?$ ]] || return 1
  [[ "$path" =~ /\.claude/worktrees/.*/\.claude/worktrees/ ]] && return 1
  [ -n "$HOME" ] && [[ "$(as_git_bash_path "$path")" == "$(as_git_bash_path "$HOME")"/.claude/* ]] && return 1
  return 0
}

quote_aware_words() {
  awk '{
    word = ""; quote = ""; has = 0
    for (k = 1; k <= length($0); k++) {
      c = substr($0, k, 1)
      if (quote != "") { if (c == quote) quote = ""; else word = word c; continue }
      if (c == "\"" || c == "\047") { quote = c; has = 1; continue }
      if (c ~ /[[:space:]]/) { if (has || word != "") print word; word = ""; has = 0; continue }
      word = word c
    }
    if (has || word != "") print word
  }'
}

worktree_adds_allowed() {
  local segment word words i j k n path
  while IFS= read -r segment; do
    words=()
    while IFS= read -r word; do words+=("$word"); done < <(printf '%s\n' "$segment" | quote_aware_words)
    n=${#words[@]}
    for ((i = 0; i < n; i++)); do
      [ "${words[i]##*[\(\`]}" = git ] || continue
      for ((k = i + 1; k < n; k++)); do
        case "${words[k]}" in
          -C|-c|--git-dir|--work-tree|--namespace|--super-prefix|--config-env) k=$((k + 1)) ;;
          -*) ;;
          *) break ;;
        esac
      done
      [ "${words[k]}" = worktree ] && [ "${words[k+1]}" = add ] || continue
      path=""
      for ((j = k + 2; j < n; j++)); do
        case "${words[j]}" in
          -h|--help) path=help; break ;;
          -b|-B|--reason) j=$((j + 1)) ;;
          --) path=${words[j+1]}; break ;;
          -*) ;;
          '#'*) break ;;
          *) path=${words[j]%%[\)\`]*}; break ;;
        esac
      done
      [ "$path" = help ] && continue
      worktree_path_allowed "$path" || return 1
    done
  done <<< "$(printf '%s' "$cmd" | sed -E 's/(&&|[|][|]|;|[|])/\n/g')"
  return 0
}

cmd=${cmd//$'\r'/}
line_continuation=$'\\\n'
cmd=${cmd//"$line_continuation"/ }
plain=$(printf '%s' "$cmd" | sed -E "s/\"[^\"]*\"/Q/g; s/'[^']*'/Q/g" | without_git_global_options)

if printf '%s' "$plain" | grep -Eq 'git[[:space:]]+add[[:space:]]+(-A|--all|\.)([[:space:]]|$)'; then
  deny "Blanket staging is blocked. Run git status --short and stage the paths you intend to commit."
fi

if printf '%s' "$plain" | grep -Eq 'git[[:space:]]+push([[:space:]].*)?[[:space:]](-f|--force|--force-with-lease)([[:space:]]|$)'; then
  deny "Force pushes are blocked. If the user wants a history rewrite pushed, ask them to run it by hand."
fi

if printf '%s' "$plain" | grep -Eq 'git[[:space:]]+commit[[:space:]].*--no-verify'; then
  deny "Skipping commit hooks is blocked. Fix what the hook is complaining about instead."
fi

if ! worktree_adds_allowed; then
  deny "Worktrees go in the main clone at <root>/.claude/worktrees/<name>, given as an absolute path, with <root> taken from git rev-parse --git-common-dir. See the source-control rules."
fi

if printf '%s' "$plain" | grep -Eq 'git[[:space:]]+(reset[[:space:]]+--hard|checkout[[:space:]]+--[[:space:]]|clean[[:space:]]+-[a-zA-Z]*f)'; then
  deny "This discards uncommitted work. State what you want to discard and ask the user to run it."
fi

exit 0
