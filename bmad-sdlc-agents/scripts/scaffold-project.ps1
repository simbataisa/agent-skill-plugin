<#
.SYNOPSIS
    BMAD Project Scaffolder (Windows PowerShell port of scaffold-project.sh).

.DESCRIPTION
    Initializes a new project in the current working directory with the BMAD
    structure, templates, project-level agent configuration, and an auto-load
    instruction file sized to whichever AI coding tool is detected.

    Supported detected tools: Claude Code, Codex CLI, Kiro, Cursor, Windsurf,
    Cowork. If none is detected, writes instruction files for all of them so
    the team can commit whichever they adopt.

.PARAMETER ProjectName
    Human-readable project name — substituted for the `[Project Name]`
    placeholder in every .bmad/ template.

.PARAMETER Force
    Overwrite an existing .bmad/ directory in the current location.

.EXAMPLE
    .\scripts\scaffold-project.ps1 "My Project"

.EXAMPLE
    .\scripts\scaffold-project.ps1 "My Project" -Force

.NOTES
    Run from the root of the target project directory.
    Windows PowerShell 5.1+ or PowerShell 7+.
#>

[CmdletBinding()]
param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$ProjectName,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# ─── Paths ────────────────────────────────────────────────────────────────────

$ScriptDir        = Split-Path -Parent $MyInvocation.MyCommand.Path
$BaseDir          = Split-Path -Parent $ScriptDir
$ScaffoldDir      = Join-Path $BaseDir 'project-scaffold'
$HooksProjectDir  = Join-Path $BaseDir 'hooks\project'
$RulesDirSrc      = Join-Path $BaseDir 'rules'
$McpProjectDir    = Join-Path $BaseDir 'mcp-configs\project'
$CommandsDir      = Join-Path $BaseDir 'commands'
$AgentsSrc        = Join-Path $BaseDir 'agents'
$SharedContext    = Join-Path $BaseDir 'shared\BMAD-SHARED-CONTEXT.md'

# ─── Pretty-print helpers ─────────────────────────────────────────────────────

function Write-Banner([string]$Text) {
    Write-Host ''
    Write-Host '========================================' -ForegroundColor Blue
    Write-Host "  $Text" -ForegroundColor Blue
    Write-Host '========================================' -ForegroundColor Blue
    Write-Host ''
}

function Write-Section([string]$Text) { Write-Host $Text -ForegroundColor Blue }
function Write-Ok     ([string]$Text) { Write-Host "✓ $Text" -ForegroundColor Green }
function Write-Fail   ([string]$Text) { Write-Host "✗ $Text" -ForegroundColor Red }
function Write-Warn   ([string]$Text) { Write-Host $Text -ForegroundColor Yellow }

function Test-CommandExists([string]$Name) {
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# ─── File helpers (UTF-8 no BOM, matches scaffold-project.sh byte-for-byte) ──

$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

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
    if (-not (Test-Path -LiteralPath $Path)) {
        [System.IO.File]::WriteAllText($Path, $Content, $script:Utf8NoBom)
    } else {
        [System.IO.File]::AppendAllText($Path, $Content, $script:Utf8NoBom)
    }
}

Write-Banner 'BMAD Project Scaffolder'
Write-Host "Project name: " -NoNewline
Write-Host $ProjectName -ForegroundColor Green
Write-Host ''

# ─── Validate scaffold source ────────────────────────────────────────────────

if (-not (Test-Path -LiteralPath (Join-Path $ScaffoldDir '.bmad'))) {
    Write-Fail "Error: Scaffold templates not found at $ScaffoldDir\.bmad"
    exit 1
}

# ─── Check .bmad/ collision ──────────────────────────────────────────────────

if ((Test-Path -LiteralPath '.bmad') -and -not $Force) {
    Write-Warn '⚠ Warning: .bmad directory already exists'
    Write-Host 'Use -Force to overwrite, or choose a different project directory'
    exit 1
}

if ($Force -and (Test-Path -LiteralPath '.bmad')) {
    Write-Warn 'Removing existing .bmad directory...'
    Remove-Item -LiteralPath '.bmad' -Recurse -Force
}

# ============================================================
# Create directory structure
# ============================================================
Write-Section 'Creating directories...'
$dirs = @(
    '.bmad\handoffs',
    '.bmad\signals',
    'docs\architecture\adr',
    'docs\analysis',
    'docs\stories',
    'docs\testing',
    'docs\ux',
    'tests\fixtures'
)
foreach ($d in $dirs) { Ensure-Directory $d }

Write-Host '  ✓ .bmad\'
Write-Host '  ✓ .bmad\handoffs\'
Write-Host '  ✓ .bmad\signals\ (autonomous orchestration sentinels)'
Write-Host '  ✓ docs\architecture\adr'
Write-Host '  ✓ docs\analysis\'
Write-Host '  ✓ docs\stories\'
Write-Host '  ✓ docs\testing\'
Write-Host '  ✓ docs\ux\'
Write-Host '  ✓ tests\fixtures\'
Write-Host ''

# ─── Hook-settings merger (native PS JSON, no python required) ───────────────

function Merge-SettingsJson {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )
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
        if ($null -eq $srcHooks) { return }

        if (-not $dst.PSObject.Properties['hooks']) {
            $dst | Add-Member -NotePropertyName 'hooks' -NotePropertyValue ([pscustomobject]@{}) -Force
        }
        foreach ($event in $srcHooks.PSObject.Properties.Name) {
            $srcEntries = $srcHooks.$event
            if (-not $dst.hooks.PSObject.Properties[$event]) {
                $dst.hooks | Add-Member -NotePropertyName $event -NotePropertyValue $srcEntries -Force
                continue
            }
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
        Set-Utf8 -Path $Destination -Content (($dst | ConvertTo-Json -Depth 100) + "`n")
        Write-Host "  ✓ Merged hooks into $(Split-Path -Leaf $Destination)"
    }
    catch {
        Copy-Item -LiteralPath $backup -Destination $Destination -Force
        Write-Fail "  Merge failed — restored from backup. Manually merge: $Source"
        Write-Fail "  Reason: $($_.Exception.Message)"
    }
}

function Replace-Placeholder([string]$File) {
    $text = Get-Content -LiteralPath $File -Raw
    $text = $text.Replace('[Project Name]', $ProjectName)
    Set-Utf8 -Path $File -Content $text
}

# ============================================================
# Copy and customize .bmad template files
# ============================================================
Write-Section 'Scaffolding .bmad templates...'

Get-ChildItem -LiteralPath (Join-Path $ScaffoldDir '.bmad') -Filter '*.md' -File | ForEach-Object {
    $dest = Join-Path '.bmad' $_.Name
    Copy-Item -LiteralPath $_.FullName -Destination $dest -Force
    Replace-Placeholder $dest
    Write-Host "  ✓ $($_.Name)"
}

$handoffTpl = Join-Path $ScaffoldDir '.bmad\handoffs\_template.md'
if (Test-Path -LiteralPath $handoffTpl) {
    Copy-Item -LiteralPath $handoffTpl -Destination '.bmad\handoffs\_template.md' -Force
    Write-Host '  ✓ handoffs\_template.md'
}

$evalSource = Join-Path $BaseDir 'eval\bmad-agent-eval-dashboard.html'
if (Test-Path -LiteralPath $evalSource) {
    Ensure-Directory '.bmad\eval'
    Copy-Item -LiteralPath $evalSource -Destination '.bmad\eval\bmad-agent-eval-dashboard.html' -Force
    Write-Host '  ✓ .bmad\eval\bmad-agent-eval-dashboard.html'
}

Write-Host ''

# ============================================================
# Detect current AI tool
# ============================================================
Write-Section 'Detecting AI coding tool...'

$DetectedTool = ''

if (     (Test-Path -LiteralPath (Join-Path $HOME '.claude'))   -or (Test-CommandExists 'claude'))  {
    $DetectedTool = 'claude';   Write-Ok 'Claude Code detected'
} elseif ((Test-Path -LiteralPath (Join-Path $HOME '.codex'))    -or (Test-CommandExists 'codex'))   {
    $DetectedTool = 'codex';    Write-Ok 'Codex CLI detected'
} elseif ((Test-Path -LiteralPath (Join-Path $HOME '.kiro'))     -or (Test-CommandExists 'kiro'))    {
    $DetectedTool = 'kiro';     Write-Ok 'Kiro detected'
} elseif ((Test-Path -LiteralPath (Join-Path $HOME '.cursor'))   -or (Test-CommandExists 'cursor'))  {
    $DetectedTool = 'cursor';   Write-Ok 'Cursor detected'
} elseif  (Test-Path -LiteralPath (Join-Path $HOME '.windsurf')) {
    $DetectedTool = 'windsurf'; Write-Ok 'Windsurf detected'
} elseif ((Test-Path -LiteralPath (Join-Path $HOME '.trae'))     -or (Test-CommandExists 'trae'))    {
    $DetectedTool = 'trae';     Write-Ok 'Trae IDE detected'
} elseif  (Test-Path -LiteralPath (Join-Path $HOME '.skills'))   {
    $DetectedTool = 'cowork';   Write-Ok 'Cowork detected'
} else {
    Write-Warn '⚠ No AI tool detected'
    $DetectedTool = 'none'
}

Write-Host ''

# ============================================================
# Install project-level agent skills/rules
# ============================================================
if ($DetectedTool -ne 'none') {
    Write-Section 'Installing project-level agents...'

    switch ($DetectedTool) {

        'claude' {
            $projectSkills   = '.claude\skills'
            $projectCommands = '.claude\commands'
            Ensure-Directory $projectSkills
            Ensure-Directory $projectCommands

            # Remove legacy flat .md files + bmad-* folders
            foreach ($agentItem in (Get-ChildItem -LiteralPath $AgentsSrc -Directory)) {
                $flat = Join-Path $projectSkills "$($agentItem.Name).md"
                if (Test-Path -LiteralPath $flat) {
                    Remove-Item -LiteralPath $flat -Force
                    Write-Host "  ✓ Removed legacy flat file: $($agentItem.Name).md"
                }
            }
            Get-ChildItem -LiteralPath $projectSkills -Directory -Filter 'bmad-*' -ErrorAction SilentlyContinue | ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Recurse -Force
                Write-Host "  ✓ Removed legacy skill folder: $($_.Name)"
            }

            # .claude/skills/<name>/SKILL.md
            foreach ($agentItem in (Get-ChildItem -LiteralPath $AgentsSrc -Directory)) {
                $target = Join-Path $projectSkills $agentItem.Name
                Ensure-Directory $target
                Copy-Item -LiteralPath (Join-Path $agentItem.FullName 'SKILL.md') -Destination (Join-Path $target 'SKILL.md') -Force
                Write-Host "  ✓ agent: $($agentItem.Name)"
            }

            if (Test-Path -LiteralPath $CommandsDir) {
                Get-ChildItem -LiteralPath $CommandsDir -Filter '*.md' -File | ForEach-Object {
                    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $projectCommands $_.Name) -Force
                    Write-Host "  ✓ command: $([IO.Path]::GetFileNameWithoutExtension($_.Name))"
                }
            }

            Write-Host "  Agents:   $projectSkills\"
            Write-Host "  Commands: $projectCommands\"
        }

        'codex' {
            $projectSkills  = '.codex\skills'
            $projectPrompts = '.codex\prompts'
            Ensure-Directory $projectSkills
            Ensure-Directory $projectPrompts

            Get-ChildItem -LiteralPath $projectSkills -Directory -Filter 'bmad-*' -ErrorAction SilentlyContinue | ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Recurse -Force
                Write-Host "  ✓ Removed legacy skill folder: $($_.Name)"
            }

            foreach ($agentItem in (Get-ChildItem -LiteralPath $AgentsSrc -Directory)) {
                $target = Join-Path $projectSkills $agentItem.Name
                Ensure-Directory $target
                Copy-Item -LiteralPath (Join-Path $agentItem.FullName 'SKILL.md') -Destination (Join-Path $target 'SKILL.md') -Force
                $refs = Join-Path $agentItem.FullName 'references'
                if (Test-Path -LiteralPath $refs) { Copy-Item -LiteralPath $refs -Destination $target -Recurse -Force }
                $tpls = Join-Path $agentItem.FullName 'templates'
                if (Test-Path -LiteralPath $tpls) { Copy-Item -LiteralPath $tpls -Destination $target -Recurse -Force }
                Write-Host "  ✓ skill: $($agentItem.Name)"
            }

            if (Test-Path -LiteralPath $CommandsDir) {
                Get-ChildItem -LiteralPath $CommandsDir -Filter '*.md' -File | ForEach-Object {
                    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $projectPrompts $_.Name) -Force
                    Write-Host "  ✓ prompt: $([IO.Path]::GetFileNameWithoutExtension($_.Name))"
                }
            }

            Write-Host "  Skills:  $projectSkills\"
            Write-Host "  Prompts: $projectPrompts\"
        }

        'kiro' {
            $projectSkills   = '.kiro\skills'
            $projectSteering = '.kiro\steering'
            Ensure-Directory $projectSkills
            Ensure-Directory $projectSteering

            Get-ChildItem -LiteralPath $projectSkills -Directory -Filter 'bmad-*' -ErrorAction SilentlyContinue | ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Recurse -Force
                Write-Host "  ✓ Removed legacy skill folder: $($_.Name)"
            }

            foreach ($agentItem in (Get-ChildItem -LiteralPath $AgentsSrc -Directory)) {
                $target = Join-Path $projectSkills $agentItem.Name
                Ensure-Directory $target
                Copy-Item -LiteralPath (Join-Path $agentItem.FullName 'SKILL.md') -Destination (Join-Path $target 'SKILL.md') -Force
                $refs = Join-Path $agentItem.FullName 'references'
                if (Test-Path -LiteralPath $refs) { Copy-Item -LiteralPath $refs -Destination $target -Recurse -Force }
                $tpls = Join-Path $agentItem.FullName 'templates'
                if (Test-Path -LiteralPath $tpls) { Copy-Item -LiteralPath $tpls -Destination $target -Recurse -Force }
                Write-Host "  ✓ skill: $($agentItem.Name)"
            }

            # Commands -> steering files with inclusion: manual
            if (Test-Path -LiteralPath $CommandsDir) {
                Get-ChildItem -LiteralPath $CommandsDir -Filter '*.md' -File | ForEach-Object {
                    $cmdName = [IO.Path]::GetFileNameWithoutExtension($_.Name)
                    # Extract description from the first few lines
                    $desc = ''
                    $head = Get-Content -LiteralPath $_.FullName -TotalCount 5
                    foreach ($line in $head) {
                        if ($line -match '^\s*description\s*:\s*(.*)$') { $desc = $Matches[1].Trim(); break }
                    }
                    if (-not $desc) { $desc = "BMAD command: $cmdName" }

                    # Strip frontmatter (everything between the first two '---' lines) and write the body
                    $raw = Get-Content -LiteralPath $_.FullName -Raw
                    $body = $raw
                    if ($raw -match '(?sm)\A---\r?\n.*?\r?\n---\r?\n?') {
                        $body = $raw.Substring($Matches[0].Length)
                    }
                    $content = @(
                        '---',
                        "description: $desc",
                        'inclusion: manual',
                        '---',
                        '',
                        $body
                    ) -join "`n"
                    Set-Utf8 -Path (Join-Path $projectSteering "$cmdName.md") -Content $content
                    Write-Host "  ✓ command: $cmdName (-> /$cmdName)"
                }
            }

            Write-Host "  Skills:   $projectSkills\"
            Write-Host "  Steering: $projectSteering\"
        }

        'cursor' {
            $projectRules = '.cursor\rules'
            Ensure-Directory $projectRules

            foreach ($agentItem in (Get-ChildItem -LiteralPath $AgentsSrc -Directory)) {
                $shared = Get-Content -LiteralPath $SharedContext -Raw
                $agent  = Get-Content -LiteralPath (Join-Path $agentItem.FullName 'SKILL.md') -Raw
                Set-Utf8 -Path (Join-Path $projectRules "$($agentItem.Name).md") -Content "$shared`n`n$agent"
                Write-Host "  ✓ agent: $($agentItem.Name)"
            }

            $cursorProjSrc = Join-Path $RulesDirSrc 'cursor\project'
            if (Test-Path -LiteralPath $cursorProjSrc) {
                Get-ChildItem -LiteralPath $cursorProjSrc -Filter '*.mdc' -File | ForEach-Object {
                    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $projectRules $_.Name) -Force
                    Write-Host "  ✓ rule: $($_.Name)"
                }
            }

            Write-Host "  Rules: $projectRules\"
        }

        'windsurf' {
            $projectRules = '.windsurf\rules'
            Ensure-Directory $projectRules

            foreach ($agentItem in (Get-ChildItem -LiteralPath $AgentsSrc -Directory)) {
                $shared = Get-Content -LiteralPath $SharedContext -Raw
                $agent  = Get-Content -LiteralPath (Join-Path $agentItem.FullName 'SKILL.md') -Raw
                Set-Utf8 -Path (Join-Path $projectRules "$($agentItem.Name).md") -Content "$shared`n`n$agent"
                Write-Host "  ✓ agent: $($agentItem.Name)"
            }

            $windsurfProjSrc = Join-Path $RulesDirSrc 'windsurf\project'
            if (Test-Path -LiteralPath $windsurfProjSrc) {
                Get-ChildItem -LiteralPath $windsurfProjSrc -Filter '*.md' -File | ForEach-Object {
                    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $projectRules $_.Name) -Force
                    Write-Host "  ✓ rule: $($_.Name)"
                }
            }

            Write-Host "  Rules: $projectRules\"
        }

        'trae' {
            $projectRules = '.trae\rules'
            Ensure-Directory $projectRules

            foreach ($agentItem in (Get-ChildItem -LiteralPath $AgentsSrc -Directory)) {
                $shared = Get-Content -LiteralPath $SharedContext -Raw
                $agent  = Get-Content -LiteralPath (Join-Path $agentItem.FullName 'SKILL.md') -Raw
                Set-Utf8 -Path (Join-Path $projectRules "$($agentItem.Name).md") -Content "$shared`n`n$agent"
                Write-Host "  ✓ agent: $($agentItem.Name)"
            }

            # Framework seed (if a project-scope rules dir exists, mirror from trae/global)
            $traeGlobalSrc = Join-Path $RulesDirSrc 'trae\global'
            if (Test-Path -LiteralPath $traeGlobalSrc) {
                Get-ChildItem -LiteralPath $traeGlobalSrc -Filter '*.md' -File | ForEach-Object {
                    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $projectRules "000-$($_.Name)") -Force
                    Write-Host "  ✓ rule: 000-$($_.Name)"
                }
            }

            Write-Host "  Rules: $projectRules\"
        }

        'cowork' {
            $projectSkills = '.skills\skills'
            Ensure-Directory $projectSkills

            foreach ($agentItem in (Get-ChildItem -LiteralPath $AgentsSrc -Directory)) {
                $flat = Join-Path $projectSkills "$($agentItem.Name).md"
                if (Test-Path -LiteralPath $flat) {
                    Remove-Item -LiteralPath $flat -Force
                    Write-Host "  ✓ Removed legacy flat file: $($agentItem.Name).md"
                }
            }
            Get-ChildItem -LiteralPath $projectSkills -Directory -Filter 'bmad-*' -ErrorAction SilentlyContinue | ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Recurse -Force
                Write-Host "  ✓ Removed legacy skill folder: $($_.Name)"
            }

            foreach ($agentItem in (Get-ChildItem -LiteralPath $AgentsSrc -Directory)) {
                $target = Join-Path $projectSkills $agentItem.Name
                Ensure-Directory $target
                Copy-Item -LiteralPath (Join-Path $agentItem.FullName 'SKILL.md') -Destination (Join-Path $target 'SKILL.md') -Force
                Write-Host "  ✓ agent: $($agentItem.Name)"
            }

            Write-Host "  Skills: $projectSkills\"
        }
    }

    Write-Host ''
}

# ============================================================
# Install project-level hooks (Claude Code only)
# ============================================================
if (($DetectedTool -eq 'claude') -and (Test-Path -LiteralPath $HooksProjectDir)) {
    Write-Section 'Installing project-level hooks...'

    $projHooksDest = '.claude'
    Ensure-Directory (Join-Path $projHooksDest 'hooks')

    $hooksSettings = Join-Path $HooksProjectDir 'settings.json'
    if (Test-Path -LiteralPath $hooksSettings) {
        Merge-SettingsJson -Source $hooksSettings -Destination (Join-Path $projHooksDest 'settings.json')
        $dedup = Join-Path $ScriptDir 'clean-duplicate-hooks.py'
        if ((Test-Path -LiteralPath $dedup) -and (Test-CommandExists 'python')) {
            & python $dedup (Join-Path $projHooksDest 'settings.json') 2>$null | Out-Null
        }
    }

    $hooksScripts = Join-Path $HooksProjectDir 'scripts'
    if (Test-Path -LiteralPath $hooksScripts) {
        $dstHooks = Join-Path $projHooksDest 'hooks'
        Get-ChildItem -LiteralPath $hooksScripts -Recurse -File | ForEach-Object {
            $relative = $_.FullName.Substring($hooksScripts.Length).TrimStart('\','/')
            $target   = Join-Path $dstHooks $relative
            Ensure-Directory (Split-Path -Parent $target)
            Copy-Item -LiteralPath $_.FullName -Destination $target -Force
        }
        Write-Host '  ✓ .claude\hooks\ (project scripts)'
    }

    Write-Host "  Hooks: $projHooksDest\hooks\"
    Write-Host ''
}

# ============================================================
# MCP project configs (display guidance only)
# ============================================================
if (Test-Path -LiteralPath $McpProjectDir) {
    Write-Section 'MCP project configs available:'
    Write-Host "  Source: $McpProjectDir\"
    Write-Host ''
    Write-Host '  Review and add to your project''s MCP settings:'
    Get-ChildItem -LiteralPath $McpProjectDir -Filter '*.json' -File | ForEach-Object {
        Write-Host "    * $($_.Name)"
    }
    Write-Host ''
    Write-Host "  See $BaseDir\mcp-configs\README.md for merge instructions."
    Write-Host ''
}

# ============================================================
# Generate tool-specific auto-load instruction file
# ============================================================
Write-Section 'Generating BMAD context auto-load instruction file...'

# Shared methodology block — no tool-specific command syntax here.
$BmadContextBlock = @'
## Active Methodology: BMAD SDLC

This project uses the **BMAD (Breakthrough Method of Agile AI-Driven Development)** methodology.
BMAD agents are the authoritative source of truth for all analysis, design, and implementation work.

**Agent priority:**
- BMAD agents are the authoritative source for all deliverables — prefer BMAD agents over generic AI suggestions
- BMAD artifacts belong **only** in the paths defined in `.bmad/PROJECT-CONTEXT.md` (Artifacts Index section)
- Do NOT use non-BMAD skills (e.g. superpowers, personas, generic planners) for this project's deliverables

## BMAD Project Context

At the start of every conversation, read these files to understand this project:

- `.bmad/PROJECT-CONTEXT.md` — vision, goals, stakeholders, constraints
- `.bmad/tech-stack.md` — technology stack, versions, dependencies
- `.bmad/team-conventions.md` — code style, naming conventions, patterns
- `.bmad/domain-glossary.md` — business domain terminology
- `.bmad/handoff-log.md` — agent handoff index (full records in `.bmad/handoffs/`)

Apply all conventions from `.bmad/team-conventions.md` when writing or reviewing code.
'@

# Agent table — Claude Code / Cowork (/slash-command syntax)
$ClaudeAgentTable = @'

## Available BMAD Agents (slash commands)

| Command | Role |
|---------|------|
| `/business-analyst` | Discovery, stakeholder analysis, project brief |
| `/product-owner` | PRD, backlog, user stories |
| `/solution-architect` | System design, APIs, ADRs |
| `/enterprise-architect` | Cloud infra, compliance, CI/CD |
| `/ux-designer` | Wireframes, design system, accessibility |
| `/tech-lead` | Orchestration, code review, risk |
| `/tester-qe` | Test strategy, quality gates |
| `/backend-engineer` | APIs, services, data layers |
| `/frontend-engineer` | React/TypeScript, components, a11y |
| `/mobile-engineer` | iOS/Android, native architecture |

## BMAD Commands

| Command | Role |
|---------|------|
| `/bmad-status` | Show project phase & artifact status |
| `/handoff` | Log an agent handoff |
| `/new-story` | Create a new user story |
| `/new-adr` | Record an architecture decision |
| `/new-epic` | Plan a full 4-phase epic |
| `/sprint-plan` | Generate a capacity-matched sprint |
'@

# Agent note for tools without native slash commands (Cursor/Windsurf/Trae/Copilot/Gemini)
$RuleBasedAgentNote = @'

## Using BMAD Agents

BMAD agents are installed as AI rules/context files. Reference the agent by name in your prompt
(e.g. "act as the Business Analyst", "use the Tech Lead agent to plan this sprint").
Each agent auto-detects its current task from the project context files in `.bmad/`.

For BMAD commands (`/bmad-status`, `/handoff`, etc.), describe the action in plain language
(e.g. "run a project status check" or "log a handoff from Tech Lead to Backend Engineer").

Available agents: business-analyst | product-owner | solution-architect | enterprise-architect |
ux-designer | tech-lead | tester-qe | backend-engineer | frontend-engineer | mobile-engineer
'@

# Codex agent table — $skill syntax
$CodexAgentTable = @'

## Available BMAD Agents (Codex skills)

| Skill ($ invoke) | Role |
|-------------------|------|
| `$business-analyst` | Discovery, stakeholder analysis, project brief |
| `$product-owner` | PRD, backlog, user stories |
| `$solution-architect` | System design, APIs, ADRs |
| `$enterprise-architect` | Cloud infra, compliance, CI/CD |
| `$ux-designer` | Wireframes, design system, accessibility |
| `$tech-lead` | Orchestration, code review, risk |
| `$tester-qe` | Test strategy, quality gates |
| `$backend-engineer` | APIs, services, data layers |
| `$frontend-engineer` | React/TypeScript, components, a11y |
| `$mobile-engineer` | iOS/Android, native architecture |

## Available BMAD Commands (slash commands)

| Command | Role |
|---------|------|
| `/bmad-status` | Show project phase & artifact status |
| `/handoff` | Log an agent handoff |
| `/new-story` | Create a new user story |
| `/new-adr` | Record an architecture decision |
| `/new-epic` | Plan a full 4-phase epic |
| `/sprint-plan` | Generate a capacity-matched sprint |
'@

# Kiro agent table — description-match skills
$KiroAgentTable = @'

## Available BMAD Agents (Kiro skills)

Skills activate by description match. You can also invoke commands with / prefix:

| Skill | Role |
|-------|------|
| business-analyst | Discovery, stakeholder analysis, project brief |
| product-owner | PRD, backlog, user stories |
| solution-architect | System design, APIs, ADRs |
| enterprise-architect | Cloud infra, compliance, CI/CD |
| ux-designer | Wireframes, design system, accessibility |
| tech-lead | Orchestration, code review, risk |
| tester-qe | Test strategy, quality gates |
| backend-engineer | APIs, services, data layers |
| frontend-engineer | React/TypeScript, components, a11y |
| mobile-engineer | iOS/Android, native architecture |

## Available BMAD Commands (/ slash commands)

| Command | Role |
|---------|------|
| `/bmad-status` | Show project phase & artifact status |
| `/handoff` | Log an agent handoff |
| `/new-story` | Create a new user story |
| `/new-adr` | Record an architecture decision |
| `/new-epic` | Plan a full 4-phase epic |
| `/sprint-plan` | Generate a capacity-matched sprint |
'@

function Write-InstructionFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Header,
        [Parameter(Mandatory)][string]$Body
    )
    if (Test-Path -LiteralPath $Path) {
        Add-Utf8 -Path $Path -Content "`n$Body"
        Write-Host "  ✓ Appended to existing $Path"
    } else {
        Set-Utf8 -Path $Path -Content "$Header`n`n$Body"
        Write-Host "  ✓ Created $Path"
    }
}

switch ($DetectedTool) {

    'claude' {
        $body = "$BmadContextBlock`n$ClaudeAgentTable"
        if (Test-Path -LiteralPath 'CLAUDE.md') {
            Add-Utf8 -Path 'CLAUDE.md' -Content "`n$body"
            Write-Host '  ✓ Appended to existing CLAUDE.md'
        } else {
            Set-Utf8 -Path 'CLAUDE.md' -Content "# $ProjectName`n`n$body"
            Write-Host '  ✓ Created CLAUDE.md'
        }
    }

    'codex' {
        $body = "$BmadContextBlock`n$CodexAgentTable"
        if (Test-Path -LiteralPath 'AGENTS.md') {
            Add-Utf8 -Path 'AGENTS.md' -Content "`n$body"
            Write-Host '  ✓ Appended to existing AGENTS.md'
        } else {
            Set-Utf8 -Path 'AGENTS.md' -Content "# $ProjectName`n`n$body"
            Write-Host '  ✓ Created AGENTS.md'
        }
    }

    'kiro' {
        $body = "$BmadContextBlock`n$KiroAgentTable"
        if (Test-Path -LiteralPath 'AGENTS.md') {
            Add-Utf8 -Path 'AGENTS.md' -Content "`n$body"
            Write-Host '  ✓ Appended to existing AGENTS.md'
        } else {
            Set-Utf8 -Path 'AGENTS.md' -Content "# $ProjectName`n`n$body"
            Write-Host '  ✓ Created AGENTS.md'
        }

        # Auto-included steering file as belt-and-suspenders
        Ensure-Directory '.kiro\steering'
        $steeringBody = @(
            '---',
            'description: BMAD project context — auto-loaded at session start',
            'inclusion: auto',
            '---',
            '',
            $BmadContextBlock
        ) -join "`n"
        Set-Utf8 -Path '.kiro\steering\bmad-project-context.md' -Content $steeringBody
        Write-Host '  ✓ Created .kiro\steering\bmad-project-context.md'
    }

    'cursor' {
        $path = '.cursor\rules\001-project-context.mdc'
        Ensure-Directory '.cursor\rules'
        $body = @(
            '---',
            'description: BMAD project context — load at the start of every conversation',
            'alwaysApply: true',
            '---',
            '',
            $BmadContextBlock,
            $RuleBasedAgentNote
        ) -join "`n"
        Set-Utf8 -Path $path -Content $body
        Write-Host "  ✓ Created $path"
    }

    'windsurf' {
        $body = "$BmadContextBlock`n$RuleBasedAgentNote"
        if (Test-Path -LiteralPath '.windsurfrules') {
            Add-Utf8 -Path '.windsurfrules' -Content "`n$body"
            Write-Host '  ✓ Appended to existing .windsurfrules'
        } else {
            Set-Utf8 -Path '.windsurfrules' -Content $body
            Write-Host '  ✓ Created .windsurfrules'
        }
    }

    'trae' {
        # Trae reads .trae/rules/*.md as always-on guidelines and also picks up user_rules.md.
        Ensure-Directory '.trae\rules'
        $body = @(
            $BmadContextBlock,
            $RuleBasedAgentNote
        ) -join "`n"
        Set-Utf8 -Path '.trae\rules\000-bmad-project-context.md' -Content $body
        Write-Host '  ✓ Created .trae\rules\000-bmad-project-context.md'
        # Mirror to user_rules.md for Trae versions that only auto-load that file
        Set-Utf8 -Path '.trae\rules\user_rules.md' -Content $body
        Write-Host '  ✓ Created .trae\rules\user_rules.md'
    }

    'cowork' {
        $body = "$BmadContextBlock`n$ClaudeAgentTable"
        if (Test-Path -LiteralPath 'CLAUDE.md') {
            Add-Utf8 -Path 'CLAUDE.md' -Content "`n$body"
            Write-Host '  ✓ Appended to existing CLAUDE.md'
        } else {
            Set-Utf8 -Path 'CLAUDE.md' -Content "# $ProjectName`n`n$body"
            Write-Host '  ✓ Created CLAUDE.md'
        }
    }

    'none' {
        # No tool detected — emit every instruction file so the team can commit the right one later.
        Write-Host '  Creating all tool instruction files (no tool detected)...'
        Ensure-Directory '.cursor\rules'
        Ensure-Directory '.github'
        Ensure-Directory '.kiro\steering'
        Ensure-Directory '.trae\rules'

        Set-Utf8 -Path 'CLAUDE.md' -Content "# $ProjectName`n`n$BmadContextBlock`n$ClaudeAgentTable"
        Write-Host '  ✓ CLAUDE.md (Claude Code / Cowork)'

        Set-Utf8 -Path 'AGENTS.md' -Content "# $ProjectName`n`n$BmadContextBlock`n$CodexAgentTable"
        Write-Host '  ✓ AGENTS.md (Codex CLI / Kiro / OpenCode)'

        $cursorBody = @(
            '---',
            'description: BMAD project context — load at the start of every conversation',
            'alwaysApply: true',
            '---',
            '',
            $BmadContextBlock,
            $RuleBasedAgentNote
        ) -join "`n"
        Set-Utf8 -Path '.cursor\rules\001-project-context.mdc' -Content $cursorBody
        Write-Host '  ✓ .cursor\rules\001-project-context.mdc (Cursor)'

        Set-Utf8 -Path '.windsurfrules' -Content "$BmadContextBlock`n$RuleBasedAgentNote"
        Write-Host '  ✓ .windsurfrules (Windsurf)'

        Set-Utf8 -Path '.trae\rules\000-bmad-project-context.md' -Content "$BmadContextBlock`n$RuleBasedAgentNote"
        Set-Utf8 -Path '.trae\rules\user_rules.md' -Content "$BmadContextBlock`n$RuleBasedAgentNote"
        Write-Host '  ✓ .trae\rules\000-bmad-project-context.md + user_rules.md (Trae IDE)'

        Set-Utf8 -Path '.github\copilot-instructions.md' -Content "$BmadContextBlock`n$RuleBasedAgentNote"
        Write-Host '  ✓ .github\copilot-instructions.md (GitHub Copilot)'

        Set-Utf8 -Path 'GEMINI.md' -Content "# $ProjectName`n`n$BmadContextBlock`n$RuleBasedAgentNote"
        Write-Host '  ✓ GEMINI.md (Gemini CLI)'

        $kiroSteeringBody = @(
            '---',
            'description: BMAD project context — auto-loaded at session start',
            'inclusion: auto',
            '---',
            '',
            $BmadContextBlock
        ) -join "`n"
        Set-Utf8 -Path '.kiro\steering\bmad-project-context.md' -Content $kiroSteeringBody
        Write-Host '  ✓ .kiro\steering\bmad-project-context.md (Kiro)'
    }
}

Write-Host ''

# ============================================================
# Create placeholder documentation files
# ============================================================
Write-Section 'Creating placeholder documentation...'

function New-EmptyFile([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        Ensure-Directory (Split-Path -Parent $Path)
        [System.IO.File]::WriteAllText($Path, '', $script:Utf8NoBom)
    }
}

New-EmptyFile 'docs\project-brief.md';                       Write-Host '  ✓ docs\project-brief.md'
New-EmptyFile 'docs\prd.md';                                 Write-Host '  ✓ docs\prd.md'
New-EmptyFile 'docs\architecture\solution-architecture.md';  Write-Host '  ✓ docs\architecture\solution-architecture.md'
New-EmptyFile 'docs\architecture\enterprise-architecture.md';Write-Host '  ✓ docs\architecture\enterprise-architecture.md'
New-EmptyFile 'docs\ux\DESIGN.md';                           Write-Host '  ✓ docs\ux\DESIGN.md (Google Stitch DESIGN.md format — UX Designer populates on first invocation)'
New-EmptyFile 'docs\architecture\adr\ADR-INDEX.md';          Write-Host '  ✓ docs\architecture\adr\ADR-INDEX.md'
New-EmptyFile 'docs\analysis\.gitkeep';                      Write-Host '  ✓ docs\analysis\ (BA impact & requirements analyses)'

Ensure-Directory 'docs\testing\bugs'
New-EmptyFile 'docs\testing\bugs\.gitkeep';                  Write-Host '  ✓ docs\testing\bugs\'

Ensure-Directory 'docs\testing\hotfixes'
New-EmptyFile 'docs\testing\hotfixes\.gitkeep';              Write-Host '  ✓ docs\testing\hotfixes\'

Write-Host ''

# ============================================================
# Summary
# ============================================================
Write-Banner 'Scaffolding Complete'

Write-Host 'Created files and directories:'
Write-Host '  * .bmad\PROJECT-CONTEXT.md     — project orientation'
Write-Host '  * .bmad\tech-stack.md          — technology decisions'
Write-Host '  * .bmad\team-conventions.md    — coding standards'
Write-Host '  * .bmad\domain-glossary.md     — domain terminology'
Write-Host '  * .bmad\handoff-log.md         — agent handoff tracking'
Write-Host '  * .bmad\eval\bmad-agent-eval-dashboard.html — productivity evaluation dashboard'
Write-Host '  * .bmad\signals\               — autonomous orchestration sentinel files (E2-be-done, E2-fe-done, etc.)'
Write-Host '  * docs\analysis\               — BA feature impact & requirements analyses'
Write-Host '  * docs\                        — documentation structure'

if ($DetectedTool -ne 'none') {
    Write-Host '  * Project-level agent configurations'
}
if (($DetectedTool -eq 'claude') -and (Test-Path -LiteralPath $HooksProjectDir)) {
    Write-Host '  * .claude\hooks\               — project-level hooks'
}

switch ($DetectedTool) {
    'claude'   { Write-Host '  * CLAUDE.md                    — auto-loads .bmad/ context on session start' }
    'cowork'   { Write-Host '  * CLAUDE.md                    — auto-loads .bmad/ context on session start' }
    'codex'    { Write-Host '  * AGENTS.md                    — auto-loads .bmad/ context on session start' }
    'kiro'     { Write-Host '  * AGENTS.md + .kiro\steering\  — auto-loads .bmad/ context on session start' }
    'cursor'   { Write-Host '  * .cursor\rules\001-project-context.mdc — auto-loads .bmad/ context' }
    'windsurf' { Write-Host '  * .windsurfrules               — auto-loads .bmad/ context on session start' }
    'trae'     { Write-Host '  * .trae\rules\000-bmad-project-context.md + user_rules.md — auto-loads .bmad/ context' }
    'none'     { Write-Host '  * CLAUDE.md (Claude/Cowork) / AGENTS.md (Codex/Kiro) / .cursor/rules/ (Cursor) / .windsurfrules (Windsurf) / .trae/rules/ (Trae) / .github/copilot-instructions.md / GEMINI.md — each with correct tool syntax' }
}

Write-Host ''
Write-Host 'Next steps:' -ForegroundColor Green
Write-Host '  1. Edit .bmad\PROJECT-CONTEXT.md to fill in project details'
Write-Host '  2. Edit .bmad\tech-stack.md with your stack decisions'
Write-Host '  3. Commit all .bmad\, .claude\, .codex\, and instruction files to version control'
Write-Host '     (CLAUDE.md / AGENTS.md / .windsurfrules / .cursor\rules\ / .trae\rules\ — whichever your team uses)'
Write-Host '  4. Teams review .bmad\*.md files before starting work'
Write-Host ''

switch ($DetectedTool) {
    'codex' {
        Write-Host 'Useful commands (Codex CLI):'
        Write-Host '  $business-analyst — invoke Business Analyst skill'
        Write-Host '  $solution-architect — invoke Solution Architect skill'
        Write-Host '  /bmad-status     — show project phase & artifact status'
        Write-Host '  /handoff         — log an agent handoff'
        Write-Host '  /new-story       — create a new user story'
        Write-Host '  /new-adr         — record an architecture decision'
    }
    'kiro' {
        Write-Host 'Useful commands (Kiro):'
        Write-Host "  Skills activate by description match (e.g. ask for a 'project brief')"
        Write-Host '  /bmad-status     — show project phase & artifact status'
        Write-Host '  /handoff         — log an agent handoff'
        Write-Host '  /new-story       — create a new user story'
        Write-Host '  /new-adr         — record an architecture decision'
    }
    default {
        Write-Host 'Useful slash commands (Claude Code):'
        Write-Host '  /bmad-status    — show project phase & artifact status'
        Write-Host '  /new-story      — create a new user story'
        Write-Host '  /new-adr        — record an architecture decision'
        Write-Host '  /handoff        — log an agent handoff'
        Write-Host '  /new-epic       — plan a full 4-phase epic'
        Write-Host '  /sprint-plan    — generate a capacity-matched sprint'
    }
}

Write-Host ''
Write-Host 'For more info, see:'
Write-Host '  * .bmad\PROJECT-CONTEXT.md (orientation)'
Write-Host '  * .bmad\handoff-log.md (track agent work)'
Write-Host "  * $BaseDir\README.md (full documentation)"
Write-Host ''

exit 0
