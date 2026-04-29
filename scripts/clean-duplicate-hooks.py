#!/usr/bin/env python3
"""
Remove duplicate stop hook entries from .claude/settings.json.
Keeps the first occurrence of each logical command (after resolving
common variable aliases like ${CLAUDE_PLUGIN_ROOT} → the real path).
Usage: python3 clean-duplicate-hooks.py .claude/settings.json [--dry-run]
"""

import json
import re
import shutil
import sys
from pathlib import Path


def normalize_command(cmd: str) -> str:
    """Strip resolved paths down to the script basename for dedup comparison."""
    # Replace any absolute path prefix before a known script filename
    cmd = re.sub(r'/[^\s"\']+/([^/\s"\']+\.(?:js|cjs|sh))', r'\1', cmd)
    # Replace ${VAR} and $VAR with a placeholder
    cmd = re.sub(r'\$\{?[A-Z_]+\}?', '<VAR>', cmd)
    return cmd.strip()


def deduplicate_event(entries: list) -> list:
    seen = set()
    result = []
    for entry in entries:
        hook_cmds = tuple(
            normalize_command(h.get("command", ""))
            for h in entry.get("hooks", [])
        )
        if hook_cmds not in seen:
            seen.add(hook_cmds)
            result.append(entry)
        else:
            print(f"  Removing duplicate: {entry.get('hooks', [{}])[0].get('command', '')[:80]}")
    return result


def main():
    dry_run = "--dry-run" in sys.argv
    args = [a for a in sys.argv[1:] if not a.startswith("--")]

    if not args:
        print("Usage: python3 clean-duplicate-hooks.py <settings.json> [--dry-run]")
        sys.exit(1)

    settings_path = Path(args[0])

    if not settings_path.exists():
        print(f"File not found: {settings_path}")
        sys.exit(1)

    with open(settings_path) as f:
        data = json.load(f)

    hooks = data.get("hooks", {})
    changed = False

    for event, entries in hooks.items():
        before = len(entries)
        deduped = deduplicate_event(entries)
        after = len(deduped)
        if after < before:
            print(f"  {event}: {before} → {after} entries")
            hooks[event] = deduped
            changed = True
        else:
            print(f"  {event}: {before} entries (no duplicates)")

    if not changed:
        print("No duplicates found.")
        return

    if dry_run:
        print("\n[DRY RUN] No files written.")
        print("Result would be:")
        print(json.dumps(data, indent=2))
        return

    backup = settings_path.with_suffix(".json.bak")
    shutil.copy(settings_path, backup)
    print(f"\nBacked up → {backup}")

    with open(settings_path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")

    print(f"Cleaned {settings_path}")


if __name__ == "__main__":
    main()
