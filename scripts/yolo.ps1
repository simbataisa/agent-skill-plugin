# BMAD Yolo Mode Toggle — Effective Harness Edition (Windows / PowerShell)
#
# Enables/disables Claude Code Yolo mode with a safety harness.
#
# Usage:
#   .\scripts\yolo.ps1 on     — activate Yolo + Harness for this project
#   .\scripts\yolo.ps1 off    — restore original project settings
#   .\scripts\yolo.ps1 status — show current mode

param(
    [Parameter(Position=0)]
    [ValidateSet("on","off","status","")]
    [string]$Action = ""
)

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$BaseDir     = Split-Path -Parent $ScriptDir
$YoloSettings     = Join-Path $BaseDir "hooks\yolo-harness\settings-windows.json"
$YoloHooksSrc     = Join-Path $BaseDir "hooks\yolo-harness\hooks"

$ClaudeDir        = ".claude"
$SettingsFile     = Join-Path $ClaudeDir "settings.json"
$SettingsBackup   = Join-Path $ClaudeDir "settings.backup.json"
$YoloHooksDest    = Join-Path $ClaudeDir "hooks\yolo"
$YoloMarker       = Join-Path $ClaudeDir ".yolo-active"

# ── Helpers ───────────────────────────────────────────────────────────────────

function Check-ProjectRoot {
    if (-not (Test-Path ".bmad")) {
        Write-Error "Must be run from a BMAD project root (no .bmad\ directory found)."
        Write-Error "Run scaffold-project.sh first, or cd to your project root."
        exit 1
    }
}

function Print-Header {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host "  ⚡ BMAD Yolo Mode — Effective Harness"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host ""
}

# ── Status ────────────────────────────────────────────────────────────────────

function Cmd-Status {
    Print-Header
    if (Test-Path $YoloMarker) {
        $activatedAt = Get-Content $YoloMarker -Raw
        Write-Host "  Status:  ACTIVE (since $($activatedAt.Trim()))"
        Write-Host "  Settings: $SettingsFile -> yolo-harness config"
        Write-Host "  Hooks:    $YoloHooksDest\"
        Write-Host ""
        Write-Host "  Harness guards:"
        Write-Host "    [✓] Irreversible commands blocked"
        Write-Host "    [✓] Git WIP checkpoint before every file write"
        Write-Host "    [✓] All file writes logged to .bmad\yolo-session-log.md"
        Write-Host "    [✓] Session summary printed on Stop"
        Write-Host "    [✓] Autonomous agent chaining active (.bmad\signals\autonomous-mode)"
        Write-Host ""
        Write-Host "  To disable: .\scripts\yolo.ps1 off"
    } else {
        Write-Host "  Status:  INACTIVE (standard project settings active)"
        Write-Host ""
        Write-Host "  To enable: .\scripts\yolo.ps1 on"
    }
    Write-Host ""
}

# ── On ────────────────────────────────────────────────────────────────────────

function Cmd-On {
    Check-ProjectRoot
    Print-Header

    if (Test-Path $YoloMarker) {
        Write-Host "  Yolo mode is already active."
        Write-Host "  Run .\scripts\yolo.ps1 status for details."
        Write-Host ""
        return
    }

    if (-not (Test-Path $YoloSettings)) {
        Write-Error "Yolo harness settings not found at: $YoloSettings"
        Write-Error "Re-run the BMAD install script or check your bmad-sdlc-agents installation."
        exit 1
    }

    # Ensure .claude\ structure exists
    New-Item -ItemType Directory -Force -Path (Join-Path $ClaudeDir "hooks") | Out-Null

    # Back up current settings
    if (Test-Path $SettingsFile) {
        Copy-Item $SettingsFile $SettingsBackup -Force
        Write-Host "  [✓] Backed up current settings -> $SettingsBackup"
    }

    # Install yolo-harness settings
    Copy-Item $YoloSettings $SettingsFile -Force
    Write-Host "  [✓] Installed yolo-harness settings -> $SettingsFile"

    # Install harness hook scripts (.ps1 files)
    New-Item -ItemType Directory -Force -Path $YoloHooksDest | Out-Null
    Get-ChildItem (Join-Path $YoloHooksSrc "*.ps1") | Copy-Item -Destination $YoloHooksDest -Force
    Write-Host "  [✓] Installed harness hooks -> $YoloHooksDest\"

    # Activate autonomous agent chaining
    New-Item -ItemType Directory -Force -Path ".bmad\signals" | Out-Null
    New-Item -ItemType File -Force -Path ".bmad\signals\autonomous-mode" | Out-Null
    Write-Host "  [✓] Autonomous agent chaining enabled -> .bmad\signals\autonomous-mode"

    # Write marker
    (Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Set-Content -Path $YoloMarker -Encoding UTF8

    Write-Host ""
    Write-Host "  ⚡ Yolo mode ACTIVE with Effective Harness"
    Write-Host ""
    Write-Host "  What this means:"
    Write-Host "  • Claude Code will NOT ask for confirmation on any tool call"
    Write-Host "  • All tool calls (Bash, Write, Edit, Glob, etc.) auto-approved"
    Write-Host "  • Agents auto-handoff to next without waiting for your command"
    Write-Host ""
    Write-Host "  Harness guardrails still enforced:"
    Write-Host "  • Irreversible commands blocked (rm -rf /, git push --force, DROP TABLE, etc.)"
    Write-Host "  • git push --force and --no-verify always denied"
    Write-Host "  • Git WIP checkpoint auto-created before every file write"
    Write-Host "  • All writes logged to .bmad\yolo-session-log.md"
    Write-Host "  • Session diff summary printed when Claude finishes"
    Write-Host ""
    Write-Host "  Start your Claude Code session now:"
    Write-Host "  claude --agent tech-lead   (for TL-orchestrated sprint)"
    Write-Host "  claude                     (for any other session)"
    Write-Host ""
    Write-Host "  To turn off: .\scripts\yolo.ps1 off"
    Write-Host ""
}

# ── Off ───────────────────────────────────────────────────────────────────────

function Cmd-Off {
    Check-ProjectRoot
    Print-Header

    if (-not (Test-Path $YoloMarker)) {
        Write-Host "  Yolo mode is not currently active."
        Write-Host ""
        return
    }

    # Restore original settings
    if (Test-Path $SettingsBackup) {
        Copy-Item $SettingsBackup $SettingsFile -Force
        Remove-Item $SettingsBackup -Force
        Write-Host "  [✓] Restored original settings from backup"
    } else {
        if (Test-Path $SettingsFile) { Remove-Item $SettingsFile -Force }
        Write-Host "  [✓] Removed yolo-harness settings (no original to restore)"
    }

    # Remove harness hooks
    if (Test-Path $YoloHooksDest) {
        Remove-Item $YoloHooksDest -Recurse -Force
        Write-Host "  [✓] Removed harness hooks from $YoloHooksDest"
    }

    # Deactivate autonomous chaining and clear all session sentinels
    $signalFiles = @(
        # Autonomous mode flag
        ".bmad\signals\autonomous-mode",
        # Planning-phase sentinels
        ".bmad\signals\ba-done", ".bmad\signals\po-done", ".bmad\signals\sa-done",
        ".bmad\signals\ea-done", ".bmad\signals\ux-done", ".bmad\signals\tl-plan-done",
        # Execution-phase E2 sentinels — ready (written by engineers)
        ".bmad\signals\E2-be-ready", ".bmad\signals\E2-fe-ready", ".bmad\signals\E2-me-ready",
        # Execution-phase E2 sentinels — done (written by Tech Lead after worktree review)
        ".bmad\signals\E2-be-done", ".bmad\signals\E2-fe-done", ".bmad\signals\E2-me-done",
        # Execution-phase E2 sentinels — rework (written by Tech Lead when review fails)
        ".bmad\signals\E2-be-rework", ".bmad\signals\E2-fe-rework", ".bmad\signals\E2-me-rework"
    )
    foreach ($f in $signalFiles) {
        if (Test-Path $f) { Remove-Item $f -Force }
    }
    Write-Host "  [✓] Autonomous agent chaining disabled — all signals cleared"

    # Remove marker
    Remove-Item $YoloMarker -Force

    Write-Host ""
    Write-Host "  [✓] Yolo mode DEACTIVATED — standard settings restored"
    Write-Host ""

    # Remind about WIP commits
    $gitCheck = git rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -eq 0) {
        $wipCount = (git log --oneline --grep="yolo-harness: WIP checkpoint" 2>$null | Measure-Object -Line).Lines
        if ($wipCount -gt 0) {
            Write-Host "  WARNING: $wipCount WIP checkpoint commit(s) from your Yolo session remain."
            Write-Host "  Squash them into a clean commit before pushing:"
            Write-Host "  git rebase -i HEAD~$($wipCount + 1)"
            Write-Host ""
        }
    }

    Write-Host "  Session log preserved at: .bmad\yolo-session-log.md"
    Write-Host ""
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

switch ($Action) {
    "on"     { Cmd-On }
    "off"    { Cmd-Off }
    "status" { Cmd-Status }
    default  {
        Write-Host ""
        Write-Host "Usage: .\scripts\yolo.ps1 <on|off|status>"
        Write-Host ""
        Write-Host "  on      Activate Yolo mode + Effective Harness for this project"
        Write-Host "  off     Restore original settings and remove harness hooks"
        Write-Host "  status  Show whether Yolo mode is currently active"
        Write-Host ""
        exit 1
    }
}
