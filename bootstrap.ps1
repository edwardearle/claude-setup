<#
.SYNOPSIS
Wires this clone of claude-setup into the local Claude Code installation.

.DESCRIPTION
Idempotent; safe to re-run after every git pull. It:
  1. Makes ~/.claude/CLAUDE.md import global/CLAUDE.md from this clone.
  2. Merges global/settings.json into ~/.claude/settings.json (adds, never overwrites).
  3. Registers this repo as a plugin marketplace and installs (or updates) the flow plugin.
  4. Reports whether the codex CLI is available for the orchestration rules.

.PARAMETER MarketplaceSource
  local  - register the marketplace from this clone's path (default; works before the repo is pushed)
  github - register from the GitHub repo named in -GitHubRepo

.PARAMETER SkipPlugin
  Only do the CLAUDE.md and settings steps.
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

# 1. Global CLAUDE.md import
$globalMd = (Join-Path (Join-Path $RepoRoot 'global') 'CLAUDE.md').Replace([char]92, '/')
$importLine = "@$globalMd"
$userMd = Join-Path $ClaudeDir 'CLAUDE.md'

if (Test-Path $userMd) {
    $existing = Read-Text $userMd
    if ($existing.Contains($importLine)) {
        Write-Step "CLAUDE.md already imports $globalMd"
    }
    else {
        Write-Utf8 $userMd ($existing.TrimEnd() + "`r`n`r`n" + $importLine + "`r`n")
        Write-Step "Appended import to existing $userMd"
    }
}
else {
    Write-Utf8 $userMd ("# Global preferences (managed by claude-setup)`r`n`r`n" + $importLine + "`r`n")
    Write-Step "Created $userMd"
}

# 2. Merge settings
$srcPath = Join-Path (Join-Path $RepoRoot 'global') 'settings.json'
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

# 3. Plugin
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
            & claude plugin update $PluginName
        }
        else {
            Write-Step "Installing plugin $PluginName@$MarketplaceName"
            & claude plugin install "$PluginName@$MarketplaceName"
        }
        if ($LASTEXITCODE -ne 0) { Write-Warning "Plugin step returned exit code $LASTEXITCODE" }
    }
}

# 4. Codex
if (Get-Command codex -ErrorAction SilentlyContinue) {
    Write-Step "codex CLI found; Codex routes in the orchestration rules are active"
}
else {
    Write-Step "codex CLI not on PATH; orchestration rules fall back to Claude-only routes"
}

Write-Host ""
Write-Host "Done. Restart Claude Code, then check:"
Write-Host "  /memory   should list $globalMd"
Write-Host "  /plugin   should show $PluginName from $MarketplaceName"
