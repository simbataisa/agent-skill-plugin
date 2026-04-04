# BMAD Yolo Harness — PreToolUse: Write/Edit/MultiEdit checkpoint (Windows)
# Creates a git WIP checkpoint before Claude writes to a file.
# Always exits 0 — advisory only, never blocks writes.

param([string]$FilePath = "")

# Only checkpoint if inside a git repo
$gitCheck = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0) { exit 0 }

# Check for dirty working tree
$dirty = git status --porcelain 2>$null
if (-not [string]::IsNullOrWhiteSpace($dirty)) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    git add -A 2>$null
    git commit -m "chore(yolo-harness): WIP checkpoint before write -- $timestamp

Auto-checkpoint created by BMAD Yolo Harness pre-write hook.
Triggered by: write to $FilePath
This commit is safe to squash/rebase after the Yolo session ends." --no-verify 2>$null
    # '--no-verify' is intentional: automated safety commit, not a quality commit.
}

exit 0
