#!/usr/bin/env bash
# Runs plugin/hooks/guard-git.sh against sample commands. Usage: bash tests/guard-git.sh

hook="$(dirname "$0")/../plugin/hooks/guard-git.sh"
failures=0

json_string() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  printf '"%s"' "$s"
}

expect() {
  local expected="$1" command="$2" output actual errors
  errors=$(mktemp)
  if ! output=$(printf '{"tool_input":{"command":%s}}' "$(json_string "$command")" | bash "$hook" 2>"$errors") || [ -s "$errors" ]; then
    actual=crash
    sed 's/^/     /' "$errors"
  elif printf '%s' "$output" | grep -q '"deny"'; then
    actual=deny
  else
    actual=allow
  fi
  rm -f "$errors"
  if [ "$actual" = "$expected" ]; then
    echo "ok   $actual  $command"
  else
    echo "FAIL $actual (expected $expected)  $command"
    failures=$((failures + 1))
  fi
}

expect allow 'git worktree add "$ROOT/.claude/worktrees/12-x" -b 12-x --no-track origin/main'
expect allow 'git worktree add C:\Users\e\repo\.claude\worktrees\12-x -b 12-x'
expect allow 'git worktree add /c/Users/e/repo/.claude/worktrees/12-x'
expect allow 'git -C /c/repo worktree add /c/repo/.claude/worktrees/12-x -b 12-x'
expect allow 'git fetch origin && git worktree add "$ROOT/.claude/worktrees/12-x" -b 12-x --no-track origin/main'
expect allow 'git worktree list'
expect allow 'git worktree remove "$ROOT/.claude/worktrees/12-x"'
expect allow 'git worktree add --help'

expect deny 'git worktree add ../Repo--slug -b 12-x origin/main'
expect deny 'git worktree add .claude/worktrees/12-x -b 12-x'
expect deny 'git worktree add ../.claude/worktrees/12-x'
expect deny 'git worktree add /c/repo/.claude/worktrees/../../outside'
expect deny 'git worktree add /c/repo/.claude/worktrees/a/.claude/worktrees/b'
expect deny 'git worktree add "$(pwd)/.claude/worktrees/12-x"'
expect deny 'git worktree add $PWD/.claude/worktrees/12-x'
expect deny 'git worktree add /c/repo/.claude/worktrees/'
expect deny 'git worktree add'
expect deny 'git worktree add ../sib -b 12-x && ls .claude/worktrees/x'
expect deny 'ls /c/repo/.claude/worktrees/x && git worktree add ../y'
expect deny 'git worktree add ../sib -b 12-x # /c/repo/.claude/worktrees/12-x'
expect deny 'git worktree add ../sib; git worktree add /c/repo/.claude/worktrees/12-x'
expect deny 'git -C . worktree add ../sib -b 12-x'
expect deny 'git -C /c/repo/.claude/worktrees/12-x worktree add ../other -b 13-y'
expect deny 'git -c core.x=y worktree add ../sib'
expect deny 'git -P worktree add ../sib'
expect deny 'git --no-optional-locks worktree add ../sib'
expect deny 'git --git-dir /c/repo/.git worktree add ../sib'
expect deny 'git -C/c/repo worktree add ../sib'
expect deny '(git worktree add ../sib)'
expect deny 'echo $(git worktree add ../sib)'
expect deny 'git worktree add ~/.claude/worktrees/x'
expect deny "git worktree add $HOME/.claude/worktrees/x"
expect deny 'git worktree add --help; git worktree add ../sib'
expect deny $'git worktree \\\n  add ../sib'
expect allow $'git worktree add \\\n  "$ROOT/.claude/worktrees/12-x" -b 12-x'
expect allow $'git fetch origin\ngit worktree add "$ROOT/.claude/worktrees/12-x" -b 12-x'
expect allow $'git worktree add "$ROOT/.claude/worktrees/12-x"\ngit status'
expect allow 'git worktree add "/c/Users/Some One/repo/.claude/worktrees/12-x"'
expect allow 'git worktree add --lock --reason "wip here" "$ROOT/.claude/worktrees/12-x"'
expect allow 'git worktree add -f --detach -q "$ROOT/.claude/worktrees/12-x"'
expect allow 'git worktree add C:/Users/e/repo/.claude/worktrees/12-x'
expect allow 'git --version'

expect deny 'git add -A'
expect deny 'git -C /c/repo add -A'
expect deny 'git -C "/c/path with space" add -A'
expect allow 'git add README.md'
expect deny 'git push --force origin x'
expect deny 'git -C /c/repo push -f'
expect allow 'git push -u origin 12-x'
expect deny 'git commit -m x --no-verify'
expect deny 'git reset --hard HEAD~1'
expect deny 'git clean -fd'

echo
if [ "$failures" -eq 0 ]; then echo "all passed"; else echo "$failures failed"; exit 1; fi
