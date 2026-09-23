<#
.SYNOPSIS
Wires this clone of claude-setup into the local Claude Code installation.

.DESCRIPTION
Idempotent; safe to re-run after every git pull. It:
  1. Makes ~/.claude/CLAUDE.md import global/CLAUDE.md from this clone.
  2. Registers this repo as a plugin marketplace and installs (or updates) the flow plugin.
  3. Merges global/settings.json into ~/.claude/settings.json (adds, never overwrites), then checks it stuck.
  4. Reports whether the codex CLI is available for the orchestration rules.

.PARAMETER MarketplaceSource
  local  - register the marketplace from this clone's path (default; works before the repo is pushed)
  github - register from the GitHub repo named in -GitHubRepo

.PARAMETER SkipPlugin
  Skip the plugin step.
#>
[CmdletBinding()]
param(
    [ValidateSet('local', 'github')]
    [string]$MarketplaceSource = 'local',
    [string]$GitHubRepo = 'edwardearle/claude-setup',
    [switch]$SkipPlugin
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir = Join-Path $HOME '.claude'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$MarketplaceName = 'ede'
$PluginName = 'flow'

function Write-Step([string]$Message) { Write-Host "==> $Message" }
function Write-Utf8([string]$Path, [string]$Text) { [System.IO.File]::WriteAllText($Path, $Text, $Utf8NoBom) }
function Read-Text([string]$Path) { [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) }

if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir | Out-Null
}

# 1. Global and platform CLAUDE.md imports
$GlobalDir = Join-Path $RepoRoot 'global'
$globalMd = (Join-Path $GlobalDir 'CLAUDE.md').Replace([char]92, '/')
$platformMd = (Join-Path (Join-Path $GlobalDir 'platform') 'windows.md').Replace([char]92, '/')
$userMd = Join-Path $ClaudeDir 'CLAUDE.md'

$wanted = @("@$globalMd")
if (Test-Path $platformMd) {
    $wanted += "@$platformMd"
}
else {
    Write-Warning "No platform rules at $platformMd; skipping that import."
}

if (-not (Test-Path $userMd)) {
    Write-Utf8 $userMd "# Global preferences (managed by claude-setup)`r`n"
    Write-Step "Created $userMd"
}

$existing = Read-Text $userMd
$missing = @($wanted | Where-Object { -not $existing.Contains($_) })
if ($missing.Count -gt 0) {
    Write-Utf8 $userMd ($existing.TrimEnd() + "`r`n`r`n" + ($missing -join "`r`n") + "`r`n")
    Write-Step "Added $($missing.Count) import line(s) to $userMd"
}
else {
    Write-Step "CLAUDE.md imports are current"
}

# 2. Plugin
# The claude CLI can write to stderr, which Windows PowerShell 5.1 turns into a
# terminating error under 'Stop' when stderr is redirected. That must not stop the
# settings merge that follows.
$ErrorActionPreference = 'Continue'
if (-not $SkipPlugin) {
    $claude = Get-Command claude -ErrorAction SilentlyContinue
    if (-not $claude) {
        Write-Warning "claude CLI not on PATH. Inside Claude Code run: /plugin marketplace add $RepoRoot  then  /plugin install $PluginName@$MarketplaceName"
    }
    else {
        $source = if ($MarketplaceSource -eq 'github') { $GitHubRepo } else { $RepoRoot }
        $marketplaces = (& claude plugin marketplace list | Out-String)
        if ($marketplaces -match "(?im)\b$MarketplaceName\b") {
            Write-Step "Marketplace '$MarketplaceName' registered; updating"
            & claude plugin marketplace update $MarketplaceName
        }
        else {
            Write-Step "Registering marketplace from $source"
            & claude plugin marketplace add $source
        }
        if ($LASTEXITCODE -ne 0) { Write-Warning "Marketplace step returned exit code $LASTEXITCODE" }

        $installed = (& claude plugin list | Out-String)
        if ($installed -match "(?im)\b$PluginName\b") {
            Write-Step "Plugin '$PluginName' installed; updating"
            & claude plugin update "$PluginName@$MarketplaceName"
        }
        else {
            Write-Step "Installing plugin $PluginName@$MarketplaceName"
            & claude plugin install "$PluginName@$MarketplaceName"
        }
        if ($LASTEXITCODE -ne 0) { Write-Warning "Plugin step returned exit code $LASTEXITCODE" }
    }
}

$ErrorActionPreference = 'Stop'

# 3. Merge settings
# Runs after the plugin step, and checks its result, because a merged key was once
# lost while the plugin step ran.
$srcPath = Join-Path $GlobalDir 'settings.json'
$dstPath = Join-Path $ClaudeDir 'settings.json'
$src = Read-Text $srcPath | ConvertFrom-Json
if (Test-Path $dstPath) { $dst = Read-Text $dstPath | ConvertFrom-Json } else { $dst = New-Object PSObject }
$changed = $false

foreach ($prop in $src.PSObject.Properties) {
    if ($prop.Name -eq 'permissions') { continue }
    if (-not ($dst.PSObject.Properties.Name -contains $prop.Name)) {
        $dst | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value
        $changed = $true
    }
}

if ($src.permissions) {
    if (-not ($dst.PSObject.Properties.Name -contains 'permissions')) {
        $dst | Add-Member -MemberType NoteProperty -Name 'permissions' -Value (New-Object PSObject)
        $changed = $true
    }
    foreach ($list in @('allow', 'deny')) {
        $srcList = $src.permissions.$list
        if (-not $srcList) { continue }
        if (-not ($dst.permissions.PSObject.Properties.Name -contains $list)) {
            $dst.permissions | Add-Member -MemberType NoteProperty -Name $list -Value @()
        }
        $merged = New-Object System.Collections.ArrayList
        foreach ($rule in @($dst.permissions.$list)) { if ($null -ne $rule) { [void]$merged.Add($rule) } }
        foreach ($rule in $srcList) {
            if (-not $merged.Contains($rule)) { [void]$merged.Add($rule); $changed = $true }
        }
        $dst.permissions.$list = [string[]]$merged.ToArray()
    }
}

if ($changed) {
    Write-Utf8 $dstPath (ConvertTo-Json -InputObject $dst -Depth 20)
    Write-Step "Merged settings into $dstPath"
}
else {
    Write-Step "settings.json already up to date"
}

if (Test-Path $dstPath) { $check = Read-Text $dstPath | ConvertFrom-Json } else { $check = New-Object PSObject }
$missing = @()
foreach ($prop in $src.PSObject.Properties) {
    if ($prop.Name -eq 'permissions') { continue }
    if (-not ($check.PSObject.Properties.Name -contains $prop.Name)) { $missing += $prop.Name }
}
foreach ($list in @('allow', 'deny')) {
    foreach ($rule in @($src.permissions.$list)) {
        if ($null -ne $rule -and -not (@($check.permissions.$list) -contains $rule)) { $missing += "permissions.$list $rule" }
    }
}
if ($missing.Count -gt 0) {
    Write-Warning ("Not in $dstPath after the merge: " + ($missing -join ', ') + ". Close Claude Code and re-run bootstrap.")
}

# 4. Codex
if (Get-Command codex -ErrorAction SilentlyContinue) {
    Write-Step "codex CLI found; Codex routes in the orchestration rules are active"

    $CodexDir = Join-Path $HOME '.codex'
    if (-not (Test-Path $CodexDir)) { New-Item -ItemType Directory -Path $CodexDir | Out-Null }

    $providerBlock = @(
        '# Usage-based billing fallback, used by: codex exec --profile api',
        '# The key is read from OPENAI_API_KEY at run time, never stored here.',
        '[model_providers.openai-api]',
        'name = "OpenAI API (usage-based)"',
        'base_url = "https://api.openai.com/v1"',
        'env_key = "OPENAI_API_KEY"',
        'wire_api = "responses"'
    ) -join "`r`n"

    $codexConfig = Join-Path $CodexDir 'config.toml'
    if (-not (Test-Path $codexConfig)) {
        Write-Utf8 $codexConfig ($providerBlock + "`r`n")
        Write-Step "Created $codexConfig"
    }
    elseif (-not (Read-Text $codexConfig).Contains('[model_providers.openai-api]')) {
        Write-Utf8 $codexConfig ((Read-Text $codexConfig).TrimEnd() + "`r`n`r`n" + $providerBlock + "`r`n")
        Write-Step "Added the openai-api provider to $codexConfig"
    }
    else {
        Write-Step "Codex openai-api provider already present"
    }

    $apiProfile = Join-Path $CodexDir 'api.config.toml'
    if (-not (Test-Path $apiProfile)) {
        Write-Utf8 $apiProfile ('model_provider = "openai-api"' + "`r`n")
        Write-Step "Created Codex profile 'api' at $apiProfile"
    }
    else {
        Write-Step "Codex profile 'api' already present"
    }

    if ($env:OPENAI_API_KEY) {
        Write-Step "OPENAI_API_KEY is set; the 'api' fallback profile is ready"
    }
    else {
        Write-Warning "OPENAI_API_KEY is not set; 'codex exec --profile api' will fail until it is."
    }
}
else {
    Write-Step "codex CLI not on PATH; orchestration rules fall back to Claude-only routes"
}

Write-Host ""
Write-Host "Done. Restart Claude Code, then check:"
Write-Host "  /memory   should list $globalMd and the platform rules"
Write-Host "  /plugin   should show $PluginName from $MarketplaceName"
