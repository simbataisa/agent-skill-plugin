# BMAD Yolo Harness — PreToolUse: Bash/PowerShell guard (Windows)
# Blocks irreversible or globally destructive commands even in Yolo mode.
# Exit 2 to block the command. Exit 0 to allow.

param([string]$Command = "")

# ── Patterns that are ALWAYS blocked in Yolo mode ─────────────────────────────

$BlockedPatterns = @(
    "rm -rf /",
    "rm -rf ~",
    "Remove-Item.*-Recurse.*-Force.*C:\\",
    "Remove-Item.*-Recurse.*-Force.*\\\\",
    "git push --force",
    "git push -f",
    "--no-verify",
    "DROP TABLE",
    "DROP DATABASE",
    "TRUNCATE TABLE",
    "Format-Volume",
    "diskpart",
    "Stop-Computer",
    "Restart-Computer",
    "shutdown /s",
    "shutdown /r"
)

foreach ($pattern in $BlockedPatterns) {
    if ($Command -imatch [regex]::Escape($pattern).Replace("\-", "-")) {
        Write-Error "BLOCKED [YOLO HARNESS]: Command matches guardrail pattern '$pattern'"
        Write-Error "Command: $Command"
        Write-Error "Disable Yolo mode (.\scripts\yolo.ps1 off) and run manually if intentional."
        exit 2
    }
}

# ── Warn on moderately risky patterns ─────────────────────────────────────────

$WarnPatterns = @(
    "git reset --hard",
    "git clean -f",
    "git checkout -- .",
    "Remove-Item.*-Recurse"
)

foreach ($pattern in $WarnPatterns) {
    if ($Command -imatch $pattern) {
        Write-Warning "[YOLO HARNESS] Potentially destructive command detected: $Command"
        Write-Warning "Proceeding (allowed in Yolo mode — ensure git checkpoint exists)."
        break
    }
}

exit 0
