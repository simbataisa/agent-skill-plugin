#!/usr/bin/env python3
"""
Migrate .bmad/handoff-log.md from the old single-file format to the new
multi-file format: master index + individual child files in .bmad/handoffs/.

Old format:
    ## Handoff #N — YYYY-MM-DD
    **From:** Agent Name
    **To:** Agent Name
    **Phase:** Phase Name
    ### Completed Deliverables / ### Key Decisions / etc.

New format:
    .bmad/handoff-log.md          ← master index table
    .bmad/handoffs/NNN-YYYY-MM-DD-from→to.md  ← one file per handoff

Usage:
    python3 migrate-handoff-log.py [--bmad-dir .bmad] [--dry-run]
"""

import re
import shutil
import sys
from datetime import date
from pathlib import Path

# ── Agent name → abbreviation mapping ────────────────────────────────────────

ABBREV = {
    "business analyst":      "ba",
    "product owner":         "po",
    "solution architect":    "sa",
    "enterprise architect":  "ea",
    "ux designer":           "ux",
    "ux/ui designer":        "ux",
    "ui designer":           "ux",
    "tech lead":             "tl",
    "technical lead":        "tl",
    "tester":                "qe",
    "tester & qe":           "qe",
    "tester and qe":         "qe",
    "qe":                    "qe",
    "backend engineer":      "be",
    "frontend engineer":     "fe",
    "mobile engineer":       "me",
    "human":                 "hu",
    "team":                  "hu",
}

def to_abbrev(name: str) -> str:
    return ABBREV.get(name.lower().strip(), name.lower()[:2])


# ── Parse the old handoff-log.md ─────────────────────────────────────────────

HANDOFF_START = re.compile(r'^##\s+Handoff\s+#(\d+)\s*[—–-]\s*(.+)$', re.MULTILINE)
# Matches **Key:** value  OR  **Key**: value  (colon inside or outside bold)
FIELD_LINE    = re.compile(r'^\*\*(\w[\w\s/&]+?):?\*\*:?\s*(.+)$')
SECTION_HEAD  = re.compile(r'^###\s+(.+)$')


def parse_old_log(text: str) -> list[dict]:
    """
    Split the old log into individual handoff blocks and extract structured
    fields from each.
    """
    # Find all handoff start positions
    matches = list(HANDOFF_START.finditer(text))
    if not matches:
        return []

    handoffs = []
    for i, m in enumerate(matches):
        num  = int(m.group(1))
        date_raw = m.group(2).strip()
        start = m.start()
        end   = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        block = text[start:end].strip()

        entry = {
            "num":          num,
            "date_raw":     date_raw,
            "date":         _parse_date(date_raw),
            "from_name":    "",
            "from_abbrev":  "??",
            "to_name":      "",
            "to_abbrev":    "??",
            "phase":        "",
            "deliverables": "",
            "decisions":    "",
            "open_questions":"",
            "risks":        "",
            "starting_point":"",
            "raw_block":    block,
        }

        # Parse bold key:value fields from the first few lines
        for line in block.splitlines()[1:8]:
            fm = FIELD_LINE.match(line.strip())
            if fm:
                key = fm.group(1).lower().strip()
                val = fm.group(2).strip()
                if "from" in key:
                    entry["from_name"]   = val
                    entry["from_abbrev"] = to_abbrev(val)
                elif "to" in key:
                    entry["to_name"]   = val
                    entry["to_abbrev"] = to_abbrev(val)
                elif "phase" in key:
                    entry["phase"] = val

        # Extract named sections
        sections = _split_sections(block)
        entry["deliverables"]    = sections.get("completed deliverables", "").strip()
        entry["decisions"]       = sections.get("key decisions made", "").strip()
        entry["open_questions"]  = sections.get("open questions for next agent", "").strip()
        entry["risks"]           = sections.get("risks / watch-outs", "").strip() or \
                                   sections.get("risks", "").strip()
        entry["starting_point"]  = sections.get("next agent's starting point", "").strip() or \
                                   sections.get("starting point for next agent", "").strip()

        handoffs.append(entry)

    return handoffs


def _parse_date(raw: str) -> str:
    """Try to normalise a date string to YYYY-MM-DD."""
    raw = raw.strip()
    for fmt in ("%Y-%m-%d", "%B %d, %Y", "%d %B %Y", "%d/%m/%Y", "%m/%d/%Y"):
        try:
            from datetime import datetime
            return datetime.strptime(raw, fmt).strftime("%Y-%m-%d")
        except ValueError:
            pass
    # Return as-is if we can't parse
    return raw


def _split_sections(block: str) -> dict[str, str]:
    """Split a handoff block into {section_title_lower: content} pairs."""
    sections: dict[str, str] = {}
    current_key = None
    current_lines: list[str] = []

    for line in block.splitlines():
        m = SECTION_HEAD.match(line)
        if m:
            if current_key is not None:
                sections[current_key] = "\n".join(current_lines)
            current_key   = m.group(1).lower().strip()
            current_lines = []
        elif current_key is not None:
            current_lines.append(line)

    if current_key is not None:
        sections[current_key] = "\n".join(current_lines)

    return sections


# ── Render new child file ─────────────────────────────────────────────────────

def render_child_file(entry: dict) -> str:
    num     = f"{entry['num']:03d}"
    d       = entry["date"]
    fr_name = entry["from_name"] or entry["from_abbrev"]
    to_name = entry["to_name"]   or entry["to_abbrev"]
    fr_abbr = entry["from_abbrev"]
    to_abbr = entry["to_abbrev"]
    phase   = entry["phase"] or "—"

    deliverables  = entry["deliverables"]  or "*(not recorded)*"
    decisions     = entry["decisions"]     or "*(not recorded)*"
    open_q        = entry["open_questions"]or "*(not recorded)*"
    risks         = entry["risks"]         or "*(not recorded)*"
    starting      = entry["starting_point"]or "*(not recorded)*"

    return f"""\
# Handoff #{num} — {d}

**From:** {fr_name} (`{fr_abbr}`)
**To:** {to_name} (`{to_abbr}`)
**Phase:** {phase}

> *Migrated from single-file handoff-log.md*

---

## Completed Deliverables

{deliverables}

## Key Decisions Made

{decisions}

## Open Questions for Next Agent

{open_q}

## Risks / Watch-outs

{risks}

## Starting Point for Next Agent

{starting}
"""


# ── Render master index ───────────────────────────────────────────────────────

def render_master_index(project_name: str, entries: list[dict]) -> str:
    rows = []
    for e in entries:
        num      = f"{e['num']:03d}"
        d        = e["date"]
        fr       = e["from_abbrev"]
        to       = e["to_abbrev"]
        phase    = e["phase"] or "—"
        summary  = _one_line_summary(e)
        filename = f"{num}-{d}-{fr}\u2192{to}.md"
        rows.append(
            f"| {num} | {d} | `{fr}` → `{to}` | {phase} | {summary} "
            f"| [→ view](handoffs/{filename}) |"
        )

    table = "\n".join(rows) if rows else \
        "| — | — | — | — | *No handoffs yet — use `/handoff` to log the first one* | — |"

    return f"""\
# Handoff Log — {project_name}

This file is the **master index** of all agent handoffs in this project.
Full handoff records live in `.bmad/handoffs/` — one file per handoff, so
this index stays concise and each entry is independently readable in git.

## Conventions

**File naming:** `.bmad/handoffs/<NNN>-<YYYY-MM-DD>-<from>→<to>.md`
**Example:** `.bmad/handoffs/003-2026-03-20-sa→ea.md`

Use the `/handoff` command to log a handoff — it auto-numbers, creates the
child file from the template, and updates this index. To log manually, copy
`.bmad/handoffs/_template.md`, fill it in, and add a row below.

## Agent Abbreviations

| Abbreviation | Agent |
|---|---|
| `ba` | Business Analyst |
| `po` | Product Owner |
| `sa` | Solution Architect |
| `ea` | Enterprise Architect |
| `ux` | UX/UI Designer |
| `tl` | Tech Lead |
| `qe` | Tester & QE |
| `be` | Backend Engineer |
| `fe` | Frontend Engineer |
| `me` | Mobile Engineer |
| `hu` | Human / Team |

## Handoff Index

| # | Date | From → To | Phase | Summary | File |
|---|------|-----------|-------|---------|------|
{table}
"""


def _one_line_summary(e: dict) -> str:
    """Extract a short summary: first non-empty line of decisions or deliverables."""
    for field in ("decisions", "deliverables", "starting_point"):
        for line in e[field].splitlines():
            line = line.strip().lstrip("-•*[ ]").strip()
            if line and not line.startswith("|") and len(line) > 4:
                return line[:80] + ("…" if len(line) > 80 else "")
    return "*(see child file)*"


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bmad-dir", default=".bmad",
                        help="Path to the .bmad directory (default: .bmad)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Preview actions without writing any files")
    args = parser.parse_args()

    bmad_dir   = Path(args.bmad_dir)
    log_file   = bmad_dir / "handoff-log.md"
    handoffs_dir = bmad_dir / "handoffs"
    dry_run    = args.dry_run

    if not log_file.exists():
        print(f"✗ Not found: {log_file}")
        sys.exit(1)

    text = log_file.read_text()

    # Detect if already migrated (new format has the index table)
    if "| # | Date | From → To |" in text and "handoffs/" in text:
        print("✓ handoff-log.md already appears to be in the new format.")
        print("  If you still have entries in the Log section, re-run after"
              " removing the index header.")
        sys.exit(0)

    handoffs = parse_old_log(text)

    if not handoffs:
        print("  No '## Handoff #N' entries found in the log.")
        print("  If the file uses a different heading format, please check it manually.")
        sys.exit(0)

    print(f"Found {len(handoffs)} handoff(s) to migrate.\n")

    # Infer project name from the h1 heading, fall back to directory name
    m = re.search(r'^#\s+(?:Agent\s+Handoff\s+Log[:\s]+)?(.+)$', text, re.MULTILINE)
    project_name = m.group(1).strip() if m else bmad_dir.parent.name

    # Preview
    for e in handoffs:
        num      = f"{e['num']:03d}"
        filename = f"{num}-{e['date']}-{e['from_abbrev']}\u2192{e['to_abbrev']}.md"
        print(f"  #{num}  {e['date']}  {e['from_abbrev']} → {e['to_abbrev']}"
              f"  →  handoffs/{filename}")

    print()

    if dry_run:
        print("[DRY RUN] No files written.")
        print("\nNew master index preview:\n")
        print(render_master_index(project_name, handoffs))
        return

    # Backup original
    backup = log_file.with_suffix(".md.bak")
    shutil.copy(log_file, backup)
    print(f"✓ Backed up original → {backup}")

    # Create handoffs/ directory
    handoffs_dir.mkdir(exist_ok=True)
    print(f"✓ Created {handoffs_dir}/")

    # Copy _template.md if it doesn't exist yet
    template_src = Path(__file__).parent.parent / \
        "project-scaffold/.bmad/handoffs/_template.md"
    template_dst = handoffs_dir / "_template.md"
    if template_src.exists() and not template_dst.exists():
        shutil.copy(template_src, template_dst)
        print(f"✓ Copied _template.md")

    # Write child files
    for e in handoffs:
        num      = f"{e['num']:03d}"
        filename = f"{num}-{e['date']}-{e['from_abbrev']}\u2192{e['to_abbrev']}.md"
        child    = handoffs_dir / filename
        if child.exists():
            print(f"  ⚠ Skipped (already exists): handoffs/{filename}")
            continue
        child.write_text(render_child_file(e))
        print(f"  ✓ Created handoffs/{filename}")

    # Rewrite master index
    log_file.write_text(render_master_index(project_name, handoffs))
    print(f"✓ Rewrote {log_file} as master index")

    print(f"\nMigration complete. {len(handoffs)} handoff(s) moved to {handoffs_dir}/")
    print(f"Original preserved at {backup}")


if __name__ == "__main__":
    main()
