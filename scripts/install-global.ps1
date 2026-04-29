<#
.SYNOPSIS
    BMAD Global Install Script (Windows PowerShell port of install-global.sh).

.DESCRIPTION
    Deploys BMAD agents, skills, subagents, commands, hooks, the Karpathy
    principles, the A2UI reference, the eval dashboard, and diagnostic scripts
    to every AI coding tool detected on the current Windows user account.

    Supported tools: Claude Code, Cowork, Codex CLI, Kiro, Cursor, Windsurf,
    Trae IDE, GitHub Copilot, Gemini CLI, OpenCode, Aider.

.PARAMETER DryRun
    Print every action without writing any files.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\install-global.ps1

.EXAMPLE
    .\scripts\install-global.ps1 -DryRun

.NOTES
    Windows PowerShell 5.1+ or PowerShell 7+. No external dependencies —
    JSON merges use the built-in ConvertFrom-Json / ConvertTo-Json cmdlets
    (no python3 required).
#>

[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# ─── Paths ────────────────────────────────────────────────────────────────────

$ScriptDir       = Split-Path -Parent $MyInvocation.MyCommand.Path
$BaseDir         = Split-Path -Parent $ScriptDir
$SharedContext   = Join-Path $BaseDir 'shared\BMAD-SHARED-CONTEXT.md'
$AgentsDir       = Join-Path $BaseDir 'agents'
$HooksDir        = Join-Path $BaseDir 'hooks\global'
$CommandsDir     = Join-Path $BaseDir 'commands'
$RulesDir        = Join-Path $BaseDir 'rules'
$McpConfigsDir   = Join-Path $BaseDir 'mcp-configs\global'

# Tracking state
$InstalledTools = New-Object System.Collections.Generic.List[string]
$SkippedTools   = New-Object System.Collections.Generic.List[string]

# ─── Pretty-print helpers ─────────────────────────────────────────────────────

function Write-Banner([string]$Text) {
    Write-Host ''
    Write-Host '========================================' -ForegroundColor Blue
    Write-Host "  $Text" -ForegroundColor Blue
    Write-Host '========================================' -ForegroundColor Blue
    Write-Host ''
}

function Write-Section([string]$Text) {
    Write-Host $Text -ForegroundColor Blue
}

function Write-Ok([string]$Text) {
    Write-Host "✓ $Text" -ForegroundColor Green
}

function Write-Fail([string]$Text) {
    Write-Host "✗ $Text" -ForegroundColor Red
}

function Write-Warn([string]$Text) {
    Write-Host $Text -ForegroundColor Yellow
}

function Test-CommandExists([string]$Name) {
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

Write-Banner 'BMAD Global Agent Installer'

# ─── Validate source files ────────────────────────────────────────────────────

if (-not (Test-Path -LiteralPath $SharedContext)) {
    Write-Fail "Error: Shared context not found at $SharedContext"
    exit 1
}
if (-not (Test-Path -LiteralPath $AgentsDir)) {
    Write-Fail "Error: Agents directory not found at $AgentsDir"
    exit 1
}

if ($DryRun) {
    Write-Warn '[DRY RUN MODE]'
    Write-Host ''
}

# ─── File helpers ─────────────────────────────────────────────────────────────

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

# Write / append UTF-8 without BOM. Windows PowerShell 5.1's default UTF8
# encoding writes a BOM, which breaks strict YAML parsers (e.g. Kiro steering).
# PowerShell 7+ already defaults to no-BOM, but this helper keeps both shells
# byte-identical with the bash installer's output.
$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Set-Utf8 {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )
    [System.IO.File]::WriteAllText($Path, $Content, $script:Utf8NoBom)
}

function Add-Utf8 {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )
    # Create if missing, otherwise append
    if (-not (Test-Path -LiteralPath $Path)) {
        [System.IO.File]::WriteAllText($Path, $Content, $script:Utf8NoBom)
    } else {
        # File.AppendAllText also writes without BOM when the file already has content
        [System.IO.File]::AppendAllText($Path, $Content, $script:Utf8NoBom)
    }
}

function Copy-FileSafe {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )
    if ($DryRun) {
        Write-Host "  [DRY] cp $Source -> $Destination"
        return
    }
    Ensure-Directory (Split-Path -Parent $Destination)
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

function Copy-DirSafe {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )
    if (-not (Test-Path -LiteralPath $Source)) { return }
    if ($DryRun) {
        Write-Host "  [DRY] cp -r $Source -> $Destination"
        return
    }
    Ensure-Directory $Destination
    # Mirror cp -r behavior: copy the folder INTO Destination
    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
}

function Write-FileSafe {
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Destination
    )
    if ($DryRun) {
        Write-Host "  [DRY] write -> $Destination"
        return
    }
    Ensure-Directory (Split-Path -Parent $Destination)
    # Use -NoNewline + trailing newline discipline consistent with bash "echo > file"
    Set-Utf8 -Path $Destination -Content $Content
}

function Append-FileSafe {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )
    if ($DryRun) {
        Write-Host "  [DRY] append $Source -> $Destination"
        return
    }
    Ensure-Directory (Split-Path -Parent $Destination)
    if (-not (Test-Path -LiteralPath $Destination)) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
    } else {
        Add-Utf8 -Path $Destination -Content (Get-Content -LiteralPath $Source -Raw)
    }
}

# ─── Sub-agent namespace walker ───────────────────────────────────────────────
# Sub-agents live as sibling .md files alongside SKILL.md in each agent folder:
#   agents/<agent>/SKILL.md          ← main skill (uppercase, skipped by walker)
#   agents/<agent>/<cmd>.md          ← sub-agent commands (lowercase siblings)
#
# Handler receives an object with: AgentName, CmdName, Source, DestBase

function Walk-SubAgents {
    param(
        [Parameter(Mandatory)][scriptblock]$Handler,
        [Parameter(Mandatory)][string]$DestBase
    )
    Get-ChildItem -LiteralPath $AgentsDir -Directory | Sort-Object Name | ForEach-Object {
        $agentName = $_.Name
        Get-ChildItem -LiteralPath $_.FullName -Filter '*.md' -File | Sort-Object Name | ForEach-Object {
            $cmdName = [IO.Path]::GetFileNameWithoutExtension($_.Name)
            if ($cmdName -eq 'SKILL') { return }
            & $Handler ([pscustomobject]@{
                AgentName = $agentName
                CmdName   = $cmdName
                Source    = $_.FullName
                DestBase  = $DestBase
            })
        }
    }
}

# ─── YAML frontmatter helpers ─────────────────────────────────────────────────
# The canonical command format is YAML frontmatter + markdown body; adapters
# transform that for tools that need a different shape.

function Get-FrontmatterBody([string]$FilePath) {
    # Return the markdown body with any leading YAML frontmatter block removed.
    $raw = Get-Content -LiteralPath $FilePath -Raw
    if ($null -eq $raw) { return '' }
    # Match an opening --- on the first line, everything up to the next --- line.
    if ($raw -match '(?sm)\A---\r?\n.*?\r?\n---\r?\n?') {
        return $raw.Substring($Matches[0].Length)
    }
    return $raw
}

function Get-FrontmatterField {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string]$Field
    )
    $raw = Get-Content -LiteralPath $FilePath -Raw
    if ($null -eq $raw) { return '' }
    if (-not ($raw -match '(?sm)\A---\r?\n(.*?)\r?\n---')) { return '' }
    $fm = $Matches[1]
    foreach ($line in $fm -split "`r?`n") {
        if ($line -match "^\s*$([regex]::Escape($Field))\s*:\s*(.*)$") {
            $val = $Matches[1].Trim()
            # Strip wrapping single- or double-quotes
            if ($val.Length -ge 2 -and (
                ($val.StartsWith('"') -and $val.EndsWith('"')) -or
                ($val.StartsWith("'") -and $val.EndsWith("'"))
            )) {
                $val = $val.Substring(1, $val.Length - 2)
            }
            return $val
        }
    }
    return ''
}

# ─── Command format adapters ──────────────────────────────────────────────────

# Claude Code / Cowork / OpenCode / GitHub Copilot:
# Native YAML frontmatter. Preserve subdirectory → /agent:cmd namespace.
$Install_Native = {
    param($it)
    $dst = Join-Path (Join-Path $it.DestBase $it.AgentName) "$($it.CmdName).md"
    if ($DryRun) {
        Write-Host "  [DRY] /$($it.AgentName):$($it.CmdName) -> $dst"
        return
    }
    Ensure-Directory (Split-Path -Parent $dst)
    Copy-Item -LiteralPath $it.Source -Destination $dst -Force
}

# Codex CLI: YAML-compatible, replace $ARGUMENTS -> $1
$Install_Codex = {
    param($it)
    $dst = Join-Path (Join-Path $it.DestBase $it.AgentName) "$($it.CmdName).md"
    if ($DryRun) {
        Write-Host "  [DRY] codex /$($it.AgentName):$($it.CmdName) -> $dst"
        return
    }
    Ensure-Directory (Split-Path -Parent $dst)
    $text = Get-Content -LiteralPath $it.Source -Raw
    $text = $text -replace '\$ARGUMENTS', '$1'
    Set-Utf8 -Path $dst -Content $text
}

# Cursor: strip YAML frontmatter, add # /agent:cmd header
$Adapt_Cursor = {
    param($it)
    $dst = Join-Path (Join-Path $it.DestBase $it.AgentName) "$($it.CmdName).md"
    $description = Get-FrontmatterField -FilePath $it.Source -Field 'description'
    $argHint     = Get-FrontmatterField -FilePath $it.Source -Field 'argument-hint'
    if ($DryRun) {
        Write-Host "  [DRY] cursor /$($it.AgentName):$($it.CmdName) -> $dst"
        return
    }
    Ensure-Directory (Split-Path -Parent $dst)
    $parts = New-Object System.Collections.Generic.List[string]
    $parts.Add("# /$($it.AgentName):$($it.CmdName)")
    if ($description) { $parts.Add(''); $parts.Add($description) }
    if ($argHint)     { $parts.Add(''); $parts.Add("**Usage:** ``/$($it.AgentName):$($it.CmdName) $argHint``") }
    $parts.Add('')
    $parts.Add((Get-FrontmatterBody $it.Source))
    Set-Utf8 -Path $dst -Content ($parts -join "`n")
}

# Windsurf: rules format, one file per command under bmad-commands/<agent>/
$Adapt_Windsurf = {
    param($it)
    $dst = Join-Path (Join-Path $it.DestBase $it.AgentName) "$($it.CmdName).md"
    $description = Get-FrontmatterField -FilePath $it.Source -Field 'description'
    $argHint     = Get-FrontmatterField -FilePath $it.Source -Field 'argument-hint'
    if ($DryRun) {
        Write-Host "  [DRY] windsurf /$($it.AgentName):$($it.CmdName) -> $dst"
        return
    }
    Ensure-Directory (Split-Path -Parent $dst)
    $phrase = $it.CmdName -replace '-', ' '
    $parts = New-Object System.Collections.Generic.List[string]
    $parts.Add("# Rule: $($it.AgentName):$($it.CmdName)")
    $parts.Add('')
    $parts.Add("**Trigger:** When the user asks to run ``$($it.AgentName):$($it.CmdName)`` or ""$phrase"".")
    if ($description) { $parts.Add(''); $parts.Add($description) }
    if ($argHint)     { $parts.Add(''); $parts.Add("**Arguments:** $argHint") }
    $parts.Add('')
    $parts.Add((Get-FrontmatterBody $it.Source))
    Set-Utf8 -Path $dst -Content ($parts -join "`n")
}

# Trae IDE: same rules-based paradigm as Windsurf.
$Adapt_Trae = {
    param($it)
    $dst = Join-Path (Join-Path $it.DestBase $it.AgentName) "$($it.CmdName).md"
    $description = Get-FrontmatterField -FilePath $it.Source -Field 'description'
    $argHint     = Get-FrontmatterField -FilePath $it.Source -Field 'argument-hint'
    if ($DryRun) {
        Write-Host "  [DRY] trae /$($it.AgentName):$($it.CmdName) -> $dst"
        return
    }
    Ensure-Directory (Split-Path -Parent $dst)
    $phrase = $it.CmdName -replace '-', ' '
    $parts = New-Object System.Collections.Generic.List[string]
    $parts.Add("# Rule: $($it.AgentName):$($it.CmdName)")
    $parts.Add('')
    $parts.Add("**Trigger:** When the user asks to run ``$($it.AgentName):$($it.CmdName)`` or ""$phrase"".")
    if ($description) { $parts.Add(''); $parts.Add($description) }
    if ($argHint)     { $parts.Add(''); $parts.Add("**Arguments:** $argHint") }
    $parts.Add('')
    $parts.Add((Get-FrontmatterBody $it.Source))
    Set-Utf8 -Path $dst -Content ($parts -join "`n")
}

# Gemini CLI: strip frontmatter, replace $ARGUMENTS -> {{input}}
# Flat file: <agent>-<cmd>.md (Gemini uses extension:command, not agent-command)
$Adapt_Gemini = {
    param($it)
    $dst = Join-Path $it.DestBase "$($it.AgentName)-$($it.CmdName).md"
    $description = Get-FrontmatterField -FilePath $it.Source -Field 'description'
    $argHint     = Get-FrontmatterField -FilePath $it.Source -Field 'argument-hint'
    if ($DryRun) {
        Write-Host "  [DRY] gemini /bmad-sdlc:$($it.AgentName)-$($it.CmdName) -> $dst"
        return
    }
    Ensure-Directory (Split-Path -Parent $dst)
    $body = (Get-FrontmatterBody $it.Source) -replace '\$ARGUMENTS', '{{input}}'
    $parts = New-Object System.Collections.Generic.List[string]
    $parts.Add("# $($it.AgentName):$($it.CmdName)")
    if ($description) { $parts.Add(''); $parts.Add($description) }
    if ($argHint)     { $parts.Add(''); $parts.Add("**Arguments:** $argHint") }
    $parts.Add('')
    $parts.Add($body)
    Set-Utf8 -Path $dst -Content ($parts -join "`n")
}

# Kiro: write a skill folder with correct name: frontmatter.
# Kiro does NOT support nested skill folders — all skills must be flat under ~/.kiro/skills/
function Write-KiroSkill {
    param(
        [Parameter(Mandatory)][string]$SkillName,
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$SkillsDir
    )
    $skillDir = Join-Path $SkillsDir $SkillName
    $description = Get-FrontmatterField -FilePath $Source -Field 'description'
    if ($DryRun) {
        Write-Host "  [DRY] /kiro $SkillName -> $skillDir\SKILL.md"
        return
    }
    Ensure-Directory $skillDir
    if (-not $description) { $description = "BMAD $SkillName" }
    # Escape internal double-quotes so the YAML stays valid
    $safeDesc = $description -replace '"', '\"'
    $body = Get-FrontmatterBody $Source
    $content = @(
        '---'
        "name: $SkillName"
        "description: ""$safeDesc"""
        '---'
        ''
        $body
    ) -join "`n"
    Set-Utf8 -Path (Join-Path $skillDir 'SKILL.md') -Content $content
}

# Aider: no native commands; embed as ## Workflow: agent:cmd sections in conventions
$Adapt_Aider = {
    param($it)
    $convFile = $it.DestBase   # re-used as the conventions file path for this adapter
    $description = Get-FrontmatterField -FilePath $it.Source -Field 'description'
    if ($DryRun) {
        Write-Host "  [DRY] aider /$($it.AgentName):$($it.CmdName) -> $convFile"
        return
    }
    Ensure-Directory (Split-Path -Parent $convFile)
    $body = (Get-FrontmatterBody $it.Source) -replace '\$ARGUMENTS', 'the user-provided arguments'
    $parts = New-Object System.Collections.Generic.List[string]
    $parts.Add('')
    $parts.Add('---')
    $parts.Add('')
    $parts.Add("## Workflow: $($it.AgentName):$($it.CmdName)")
    if ($description) { $parts.Add(''); $parts.Add($description) }
    $parts.Add('')
    $parts.Add($body)
    Add-Utf8 -Path $convFile -Content ($parts -join "`n")
}

# ─── settings.json hook merger (native PowerShell — no python required) ──────

function Merge-SettingsJson {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )
    if ($DryRun) {
        Write-Host "  [DRY] merge $Source -> $Destination"
        return
    }
    if (-not (Test-Path -LiteralPath $Destination)) {
        Ensure-Directory (Split-Path -Parent $Destination)
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
        Write-Host "  ✓ Created $(Split-Path -Leaf $Destination)"
        return
    }

    $backup = "$Destination.bak"
    Copy-Item -LiteralPath $Destination -Destination $backup -Force
    Write-Host "  ✓ Backed up existing $(Split-Path -Leaf $Destination) -> $(Split-Path -Leaf $backup)"

    try {
        $src = Get-Content -LiteralPath $Source      -Raw | ConvertFrom-Json
        $dst = Get-Content -LiteralPath $Destination -Raw | ConvertFrom-Json

        $srcHooks = if ($src.PSObject.Properties['hooks']) { $src.hooks } else { $null }
        if ($null -eq $srcHooks) {
            # Nothing to merge
            return
        }
        if (-not $dst.PSObject.Properties['hooks']) {
            $dst | Add-Member -NotePropertyName 'hooks' -NotePropertyValue ([pscustomobject]@{}) -Force
        }
        foreach ($event in $srcHooks.PSObject.Properties.Name) {
            $srcEntries = $srcHooks.$event
            if (-not $dst.hooks.PSObject.Properties[$event]) {
                $dst.hooks | Add-Member -NotePropertyName $event -NotePropertyValue $srcEntries -Force
                continue
            }
            # Gather existing commands across all blocks
            $existingCmds = New-Object System.Collections.Generic.HashSet[string]
            foreach ($block in $dst.hooks.$event) {
                if ($block.PSObject.Properties['hooks']) {
                    foreach ($h in $block.hooks) {
                        if ($h.PSObject.Properties['command']) {
                            [void]$existingCmds.Add([string]$h.command)
                        }
                    }
                }
            }
            # Append only entries whose commands aren't all present
            foreach ($entry in $srcEntries) {
                $newCmds = @()
                if ($entry.PSObject.Properties['hooks']) {
                    $newCmds = $entry.hooks | ForEach-Object {
                        if ($_.PSObject.Properties['command']) { [string]$_.command }
                    }
                }
                $allPresent = $true
                foreach ($c in $newCmds) {
                    if (-not $existingCmds.Contains($c)) { $allPresent = $false; break }
                }
                if (-not $allPresent) {
                    $dst.hooks.$event = @($dst.hooks.$event) + $entry
                }
            }
        }
        $json = $dst | ConvertTo-Json -Depth 100
        Set-Utf8 -Path $Destination -Content $json
        Write-Host "  ✓ Merged hooks into $(Split-Path -Leaf $Destination)"
    }
    catch {
        Copy-Item -LiteralPath $backup -Destination $Destination -Force
        Write-Fail "  Merge failed — restored from backup. Manually merge: $Source"
        Write-Fail "  Reason: $($_.Exception.Message)"
    }
}

# ─── Shared-context prepender ────────────────────────────────────────────────

function Prepend-SharedContext {
    param(
        [Parameter(Mandatory)][string]$AgentFile,
        [Parameter(Mandatory)][string]$OutputFile
    )
    if ($DryRun) {
        Write-Host "  [DRY] prepend shared context + $AgentFile -> $OutputFile"
        return
    }
    Ensure-Directory (Split-Path -Parent $OutputFile)
    $shared = Get-Content -LiteralPath $SharedContext -Raw
    $agent  = Get-Content -LiteralPath $AgentFile     -Raw
    Set-Utf8 -Path $OutputFile -Content "$shared`n`n$agent"
}

# ─── Legacy cleanup helpers ──────────────────────────────────────────────────

function Remove-LegacyFlatSkills {
    param([Parameter(Mandatory)][string]$SkillsDir)
    if ($DryRun -or -not (Test-Path -LiteralPath $SkillsDir)) { return }
    Get-ChildItem -LiteralPath $AgentsDir -Directory | ForEach-Object {
        $flat = Join-Path $SkillsDir "$($_.Name).md"
        if (Test-Path -LiteralPath $flat) {
            Remove-Item -LiteralPath $flat -Force
            Write-Host "  ✓ Removed legacy flat file: $($_.Name).md"
        }
    }
    # Remove old bmad-* prefixed skill folders
    Get-ChildItem -LiteralPath $SkillsDir -Directory -Filter 'bmad-*' -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item -LiteralPath $_.FullName -Recurse -Force
        Write-Host "  ✓ Removed legacy skill folder: $($_.Name)"
    }
}

function Install-AgentSkillFolder {
    param(
        [Parameter(Mandatory)][string]$AgentDir,
        [Parameter(Mandatory)][string]$SkillsRoot
    )
    $agentName = Split-Path -Leaf $AgentDir
    $target    = Join-Path $SkillsRoot $agentName
    if ($DryRun) {
        Write-Host "  [DRY] mkdir + cp $AgentDir\SKILL.md -> $target\SKILL.md"
        return
    }
    Ensure-Directory $target
    Copy-Item -LiteralPath (Join-Path $AgentDir 'SKILL.md') -Destination (Join-Path $target 'SKILL.md') -Force
    $refs = Join-Path $AgentDir 'references'
    if (Test-Path -LiteralPath $refs)      { Copy-Item -LiteralPath $refs -Destination $target -Recurse -Force }
    $tpls = Join-Path $AgentDir 'templates'
    if (Test-Path -LiteralPath $tpls)      { Copy-Item -LiteralPath $tpls -Destination $target -Recurse -Force }
    Write-Host "  ✓ Installed skill: $agentName"
}

Write-Section 'Checking for installed AI tools...'
Write-Host ''

# ============================================================
# Claude Code
# ============================================================
if ((Test-Path -LiteralPath (Join-Path $HOME '.claude')) -or (Test-CommandExists 'claude')) {
    Write-Ok 'Claude Code found'
    $ClaudeSkills   = Join-Path $HOME '.claude\skills'
    $ClaudeCommands = Join-Path $HOME '.claude\commands'
    $ClaudeAgents   = Join-Path $HOME '.claude\agents'
    $ClaudeHooksDir = Join-Path $HOME '.claude'

    if (-not $DryRun) {
        Ensure-Directory $ClaudeSkills
        Ensure-Directory $ClaudeCommands
        Ensure-Directory $ClaudeAgents
    }

    Copy-FileSafe -Source $SharedContext -Destination (Join-Path $HOME '.claude\BMAD-SHARED-CONTEXT.md')

    if ($DryRun) {
        Write-Host "  [DRY] remove legacy flat skill files and bmad-* folders from $ClaudeSkills\"
    } else {
        Remove-LegacyFlatSkills -SkillsDir $ClaudeSkills
    }

    Get-ChildItem -LiteralPath $AgentsDir -Directory | ForEach-Object {
        Install-AgentSkillFolder -AgentDir $_.FullName -SkillsRoot $ClaudeSkills
    }

    # Deploy Claude Code subagent definitions to ~/.claude/agents/
    $ClaudeSubagentsSrc = Join-Path $RulesDir 'claude\agents'
    if (Test-Path -LiteralPath $ClaudeSubagentsSrc) {
        Get-ChildItem -LiteralPath $ClaudeSubagentsSrc -Filter '*.md' -File | ForEach-Object {
            $dst = Join-Path $ClaudeAgents $_.Name
            if ($DryRun) {
                Write-Host "  [DRY] cp $($_.FullName) -> $dst"
            } else {
                Copy-Item -LiteralPath $_.FullName -Destination $dst -Force
                Write-Host "  ✓ Installed subagent: $([IO.Path]::GetFileNameWithoutExtension($_.Name))"
            }
        }
    }

    Walk-SubAgents -Handler $Install_Native -DestBase $ClaudeCommands

    # Merge hooks into ~/.claude/settings.json (backs up first)
    $hooksSettings = Join-Path $HooksDir 'settings.json'
    if (Test-Path -LiteralPath $hooksSettings) {
        Merge-SettingsJson -Source $hooksSettings -Destination (Join-Path $ClaudeHooksDir 'settings.json')
        # The python dedup helper isn't present on Windows by default; skip silently if python isn't available
        $dedup = Join-Path $ScriptDir 'clean-duplicate-hooks.py'
        if ((Test-Path -LiteralPath $dedup) -and (Test-CommandExists 'python')) {
            & python $dedup (Join-Path $ClaudeHooksDir 'settings.json') 2>$null | Out-Null
        }
    }

    # Copy hook scripts
    $hooksScripts = Join-Path $HooksDir 'scripts'
    if (Test-Path -LiteralPath $hooksScripts) {
        if ($DryRun) {
            Write-Host "  [DRY] copy $hooksScripts\ -> $ClaudeHooksDir\hooks\"
        } else {
            $dstHooks = Join-Path $ClaudeHooksDir 'hooks'
            Ensure-Directory $dstHooks
            Get-ChildItem -LiteralPath $hooksScripts -Recurse -File | ForEach-Object {
                $relative = $_.FullName.Substring($hooksScripts.Length).TrimStart('\','/')
                $target   = Join-Path $dstHooks $relative
                Ensure-Directory (Split-Path -Parent $target)
                Copy-Item -LiteralPath $_.FullName -Destination $target -Force
            }
        }
    }

    Write-Host "  Skills:    $ClaudeSkills\"
    Write-Host "  Subagents: $ClaudeAgents\"
    Write-Host "  Commands:  $ClaudeCommands\"
    Write-Host "  Hooks:     $ClaudeHooksDir\hooks\"
    $InstalledTools.Add('Claude Code') | Out-Null
    Write-Host ''
}

# ============================================================
# Cowork
# ============================================================
if (Test-Path -LiteralPath (Join-Path $HOME '.skills')) {
    Write-Ok 'Cowork found'
    $CoworkSkills = Join-Path $HOME '.skills\skills'
    if (-not $DryRun) { Ensure-Directory $CoworkSkills; Remove-LegacyFlatSkills -SkillsDir $CoworkSkills }

    Get-ChildItem -LiteralPath $AgentsDir -Directory | ForEach-Object {
        Install-AgentSkillFolder -AgentDir $_.FullName -SkillsRoot $CoworkSkills
    }

    Copy-FileSafe -Source $SharedContext -Destination (Join-Path $HOME '.skills\BMAD-SHARED-CONTEXT.md')

    $CoworkCommands = Join-Path $HOME '.skills\commands'
    Walk-SubAgents -Handler $Install_Native -DestBase $CoworkCommands

    Write-Host "  Skills:   $CoworkSkills\"
    Write-Host "  Commands: $CoworkCommands\"
    $InstalledTools.Add('Cowork') | Out-Null
    Write-Host ''
}

# ============================================================
# Codex CLI (OpenAI)
# ============================================================
if ((Test-Path -LiteralPath (Join-Path $HOME '.codex')) -or (Test-CommandExists 'codex')) {
    Write-Ok 'Codex CLI found'
    $CodexSkills  = Join-Path $HOME '.codex\skills'
    $CodexPrompts = Join-Path $HOME '.codex\prompts'

    if (-not $DryRun) {
        Ensure-Directory $CodexSkills
        Ensure-Directory $CodexPrompts
        if (Test-Path -LiteralPath $CodexSkills) { Remove-Item -LiteralPath $CodexSkills -Recurse -Force }
        Ensure-Directory $CodexSkills
    }

    Copy-FileSafe -Source $SharedContext -Destination (Join-Path $HOME '.codex\BMAD-SHARED-CONTEXT.md')

    $nSkills = 0
    foreach ($agentItem in (Get-ChildItem -LiteralPath $AgentsDir -Directory)) {
        $agentName  = $agentItem.Name
        $personaDir = Join-Path $CodexSkills $agentName
        if ($DryRun) {
            Write-Host "  [DRY] $personaDir\SKILL.md  (persona)"
        } else {
            Ensure-Directory $personaDir
            Copy-Item -LiteralPath (Join-Path $agentItem.FullName 'SKILL.md') -Destination (Join-Path $personaDir 'SKILL.md') -Force
        }
        $nSkills++

        foreach ($cmdFile in (Get-ChildItem -LiteralPath $agentItem.FullName -Filter '*.md' -File)) {
            $cmdName = [IO.Path]::GetFileNameWithoutExtension($cmdFile.Name)
            if ($cmdName -eq 'SKILL') { continue }
            $skillDir = Join-Path $CodexSkills "$agentName-$cmdName"
            if ($DryRun) {
                Write-Host "  [DRY] $skillDir\SKILL.md"
            } else {
                Ensure-Directory $skillDir
                Copy-Item -LiteralPath $cmdFile.FullName -Destination (Join-Path $skillDir 'SKILL.md') -Force
            }
            $nSkills++
        }
    }
    Write-Host "  Skills:   $CodexSkills\  ($nSkills flat skill folders)"
    Write-Host '  Layout:   skills\<agent>\SKILL.md  +  skills\<agent>-<cmd>\SKILL.md'
    $InstalledTools.Add('Codex CLI') | Out-Null
    Write-Host ''
}

# ============================================================
# Kiro (AWS)
# ============================================================
if ((Test-Path -LiteralPath (Join-Path $HOME '.kiro')) -or (Test-CommandExists 'kiro')) {
    Write-Ok 'Kiro found'
    $KiroSkills   = Join-Path $HOME '.kiro\skills'
    $KiroSteering = Join-Path $HOME '.kiro\steering'

    if (-not $DryRun) {
        Ensure-Directory $KiroSteering
        Get-ChildItem -LiteralPath $AgentsDir -Directory | ForEach-Object {
            $agentName = $_.Name
            # Remove agent-named and agent-prefixed skill folders
            if (Test-Path -LiteralPath $KiroSkills) {
                Get-ChildItem -LiteralPath $KiroSkills -Directory -ErrorAction SilentlyContinue | Where-Object {
                    $_.Name -eq $agentName -or $_.Name -like "$agentName-*"
                } | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force }
            }
            # Remove legacy steering files
            Get-ChildItem -LiteralPath $KiroSteering -Filter "$agentName-*.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Force
                Write-Host "  ✓ Removed legacy steering: $($_.Name)"
            }
        }
        Ensure-Directory $KiroSkills
    }

    # Shared context as always-included steering file
    if ($DryRun) {
        Write-Host "  [DRY] $KiroSteering\bmad-shared-context.md  (inclusion: always)"
    } else {
        $shared = Get-Content -LiteralPath $SharedContext -Raw
        $content = @(
            '---'
            'inclusion: always'
            'description: BMAD shared context — organization standards and conventions'
            '---'
            ''
            $shared
        ) -join "`n"
        Set-Utf8 -Path (Join-Path $KiroSteering 'bmad-shared-context.md') -Content $content
    }

    $nKiro = 0
    foreach ($agentItem in (Get-ChildItem -LiteralPath $AgentsDir -Directory)) {
        $agentName = $agentItem.Name
        Write-KiroSkill -SkillName $agentName -Source (Join-Path $agentItem.FullName 'SKILL.md') -SkillsDir $KiroSkills
        $nKiro++

        foreach ($cmdFile in (Get-ChildItem -LiteralPath $agentItem.FullName -Filter '*.md' -File)) {
            $cmdName = [IO.Path]::GetFileNameWithoutExtension($cmdFile.Name)
            if ($cmdName -eq 'SKILL') { continue }
            Write-KiroSkill -SkillName "$agentName-$cmdName" -Source $cmdFile.FullName -SkillsDir $KiroSkills
            $nKiro++
        }
    }

    Write-Host "  Skills:   $KiroSkills\  ($nKiro flat skill folders)"
    Write-Host "  Steering: $KiroSteering\bmad-shared-context.md  (inclusion: always)"
    Write-Host '  Invoke:   /tech-lead,  /tech-lead-code-review,  /product-owner-create-brd,  etc.'
    $InstalledTools.Add('Kiro') | Out-Null
    Write-Host ''
}

# ============================================================
# Cursor
# ============================================================
if ((Test-Path -LiteralPath (Join-Path $HOME '.cursor')) -or (Test-CommandExists 'cursor')) {
    Write-Ok 'Cursor found'
    $CursorRules  = Join-Path $HOME '.cursor\rules'
    $CursorSkills = Join-Path $HOME '.cursor\skills'
    if (-not $DryRun) { Ensure-Directory $CursorRules; Ensure-Directory $CursorSkills }

    Get-ChildItem -LiteralPath $AgentsDir -Directory | ForEach-Object {
        $agentName = $_.Name
        Prepend-SharedContext -AgentFile (Join-Path $_.FullName 'SKILL.md') -OutputFile (Join-Path $CursorRules "$agentName.md")
        if (-not $DryRun) {
            $target = Join-Path $CursorSkills $agentName
            Ensure-Directory $target
            $refs = Join-Path $_.FullName 'references'
            if (Test-Path -LiteralPath $refs) { Copy-Item -LiteralPath $refs -Destination $target -Recurse -Force }
            $tpls = Join-Path $_.FullName 'templates'
            if (Test-Path -LiteralPath $tpls) { Copy-Item -LiteralPath $tpls -Destination $target -Recurse -Force }
        }
    }

    $CursorCommands = Join-Path $HOME '.cursor\commands'
    Walk-SubAgents -Handler $Adapt_Cursor -DestBase $CursorCommands

    $cursorGlobal = Join-Path $RulesDir 'cursor\global'
    if (Test-Path -LiteralPath $cursorGlobal) {
        Get-ChildItem -LiteralPath $cursorGlobal -Filter '*.mdc' -File | ForEach-Object {
            Copy-FileSafe -Source $_.FullName -Destination (Join-Path $CursorRules $_.Name)
        }
    }

    # Register the repo's .cursor-plugin/plugin.json
    $cursorPluginDir = Join-Path $HOME '.cursor\plugins\bmad-sdlc'
    $srcPlugin = Join-Path $BaseDir '.cursor-plugin\plugin.json'
    if (Test-Path -LiteralPath $srcPlugin) {
        if ($DryRun) {
            Write-Host "  [DRY] register plugin -> $cursorPluginDir\plugin.json"
        } else {
            Ensure-Directory $cursorPluginDir
            $dstPlugin = Join-Path $cursorPluginDir 'plugin.json'
            # Patch relative paths to absolute repo paths, similar to the bash sed
            $text = Get-Content -LiteralPath $srcPlugin -Raw
            $agentsForward   = ($AgentsDir   -replace '\\','/')
            $commandsForward = ($CommandsDir -replace '\\','/')
            $hooksForward    = ((Join-Path $BaseDir 'hooks\global\settings.json') -replace '\\','/')
            $text = $text.Replace('"./agents/"',                 "`"$agentsForward/`"")
            $text = $text.Replace('"./commands/"',               "`"$commandsForward/`"")
            $text = $text.Replace('"./hooks/global/settings.json"', "`"$hooksForward`"")
            Set-Utf8 -Path $dstPlugin -Content $text
        }
    }

    Write-Host "  Rules:    $CursorRules\"
    Write-Host "  Skills:   $CursorSkills\"
    Write-Host "  Commands: $CursorCommands\"
    Write-Host "  Plugin:   $cursorPluginDir\plugin.json"
    $InstalledTools.Add('Cursor') | Out-Null
    Write-Host ''
}

# ============================================================
# Windsurf
# ============================================================
if (Test-Path -LiteralPath (Join-Path $HOME '.windsurf')) {
    Write-Ok 'Windsurf found'
    $WindsurfRules  = Join-Path $HOME '.windsurf\rules'
    $WindsurfSkills = Join-Path $HOME '.windsurf\skills'
    if (-not $DryRun) { Ensure-Directory $WindsurfRules; Ensure-Directory $WindsurfSkills }

    Get-ChildItem -LiteralPath $AgentsDir -Directory | ForEach-Object {
        $agentName = $_.Name
        Prepend-SharedContext -AgentFile (Join-Path $_.FullName 'SKILL.md') -OutputFile (Join-Path $WindsurfRules "$agentName.md")
        if (-not $DryRun) {
            $target = Join-Path $WindsurfSkills $agentName
            Ensure-Directory $target
            $refs = Join-Path $_.FullName 'references'
            if (Test-Path -LiteralPath $refs) { Copy-Item -LiteralPath $refs -Destination $target -Recurse -Force }
            $tpls = Join-Path $_.FullName 'templates'
            if (Test-Path -LiteralPath $tpls) { Copy-Item -LiteralPath $tpls -Destination $target -Recurse -Force }
        }
    }

    $windsurfGlobal = Join-Path $RulesDir 'windsurf\global'
    if (Test-Path -LiteralPath $windsurfGlobal) {
        Get-ChildItem -LiteralPath $windsurfGlobal -Filter '*.md' -File | ForEach-Object {
            Copy-FileSafe -Source $_.FullName -Destination (Join-Path $WindsurfRules $_.Name)
        }
    }

    $WindsurfCommands = Join-Path $HOME '.windsurf\rules\bmad-commands'
    Walk-SubAgents -Handler $Adapt_Windsurf -DestBase $WindsurfCommands

    Write-Host "  Rules:    $WindsurfRules\"
    Write-Host "  Skills:   $WindsurfSkills\"
    Write-Host "  Commands: $WindsurfCommands\"
    $InstalledTools.Add('Windsurf') | Out-Null
    Write-Host ''
}

# ============================================================
# Trae IDE (ByteDance) — rules-based, same paradigm as Windsurf/Cursor.
# ============================================================
if ((Test-Path -LiteralPath (Join-Path $HOME '.trae')) -or (Test-CommandExists 'trae')) {
    Write-Ok 'Trae IDE found'
    $TraeRules  = Join-Path $HOME '.trae\rules'
    $TraeSkills = Join-Path $HOME '.trae\skills'
    if (-not $DryRun) { Ensure-Directory $TraeRules; Ensure-Directory $TraeSkills }

    Copy-FileSafe -Source $SharedContext -Destination (Join-Path $HOME '.trae\BMAD-SHARED-CONTEXT.md')

    Get-ChildItem -LiteralPath $AgentsDir -Directory | ForEach-Object {
        $agentName = $_.Name
        Prepend-SharedContext -AgentFile (Join-Path $_.FullName 'SKILL.md') -OutputFile (Join-Path $TraeRules "$agentName.md")
        if (-not $DryRun) {
            $target = Join-Path $TraeSkills $agentName
            Ensure-Directory $target
            $refs = Join-Path $_.FullName 'references'
            if (Test-Path -LiteralPath $refs) { Copy-Item -LiteralPath $refs -Destination $target -Recurse -Force }
            $tpls = Join-Path $_.FullName 'templates'
            if (Test-Path -LiteralPath $tpls) { Copy-Item -LiteralPath $tpls -Destination $target -Recurse -Force }
        }
    }

    # Framework seed: install twice — as 000-bmad-framework.md (sorts first) and user_rules.md (Trae canonical path)
    $traeGlobal = Join-Path $RulesDir 'trae\global'
    if (Test-Path -LiteralPath $traeGlobal) {
        Get-ChildItem -LiteralPath $traeGlobal -Filter '*.md' -File | ForEach-Object {
            Copy-FileSafe -Source $_.FullName -Destination (Join-Path $TraeRules "000-$($_.Name)")
            if ($_.Name -eq 'bmad-framework.md') {
                Copy-FileSafe -Source $_.FullName -Destination (Join-Path $TraeRules 'user_rules.md')
            }
        }
    }

    $TraeCommands = Join-Path $HOME '.trae\rules\bmad-commands'
    Walk-SubAgents -Handler $Adapt_Trae -DestBase $TraeCommands

    Write-Host "  Rules:    $TraeRules\"
    Write-Host "  Skills:   $TraeSkills\"
    Write-Host "  Commands: $TraeCommands\"
    $InstalledTools.Add('Trae IDE') | Out-Null
    Write-Host ''
}

# ============================================================
# GitHub Copilot
# ============================================================
if (Test-Path -LiteralPath (Join-Path $HOME '.github')) {
    Write-Ok 'GitHub Copilot found'
    $CopilotInstructions = Join-Path $HOME '.github\copilot-instructions.md'
    $CopilotSkills       = Join-Path $HOME '.github\bmad-skills'

    if ($DryRun) {
        Write-Host "  [DRY] append all agents -> $CopilotInstructions"
        $copilotGlobal = Join-Path $RulesDir 'copilot\global'
        if (Test-Path -LiteralPath $copilotGlobal) {
            Write-Host "  [DRY] append copilot global rules -> $CopilotInstructions"
        }
    } else {
        Ensure-Directory (Split-Path -Parent $CopilotInstructions)
        Ensure-Directory $CopilotSkills
        $sb = New-Object System.Text.StringBuilder
        if (Test-Path -LiteralPath $CopilotInstructions) {
            [void]$sb.Append((Get-Content -LiteralPath $CopilotInstructions -Raw))
            [void]$sb.AppendLine()
        }
        [void]$sb.Append((Get-Content -LiteralPath $SharedContext -Raw))
        Get-ChildItem -LiteralPath $AgentsDir -Directory | ForEach-Object {
            [void]$sb.AppendLine()
            [void]$sb.Append((Get-Content -LiteralPath (Join-Path $_.FullName 'SKILL.md') -Raw))
        }
        $copilotGlobal = Join-Path $RulesDir 'copilot\global'
        if (Test-Path -LiteralPath $copilotGlobal) {
            Get-ChildItem -LiteralPath $copilotGlobal -Filter '*.md' -File | ForEach-Object {
                [void]$sb.AppendLine()
                [void]$sb.Append((Get-Content -LiteralPath $_.FullName -Raw))
            }
        }
        Set-Utf8 -Path $CopilotInstructions -Content $sb.ToString()

        # references/ + templates/ to parallel skills directory
        Get-ChildItem -LiteralPath $AgentsDir -Directory | ForEach-Object {
            $target = Join-Path $CopilotSkills $_.Name
            Ensure-Directory $target
            $refs = Join-Path $_.FullName 'references'
            if (Test-Path -LiteralPath $refs) { Copy-Item -LiteralPath $refs -Destination $target -Recurse -Force }
            $tpls = Join-Path $_.FullName 'templates'
            if (Test-Path -LiteralPath $tpls) { Copy-Item -LiteralPath $tpls -Destination $target -Recurse -Force }
        }
    }

    $CopilotCommands = Join-Path $HOME '.github\bmad-commands'
    Walk-SubAgents -Handler $Install_Native -DestBase $CopilotCommands

    Write-Host "  Instructions: $CopilotInstructions"
    Write-Host "  Skills:       $CopilotSkills\"
    Write-Host "  Commands:     $CopilotCommands\"
    $InstalledTools.Add('GitHub Copilot') | Out-Null
    Write-Host ''
}

# ============================================================
# Gemini CLI — extensions + native subagents
# ============================================================
if ((Test-Path -LiteralPath (Join-Path $HOME '.gemini')) -or (Test-CommandExists 'gemini')) {
    Write-Ok 'Gemini CLI found'
    $GeminiExtensionsDir = Join-Path $HOME '.gemini\extensions'

    if (-not $DryRun) {
        # Remove legacy installs
        $legacyCandidates = @(
            (Join-Path $HOME '.gemini\BMAD-SHARED-CONTEXT.md'),
            (Join-Path $GeminiExtensionsDir 'bmad-sdlc'),
            (Join-Path $GeminiExtensionsDir 'bmad')
        )
        Get-ChildItem -LiteralPath (Join-Path $HOME '.gemini\skills') -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like 'bmad-*' } |
            ForEach-Object { $legacyCandidates += $_.FullName }
        Get-ChildItem -LiteralPath $AgentsDir -Directory | ForEach-Object {
            $legacyCandidates += (Join-Path $HOME ".gemini\skills\$($_.Name)")
        }
        foreach ($legacy in $legacyCandidates) {
            if (Test-Path -LiteralPath $legacy) {
                Remove-Item -LiteralPath $legacy -Recurse -Force
                Write-Host "  ✓ Removed legacy: $(Split-Path -Leaf $legacy)"
            }
        }
    }

    # Deploy one extension per agent (skip the bmad orchestrator)
    Get-ChildItem -LiteralPath $AgentsDir -Directory | ForEach-Object {
        $agentName = $_.Name
        if ($agentName -eq 'bmad') { return }
        $extName = "bmad-$agentName"
        $extDir  = Join-Path $GeminiExtensionsDir $extName

        if ($DryRun) {
            Write-Host "  [DRY] /$extName :"
            Write-Host "  [DRY]   :$agentName  ->  skills\$agentName\SKILL.md  (persona)"
            Get-ChildItem -LiteralPath $_.FullName -Filter '*.md' -File | ForEach-Object {
                $cmdName = [IO.Path]::GetFileNameWithoutExtension($_.Name)
                if ($cmdName -eq 'SKILL') { return }
                Write-Host "  [DRY]   :$cmdName  ->  skills\$cmdName\SKILL.md"
            }
            return
        }

        # Wipe clean
        if (Test-Path -LiteralPath $extDir) { Remove-Item -LiteralPath $extDir -Recurse -Force }
        Ensure-Directory (Join-Path $extDir 'skills')

        # gemini-extension.json
        $description = Get-FrontmatterField -FilePath (Join-Path $_.FullName 'SKILL.md') -Field 'description'
        $extJson = @{
            name            = $extName
            description     = $description
            version         = '1.0.0'
            contextFileName = 'GEMINI.md'
        } | ConvertTo-Json -Depth 10
        Set-Utf8 -Path (Join-Path $extDir 'gemini-extension.json') -Content $extJson

        # Persona → skills/<agent>/SKILL.md
        $personaDir = Join-Path $extDir "skills\$agentName"
        Ensure-Directory $personaDir
        Copy-Item -LiteralPath (Join-Path $_.FullName 'SKILL.md') -Destination (Join-Path $personaDir 'SKILL.md') -Force

        # Commands → skills/<cmd>/SKILL.md
        $geminiLines = New-Object System.Collections.Generic.List[string]
        $geminiLines.Add("@./skills/$agentName/SKILL.md")
        Get-ChildItem -LiteralPath $_.FullName -Filter '*.md' -File | ForEach-Object {
            $cmdName = [IO.Path]::GetFileNameWithoutExtension($_.Name)
            if ($cmdName -eq 'SKILL') { return }
            $cmdDir = Join-Path $extDir "skills\$cmdName"
            Ensure-Directory $cmdDir
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $cmdDir 'SKILL.md') -Force
            $geminiLines.Add("@./skills/$cmdName/SKILL.md")
        }

        # Append global rules
        $geminiGlobal = Join-Path $RulesDir 'gemini\global'
        if (Test-Path -LiteralPath $geminiGlobal) {
            Get-ChildItem -LiteralPath $geminiGlobal -Filter '*.md' -File | ForEach-Object {
                $geminiLines.Add('')
                $geminiLines.Add((Get-Content -LiteralPath $_.FullName -Raw))
            }
        }
        Set-Utf8 -Path (Join-Path $extDir 'GEMINI.md') -Content ($geminiLines -join "`n")

        $nCmds = (Get-ChildItem -LiteralPath (Join-Path $extDir 'skills') -Directory).Count
        Write-Host "  ✓ /$extName  ($nCmds commands)"
    }

    Write-Host "  Extensions:  $GeminiExtensionsDir\bmad-*\"
    Write-Host '  Invoke:      /bmad-product-owner:create-brd,  /bmad-tech-lead:code-review,  etc.'
    Write-Host '  Register:    for each extension, run: gemini extensions install <path>'

    # Native subagents
    $geminiSubSrc = Join-Path $RulesDir 'gemini\agents'
    $geminiSubDst = Join-Path $HOME '.gemini\agents'
    if (Test-Path -LiteralPath $geminiSubSrc) {
        if ($DryRun) {
            Get-ChildItem -LiteralPath $geminiSubSrc -Filter '*.md' -File | ForEach-Object {
                Write-Host "  [DRY] subagent $($_.Name) -> $geminiSubDst\"
            }
        } else {
            Ensure-Directory $geminiSubDst
            $nSub = 0
            foreach ($subFile in (Get-ChildItem -LiteralPath $geminiSubSrc -Filter '*.md' -File)) {
                Copy-Item -LiteralPath $subFile.FullName -Destination (Join-Path $geminiSubDst $subFile.Name) -Force
                $nSub++
            }
            Write-Host "  ✓ Subagents:  $geminiSubDst\  ($nSub files)"
            Write-Host '  Invoke:       @backend-engineer …, @tech-lead …, @product-owner …'
            Write-Host '  Manage:       /agents  (inside gemini)'
        }
    }

    $InstalledTools.Add('Gemini CLI') | Out-Null
    Write-Host ''
}

# ============================================================
# OpenCode
# ============================================================
if ((Test-Path -LiteralPath (Join-Path $HOME '.opencode')) -or (Test-CommandExists 'opencode')) {
    Write-Ok 'OpenCode found'
    $OpencodeInstructions = Join-Path $HOME '.opencode\instructions.md'

    if ($DryRun) {
        Write-Host "  [DRY] create with shared context + all agents -> $OpencodeInstructions"
    } else {
        Ensure-Directory (Split-Path -Parent $OpencodeInstructions)
        $sb = New-Object System.Text.StringBuilder
        [void]$sb.Append((Get-Content -LiteralPath $SharedContext -Raw))
        Get-ChildItem -LiteralPath $AgentsDir -Directory | ForEach-Object {
            [void]$sb.AppendLine()
            [void]$sb.Append((Get-Content -LiteralPath (Join-Path $_.FullName 'SKILL.md') -Raw))
        }
        $opencodeGlobal = Join-Path $RulesDir 'opencode\global'
        if (Test-Path -LiteralPath $opencodeGlobal) {
            Get-ChildItem -LiteralPath $opencodeGlobal -Filter '*.md' -File | ForEach-Object {
                [void]$sb.AppendLine()
                [void]$sb.Append((Get-Content -LiteralPath $_.FullName -Raw))
            }
        }
        Set-Utf8 -Path $OpencodeInstructions -Content $sb.ToString()
    }

    $OpencodeSkills = Join-Path $HOME '.opencode\bmad-skills'
    Get-ChildItem -LiteralPath $AgentsDir -Directory | ForEach-Object {
        $target = Join-Path $OpencodeSkills $_.Name
        if ($DryRun) {
            Write-Host "  [DRY] copy refs/templates -> $target\"
        } else {
            Ensure-Directory $target
            $refs = Join-Path $_.FullName 'references'
            if (Test-Path -LiteralPath $refs) { Copy-Item -LiteralPath $refs -Destination $target -Recurse -Force }
            $tpls = Join-Path $_.FullName 'templates'
            if (Test-Path -LiteralPath $tpls) { Copy-Item -LiteralPath $tpls -Destination $target -Recurse -Force }
        }
    }

    $OpencodeCommands = Join-Path $HOME '.opencode\commands'
    Walk-SubAgents -Handler $Install_Native -DestBase $OpencodeCommands

    Write-Host "  Instructions: $OpencodeInstructions"
    Write-Host "  Skills:       $OpencodeSkills\"
    Write-Host "  Commands:     $OpencodeCommands\"
    $InstalledTools.Add('OpenCode') | Out-Null
    Write-Host ''
}

# ============================================================
# Aider
# ============================================================
if ((Test-Path -LiteralPath (Join-Path $HOME '.aider')) -or (Test-CommandExists 'aider')) {
    Write-Ok 'Aider found'
    $AiderConventions = Join-Path $HOME '.aider.conventions.md'

    if ($DryRun) {
        Write-Host "  [DRY] append shared context to $AiderConventions"
    } else {
        Ensure-Directory (Split-Path -Parent $AiderConventions)
        if (-not (Test-Path -LiteralPath $AiderConventions)) {
            Copy-Item -LiteralPath $SharedContext -Destination $AiderConventions -Force
        } else {
            Add-Utf8 -Path $AiderConventions -Content "`n$(Get-Content -LiteralPath $SharedContext -Raw)"
        }
        $aiderGlobal = Join-Path $RulesDir 'aider\global'
        if (Test-Path -LiteralPath $aiderGlobal) {
            Get-ChildItem -LiteralPath $aiderGlobal -Filter '*.md' -File | ForEach-Object {
                Add-Utf8 -Path $AiderConventions -Content "`n$(Get-Content -LiteralPath $_.FullName -Raw)"
            }
        }
    }

    $AiderSkills = Join-Path $HOME '.aider\bmad-skills'
    Get-ChildItem -LiteralPath $AgentsDir -Directory | ForEach-Object {
        $target = Join-Path $AiderSkills $_.Name
        if ($DryRun) {
            Write-Host "  [DRY] copy refs/templates -> $target\"
        } else {
            Ensure-Directory $target
            $refs = Join-Path $_.FullName 'references'
            if (Test-Path -LiteralPath $refs) { Copy-Item -LiteralPath $refs -Destination $target -Recurse -Force }
            $tpls = Join-Path $_.FullName 'templates'
            if (Test-Path -LiteralPath $tpls) { Copy-Item -LiteralPath $tpls -Destination $target -Recurse -Force }
        }
    }

    Walk-SubAgents -Handler $Adapt_Aider -DestBase $AiderConventions

    Write-Host "  Conventions:  $AiderConventions"
    Write-Host "  Skills:       $AiderSkills\"
    $InstalledTools.Add('Aider') | Out-Null
    Write-Host ''
}

# ============================================================
# Karpathy-Style Coding Principles — per detected tool
# ============================================================
$KarpathyDir = Join-Path $BaseDir 'shared\karpathy-principles'

function Append-Karpathy {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$Marker
    )
    if ($DryRun) {
        Write-Host "  [DRY] append $Source -> $Destination"
        return
    }
    Ensure-Directory (Split-Path -Parent $Destination)
    if ((Test-Path -LiteralPath $Destination) -and (Select-String -LiteralPath $Destination -Pattern $Marker -Quiet)) {
        return  # already installed
    }
    if (Test-Path -LiteralPath $Destination) {
        Add-Utf8 -Path $Destination -Content ''
    }
    Add-Utf8 -Path $Destination -Content (Get-Content -LiteralPath $Source -Raw)
}

if (Test-Path -LiteralPath $KarpathyDir) {
    Write-Section 'Installing Karpathy-style coding principles...'

    if ((Test-Path -LiteralPath (Join-Path $HOME '.claude')) -or (Test-CommandExists 'claude')) {
        Copy-FileSafe -Source (Join-Path $KarpathyDir 'claude-code.md') -Destination (Join-Path $HOME '.claude\KARPATHY-PRINCIPLES.md')
        Write-Host '  ✓ Claude Code    -> ~\.claude\KARPATHY-PRINCIPLES.md' -ForegroundColor Green
    }
    if (Test-Path -LiteralPath (Join-Path $HOME '.skills')) {
        Copy-FileSafe -Source (Join-Path $KarpathyDir 'cowork.md') -Destination (Join-Path $HOME '.skills\KARPATHY-PRINCIPLES.md')
        Write-Host '  ✓ Cowork         -> ~\.skills\KARPATHY-PRINCIPLES.md' -ForegroundColor Green
    }
    if ((Test-Path -LiteralPath (Join-Path $HOME '.codex')) -or (Test-CommandExists 'codex')) {
        Copy-FileSafe -Source (Join-Path $KarpathyDir 'codex-cli.md') -Destination (Join-Path $HOME '.codex\KARPATHY-PRINCIPLES.md')
        Write-Host '  ✓ Codex CLI      -> ~\.codex\KARPATHY-PRINCIPLES.md' -ForegroundColor Green
    }
    if ((Test-Path -LiteralPath (Join-Path $HOME '.kiro')) -or (Test-CommandExists 'kiro')) {
        Copy-FileSafe -Source (Join-Path $KarpathyDir 'kiro.md') -Destination (Join-Path $HOME '.kiro\steering\karpathy-principles.md')
        Write-Host '  ✓ Kiro           -> ~\.kiro\steering\karpathy-principles.md' -ForegroundColor Green
    }
    if ((Test-Path -LiteralPath (Join-Path $HOME '.cursor')) -or (Test-CommandExists 'cursor')) {
        Copy-FileSafe -Source (Join-Path $KarpathyDir 'cursor.mdc') -Destination (Join-Path $HOME '.cursor\rules\001-karpathy-principles.mdc')
        Write-Host '  ✓ Cursor         -> ~\.cursor\rules\001-karpathy-principles.mdc' -ForegroundColor Green
    }
    if (Test-Path -LiteralPath (Join-Path $HOME '.windsurf')) {
        Copy-FileSafe -Source (Join-Path $KarpathyDir 'windsurf.md') -Destination (Join-Path $HOME '.windsurf\rules\001-karpathy-principles.md')
        Write-Host '  ✓ Windsurf       -> ~\.windsurf\rules\001-karpathy-principles.md' -ForegroundColor Green
    }
    if ((Test-Path -LiteralPath (Join-Path $HOME '.trae')) -or (Test-CommandExists 'trae')) {
        Copy-FileSafe -Source (Join-Path $KarpathyDir 'windsurf.md') -Destination (Join-Path $HOME '.trae\rules\001-karpathy-principles.md')
        Write-Host '  ✓ Trae IDE       -> ~\.trae\rules\001-karpathy-principles.md' -ForegroundColor Green
    }
    if (Test-Path -LiteralPath (Join-Path $HOME '.github')) {
        Append-Karpathy `
            -Source      (Join-Path $KarpathyDir 'copilot-instructions.md') `
            -Destination (Join-Path $HOME '.github\copilot-instructions.md') `
            -Marker      '^# GitHub Copilot — Coding Principles \(Karpathy-style\)'
        Write-Host '  ✓ GitHub Copilot -> ~\.github\copilot-instructions.md (appended)' -ForegroundColor Green
    }
    if ((Test-Path -LiteralPath (Join-Path $HOME '.gemini')) -or (Test-CommandExists 'gemini')) {
        Copy-FileSafe -Source (Join-Path $KarpathyDir 'gemini-cli.md') -Destination (Join-Path $HOME '.gemini\KARPATHY-PRINCIPLES.md')
        Write-Host '  ✓ Gemini CLI     -> ~\.gemini\KARPATHY-PRINCIPLES.md' -ForegroundColor Green
    }
    if ((Test-Path -LiteralPath (Join-Path $HOME '.opencode')) -or (Test-CommandExists 'opencode')) {
        Append-Karpathy `
            -Source      (Join-Path $KarpathyDir 'opencode.md') `
            -Destination (Join-Path $HOME '.opencode\instructions.md') `
            -Marker      '^# OpenCode — Coding Principles \(Karpathy-style\)'
        Write-Host '  ✓ OpenCode       -> ~\.opencode\instructions.md (appended)' -ForegroundColor Green
    }
    if ((Test-Path -LiteralPath (Join-Path $HOME '.aider')) -or (Test-CommandExists 'aider')) {
        Append-Karpathy `
            -Source      (Join-Path $KarpathyDir 'aider.md') `
            -Destination (Join-Path $HOME '.aider.conventions.md') `
            -Marker      '^# Aider — Coding Conventions \(Karpathy-style\)'
        Write-Host '  ✓ Aider          -> ~\.aider.conventions.md (appended)' -ForegroundColor Green
    }

    Write-Host "  Source:  $KarpathyDir\"
    Write-Host ''
}

# ============================================================
# A2UI Reference — per detected tool
# ============================================================
$A2uiRef = Join-Path $BaseDir 'shared\a2ui-reference.md'

if (Test-Path -LiteralPath $A2uiRef) {
    Write-Section 'Installing A2UI reference...'

    if ((Test-Path -LiteralPath (Join-Path $HOME '.claude')) -or (Test-CommandExists 'claude')) {
        Copy-FileSafe -Source $A2uiRef -Destination (Join-Path $HOME '.claude\A2UI-REFERENCE.md')
        Write-Host '  ✓ Claude Code    -> ~\.claude\A2UI-REFERENCE.md' -ForegroundColor Green
    }
    if (Test-Path -LiteralPath (Join-Path $HOME '.skills')) {
        Copy-FileSafe -Source $A2uiRef -Destination (Join-Path $HOME '.skills\A2UI-REFERENCE.md')
        Write-Host '  ✓ Cowork         -> ~\.skills\A2UI-REFERENCE.md' -ForegroundColor Green
    }
    if ((Test-Path -LiteralPath (Join-Path $HOME '.codex')) -or (Test-CommandExists 'codex')) {
        Copy-FileSafe -Source $A2uiRef -Destination (Join-Path $HOME '.codex\A2UI-REFERENCE.md')
        Write-Host '  ✓ Codex CLI      -> ~\.codex\A2UI-REFERENCE.md' -ForegroundColor Green
    }
    if ((Test-Path -LiteralPath (Join-Path $HOME '.kiro')) -or (Test-CommandExists 'kiro')) {
        Copy-FileSafe -Source $A2uiRef -Destination (Join-Path $HOME '.kiro\steering\a2ui-reference.md')
        Write-Host '  ✓ Kiro           -> ~\.kiro\steering\a2ui-reference.md' -ForegroundColor Green
    }
    if ((Test-Path -LiteralPath (Join-Path $HOME '.cursor')) -or (Test-CommandExists 'cursor')) {
        Copy-FileSafe -Source $A2uiRef -Destination (Join-Path $HOME '.cursor\rules\002-a2ui-reference.md')
        Write-Host '  ✓ Cursor         -> ~\.cursor\rules\002-a2ui-reference.md' -ForegroundColor Green
    }
    if (Test-Path -LiteralPath (Join-Path $HOME '.windsurf')) {
        Copy-FileSafe -Source $A2uiRef -Destination (Join-Path $HOME '.windsurf\rules\002-a2ui-reference.md')
        Write-Host '  ✓ Windsurf       -> ~\.windsurf\rules\002-a2ui-reference.md' -ForegroundColor Green
    }
    if ((Test-Path -LiteralPath (Join-Path $HOME '.trae')) -or (Test-CommandExists 'trae')) {
        Copy-FileSafe -Source $A2uiRef -Destination (Join-Path $HOME '.trae\rules\002-a2ui-reference.md')
        Write-Host '  ✓ Trae IDE       -> ~\.trae\rules\002-a2ui-reference.md' -ForegroundColor Green
    }
    if ((Test-Path -LiteralPath (Join-Path $HOME '.gemini')) -or (Test-CommandExists 'gemini')) {
        Copy-FileSafe -Source $A2uiRef -Destination (Join-Path $HOME '.gemini\A2UI-REFERENCE.md')
        Write-Host '  ✓ Gemini CLI     -> ~\.gemini\A2UI-REFERENCE.md' -ForegroundColor Green
    }
    if ((Test-Path -LiteralPath (Join-Path $HOME '.opencode')) -or (Test-CommandExists 'opencode')) {
        Copy-FileSafe -Source $A2uiRef -Destination (Join-Path $HOME '.opencode\A2UI-REFERENCE.md')
        Write-Host '  ✓ OpenCode       -> ~\.opencode\A2UI-REFERENCE.md' -ForegroundColor Green
    }
    if ((Test-Path -LiteralPath (Join-Path $HOME '.aider')) -or (Test-CommandExists 'aider')) {
        Copy-FileSafe -Source $A2uiRef -Destination (Join-Path $HOME '.aider\A2UI-REFERENCE.md')
        Write-Host '  ✓ Aider          -> ~\.aider\A2UI-REFERENCE.md' -ForegroundColor Green
    }

    Write-Host "  Source:  $A2uiRef"
    Write-Host ''
}

# ============================================================
# Eval Dashboard — deploy to ~/.bmad/eval/
# ============================================================
$EvalDir  = Join-Path $BaseDir 'eval'
$BmadHome = Join-Path $HOME '.bmad'

if (Test-Path -LiteralPath $EvalDir) {
    Write-Section 'Installing BMAD Eval Dashboard...'
    Get-ChildItem -LiteralPath $EvalDir -File | ForEach-Object {
        Copy-FileSafe -Source $_.FullName -Destination (Join-Path $BmadHome "eval\$($_.Name)")
        Write-Host "  ✓ $($_.Name) -> $BmadHome\eval\" -ForegroundColor Green
    }
    Write-Host "  Open $BmadHome\eval\bmad-agent-eval-dashboard.html in a browser to view."
    Write-Host ''
}

# ============================================================
# BMAD Diagnostic Scripts — deploy to ~/.bmad/scripts/
# ============================================================
$ScriptsSrcDir    = Join-Path $BaseDir 'scripts'
$BmadScriptsDir   = Join-Path $BmadHome 'scripts'
$DiagnosticScripts = @('check-playwright-env.sh', 'render-design-md.py')

$hasDiag = $false
foreach ($s in $DiagnosticScripts) {
    if (Test-Path -LiteralPath (Join-Path $ScriptsSrcDir $s)) { $hasDiag = $true; break }
}

if ($hasDiag) {
    Write-Section 'Installing BMAD diagnostic scripts...'
    foreach ($s in $DiagnosticScripts) {
        $src  = Join-Path $ScriptsSrcDir $s
        $dest = Join-Path $BmadScriptsDir $s
        if (Test-Path -LiteralPath $src) {
            Copy-FileSafe -Source $src -Destination $dest
            Write-Host "  ✓ $s -> $BmadScriptsDir\" -ForegroundColor Green
        }
    }
    Write-Host "  Invoke from any project:"
    Write-Host "    bash   $BmadScriptsDir\check-playwright-env.sh   (requires WSL / Git Bash)"
    Write-Host "    python $BmadScriptsDir\render-design-md.py --input docs\ux\DESIGN.md"
    Write-Host ''
}

# ============================================================
# MCP Configs — display guidance (not auto-installed)
# ============================================================
if (Test-Path -LiteralPath $McpConfigsDir) {
    Write-Section 'MCP Server Configs available:'
    Write-Host "  Source: $McpConfigsDir\"
    Write-Host ''
    Write-Host '  Merge the configs you need into your tool''s MCP settings:'
    Write-Host ''
    Get-ChildItem -LiteralPath $McpConfigsDir -Filter '*.json' -File | ForEach-Object {
        Write-Host "    * $($_.Name)"
    }
    Write-Host ''
    Write-Host '  Claude Code:  ~\.claude\claude_desktop_config.json'
    Write-Host '  Codex CLI:    ~\.codex\config.toml  (mcp_servers section)'
    Write-Host '  Kiro:         ~\.kiro\settings\mcp.json'
    Write-Host '  Cursor:       ~\.cursor\mcp.json'
    Write-Host '  Windsurf:     ~\.windsurf\mcp_config.json'
    Write-Host '  Trae IDE:     ~\.trae\mcp.json          (Settings -> MCP & Agents, or edit the file)'
    Write-Host '  Gemini CLI:   ~\.gemini\settings.json  (tools section)'
    Write-Host ''
    Write-Host "  See $BaseDir\mcp-configs\README.md for merge instructions."
    Write-Host ''
}

# ============================================================
# Tools not found
# ============================================================
Write-Section 'Tools not found:'
if (-not (Test-Path -LiteralPath (Join-Path $HOME '.claude')) -and -not (Test-CommandExists 'claude')) {
    Write-Fail 'Claude Code — not installed'
    $SkippedTools.Add('Claude Code') | Out-Null
}
if (-not (Test-Path -LiteralPath (Join-Path $HOME '.codex')) -and -not (Test-CommandExists 'codex')) {
    Write-Fail 'Codex CLI — not installed'
    $SkippedTools.Add('Codex CLI') | Out-Null
}
if (-not (Test-Path -LiteralPath (Join-Path $HOME '.kiro')) -and -not (Test-CommandExists 'kiro')) {
    Write-Fail 'Kiro — not installed'
    $SkippedTools.Add('Kiro') | Out-Null
}
if (-not (Test-Path -LiteralPath (Join-Path $HOME '.cursor')) -and -not (Test-CommandExists 'cursor')) {
    Write-Fail 'Cursor — not installed'
    $SkippedTools.Add('Cursor') | Out-Null
}
if (-not (Test-Path -LiteralPath (Join-Path $HOME '.windsurf'))) {
    Write-Fail 'Windsurf — not installed'
    $SkippedTools.Add('Windsurf') | Out-Null
}
if (-not (Test-Path -LiteralPath (Join-Path $HOME '.trae')) -and -not (Test-CommandExists 'trae')) {
    Write-Fail 'Trae IDE — not installed'
    $SkippedTools.Add('Trae IDE') | Out-Null
}
if (-not (Test-Path -LiteralPath (Join-Path $HOME '.github'))) {
    Write-Fail 'GitHub Copilot — config directory not found'
    $SkippedTools.Add('GitHub Copilot') | Out-Null
}
if (-not (Test-Path -LiteralPath (Join-Path $HOME '.gemini')) -and -not (Test-CommandExists 'gemini')) {
    Write-Fail 'Gemini CLI — not installed'
    $SkippedTools.Add('Gemini CLI') | Out-Null
}
if (-not (Test-Path -LiteralPath (Join-Path $HOME '.opencode')) -and -not (Test-CommandExists 'opencode')) {
    Write-Fail 'OpenCode — not installed'
    $SkippedTools.Add('OpenCode') | Out-Null
}
if (-not (Test-Path -LiteralPath (Join-Path $HOME '.aider')) -and -not (Test-CommandExists 'aider')) {
    Write-Fail 'Aider — not installed'
    $SkippedTools.Add('Aider') | Out-Null
}
if (-not (Test-Path -LiteralPath (Join-Path $HOME '.skills'))) {
    Write-Fail 'Cowork — not installed'
    $SkippedTools.Add('Cowork') | Out-Null
}

Write-Host ''
Write-Banner 'Summary'

if ($DryRun) {
    Write-Warn 'DRY RUN MODE - No files were actually written'
    Write-Host ''
}

Write-Host "Installed to $($InstalledTools.Count) tools:" -ForegroundColor Green
foreach ($tool in $InstalledTools) { Write-Host "  * $tool" }

Write-Host ''
Write-Host "Skipped $($SkippedTools.Count) tools:" -ForegroundColor Red
foreach ($tool in $SkippedTools) { Write-Host "  * $tool" }

Write-Host ''
Write-Host 'Next steps:'
Write-Host '  1. Review installed agent configurations'
Write-Host "  2. Review MCP configs in $BaseDir\mcp-configs\ and merge as needed"
Write-Host '  3. Run: .\scripts\scaffold-project.ps1 <project-name>   (or the .sh from WSL/Git Bash)'
Write-Host '  4. Teams fill in .bmad\*.md files in the project root'
Write-Host "  5. Open $BmadHome\eval\bmad-agent-eval-dashboard.html to track productivity"
Write-Host ''

exit 0
