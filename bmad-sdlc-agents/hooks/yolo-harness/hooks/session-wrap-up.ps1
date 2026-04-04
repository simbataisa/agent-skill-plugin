# BMAD Yolo Harness — Stop: session wrap-up (Windows)
# Runs when Claude Code finishes a Yolo session.

$logFile = ".bmad\yolo-session-log.md"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "  BMAD Yolo Session Complete"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Git summary ────────────────────────────────────────────────────────────────
$gitCheck = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -eq 0) {
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    Write-Host ""
    Write-Host "  Branch: $branch"
    Write-Host ""

    $dirty = git status --porcelain 2>$null
    if (-not [string]::IsNullOrWhiteSpace($dirty)) {
        Write-Host "  Uncommitted changes:"
        git diff --stat HEAD 2>$null | ForEach-Object { Write-Host "     $_" }
        Write-Host ""
        Write-Host "  Run: git add -A && git commit -m '<your message>'"
        Write-Host "  to finalise this Yolo session's changes."
    } else {
        Write-Host "  All changes committed (WIP checkpoints were auto-committed)."
        Write-Host "  Consider squashing WIP commits: git rebase -i HEAD~<n>"
    }

    $wipCount = (git log --oneline --grep="yolo-harness: WIP checkpoint" 2>$null | Measure-Object -Line).Lines
    if ($wipCount -gt 0) {
        Write-Host ""
        Write-Host "  $wipCount WIP checkpoint commit(s) created during this session."
        Write-Host "  Squash them into a clean commit before pushing:"
        Write-Host "  git rebase -i HEAD~$($wipCount + 1)"
    }
} else {
    Write-Host "  (Not a git repo -- no git summary available)"
}

# ── Finalise session log ───────────────────────────────────────────────────────
if (Test-Path $logFile) {
    "" | Add-Content -Path $logFile -Encoding UTF8
    "---" | Add-Content -Path $logFile -Encoding UTF8
    "" | Add-Content -Path $logFile -Encoding UTF8
    "**Session ended:** $timestamp" | Add-Content -Path $logFile -Encoding UTF8
    $fileCount = (Select-String -Path $logFile -Pattern "^\|" | Measure-Object).Count
    "**Total files written:** $($fileCount - 1)" | Add-Content -Path $logFile -Encoding UTF8
    Write-Host ""
    Write-Host "  Session log: $logFile"
}

Write-Host ""
Write-Host "  To turn off Yolo mode: .\scripts\yolo.ps1 off"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host ""

exit 0
