# BMAD Yolo Harness — PostToolUse: Write/Edit/MultiEdit logger (Windows)
# Appends every file write to .bmad\yolo-session-log.md.
# Always exits 0.

param([string]$FilePath = "")

$logFile = ".bmad\yolo-session-log.md"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Ensure .bmad\ exists
if (-not (Test-Path ".bmad")) {
    New-Item -ItemType Directory -Path ".bmad" | Out-Null
}

# Bootstrap the log if this is the first write this session
if (-not (Test-Path $logFile)) {
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if (-not $branch) { $branch = "unknown" }
    @"
# BMAD Yolo Session Log

**Mode:** Yolo + Effective Harness
**Started:** $timestamp
**Branch:** $branch

---

## Files Written This Session

| Timestamp | File |
|-----------|------|
"@ | Set-Content -Path $logFile -Encoding UTF8
}

# Append the write entry
"| $timestamp | ``$FilePath`` |" | Add-Content -Path $logFile -Encoding UTF8

exit 0
