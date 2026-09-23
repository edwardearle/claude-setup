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

# 1. Global and platform CLAUDE.md imports
case "$(uname -s)" in
  Darwin)               PLATFORM_FILE="macos.md" ;;
  Linux)                PLATFORM_FILE="linux.md" ;;
  MINGW*|MSYS*|CYGWIN*) PLATFORM_FILE="windows.md" ;;
  *)                    PLATFORM_FILE="" ;;
esac

USER_MD="$CLAUDE_DIR/CLAUDE.md"
if [ ! -f "$USER_MD" ]; then
  printf '# Global preferences (managed by claude-setup)\n' > "$USER_MD"
  step "Created $USER_MD"
fi

add_import() {
  if grep -qF "$1" "$USER_MD"; then return 0; fi
  printf '\n%s\n' "$1" >> "$USER_MD"
  step "Added import: $1"
}

add_import "@$REPO_ROOT/global/CLAUDE.md"
if [ -n "$PLATFORM_FILE" ] && [ -f "$REPO_ROOT/global/platform/$PLATFORM_FILE" ]; then
  add_import "@$REPO_ROOT/global/platform/$PLATFORM_FILE"
else
  step "No platform rules for $(uname -s); skipping that import"
fi

# 2. Plugin
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

# 3. Merge settings (requires jq)
# Runs after the plugin step, and checks its result, because a merged key was once
# lost while the plugin step ran. The cause is not confirmed.
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
  missing="$(jq -rn --slurpfile d "$DST" --slurpfile s "$SRC" '
    ($s[0] | del(.permissions) | keys) - ($d[0] | keys)
    + ((($s[0].permissions.allow // []) - ($d[0].permissions.allow // [])) | map("permissions.allow " + .))
    + ((($s[0].permissions.deny  // []) - ($d[0].permissions.deny  // [])) | map("permissions.deny " + .))
    | join(", ")')"
  if [ -n "$missing" ]; then
    echo "warning: not in $DST after the merge: $missing. Close Claude Code and re-run bootstrap." >&2
  fi
else
  step "jq not found; skipping settings merge. Copy the permissions from $SRC into $DST by hand."
fi

# 4. Codex
if command -v codex >/dev/null 2>&1; then
  step "codex CLI found; Codex routes in the orchestration rules are active"

  CODEX_DIR="$HOME/.codex"
  mkdir -p "$CODEX_DIR"

  read -r -d '' PROVIDER_BLOCK <<'TOML' || true
# Usage-based billing fallback, used by: codex exec --profile api
# The key is read from OPENAI_API_KEY at run time, never stored here.
[model_providers.openai-api]
name = "OpenAI API (usage-based)"
base_url = "https://api.openai.com/v1"
env_key = "OPENAI_API_KEY"
wire_api = "responses"
TOML

  CODEX_CONFIG="$CODEX_DIR/config.toml"
  if [ ! -f "$CODEX_CONFIG" ]; then
    printf '%s
' "$PROVIDER_BLOCK" > "$CODEX_CONFIG"
    step "Created $CODEX_CONFIG"
  elif ! grep -qF '[model_providers.openai-api]' "$CODEX_CONFIG"; then
    printf '
%s
' "$PROVIDER_BLOCK" >> "$CODEX_CONFIG"
    step "Added the openai-api provider to $CODEX_CONFIG"
  else
    step "Codex openai-api provider already present"
  fi

  API_PROFILE="$CODEX_DIR/api.config.toml"
  if [ ! -f "$API_PROFILE" ]; then
    printf 'model_provider = "openai-api"
' > "$API_PROFILE"
    step "Created Codex profile 'api' at $API_PROFILE"
  else
    step "Codex profile 'api' already present"
  fi

  if [ -n "${OPENAI_API_KEY:-}" ]; then
    step "OPENAI_API_KEY is set; the 'api' fallback profile is ready"
  else
    echo "warning: OPENAI_API_KEY is not set; 'codex exec --profile api' will fail until it is." >&2
  fi
else
  step "codex CLI not on PATH; orchestration rules fall back to Claude-only routes"
fi

echo
echo "Done. Restart Claude Code, then check /memory lists the import and /plugin shows $PLUGIN_NAME."
