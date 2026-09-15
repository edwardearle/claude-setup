#!/usr/bin/env bash
# Wires this clone of claude-setup into the local Claude Code installation (macOS, Linux, WSL).
# Idempotent; safe to re-run after every git pull. Mirrors bootstrap.ps1.
#   ./bootstrap.sh [--github owner/repo] [--skip-plugin]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
MARKETPLACE_NAME="ede"
PLUGIN_NAME="flow"
SOURCE="$REPO_ROOT"
SKIP_PLUGIN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --github) SOURCE="$2"; shift 2 ;;
    --skip-plugin) SKIP_PLUGIN=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 1 ;;
  esac
done

step() { echo "==> $*"; }
mkdir -p "$CLAUDE_DIR"

# 1. Global CLAUDE.md import
IMPORT_LINE="@$REPO_ROOT/global/CLAUDE.md"
USER_MD="$CLAUDE_DIR/CLAUDE.md"
if [ -f "$USER_MD" ]; then
  if grep -qF "$IMPORT_LINE" "$USER_MD"; then
    step "CLAUDE.md already imports global preferences"
  else
    printf '\n%s\n' "$IMPORT_LINE" >> "$USER_MD"
    step "Appended import to existing $USER_MD"
  fi
else
  printf '# Global preferences (managed by claude-setup)\n\n%s\n' "$IMPORT_LINE" > "$USER_MD"
  step "Created $USER_MD"
fi

# 2. Merge settings (requires jq)
SRC="$REPO_ROOT/global/settings.json"
DST="$CLAUDE_DIR/settings.json"
if command -v jq >/dev/null 2>&1; then
  [ -f "$DST" ] || echo '{}' > "$DST"
  tmp="$(mktemp)"
  jq -s '
    .[0] as $dst | .[1] as $src |
    ($src | del(.permissions)) * $dst
    | .permissions.allow = ((($dst.permissions.allow // []) + ($src.permissions.allow // [])) | unique)
    | .permissions.deny  = ((($dst.permissions.deny  // []) + ($src.permissions.deny  // [])) | unique)
  ' "$DST" "$SRC" > "$tmp" && mv "$tmp" "$DST"
  step "Merged settings into $DST"
else
  step "jq not found; skipping settings merge. Copy the permissions from $SRC into $DST by hand."
fi

# 3. Plugin
if [ "$SKIP_PLUGIN" -eq 0 ]; then
  if command -v claude >/dev/null 2>&1; then
    if claude plugin marketplace list 2>/dev/null | grep -qw "$MARKETPLACE_NAME"; then
      step "Marketplace '$MARKETPLACE_NAME' registered; updating"
      claude plugin marketplace update "$MARKETPLACE_NAME" || true
    else
      step "Registering marketplace from $SOURCE"
      claude plugin marketplace add "$SOURCE" || true
    fi
    if claude plugin list 2>/dev/null | grep -qw "$PLUGIN_NAME"; then
      step "Plugin '$PLUGIN_NAME' installed; updating"
      claude plugin update "$PLUGIN_NAME@$MARKETPLACE_NAME" || true
    else
      step "Installing plugin $PLUGIN_NAME@$MARKETPLACE_NAME"
      claude plugin install "$PLUGIN_NAME@$MARKETPLACE_NAME" || true
    fi
  else
    echo "claude CLI not on PATH. Inside Claude Code run: /plugin marketplace add $SOURCE  then  /plugin install $PLUGIN_NAME@$MARKETPLACE_NAME" >&2
  fi
fi

# 4. Codex
if command -v codex >/dev/null 2>&1; then
  step "codex CLI found; Codex routes in the orchestration rules are active"
else
  step "codex CLI not on PATH; orchestration rules fall back to Claude-only routes"
fi

echo
echo "Done. Restart Claude Code, then check /memory lists the import and /plugin shows $PLUGIN_NAME."
