#!/usr/bin/env python3
"""Render a Google Stitch DESIGN.md file to a self-contained HTML visualization.

Layout: fixed left sidebar (Foundations / Components / Patterns / Principles)
with scroll-spy highlighting + persistent dark-mode toggle + brand gradient
hero + auto-grouped color palettes that detect scales (primary-50..primary-900
or nested primary: {50: ...}) and emit them as cohesive palette ramps.

Usage:
    python3 scripts/render-design-md.py [--input docs/ux/DESIGN.md] [--output docs/ux/DESIGN.html]

Stdlib-only — no PyYAML, no external dependencies. Python 3.8+ on Windows 11,
macOS, or Linux.
"""

from __future__ import annotations

import argparse
import datetime as dt
import html as html_mod
import re
import sys
from pathlib import Path
from typing import Any


# ─── YAML parsing (minimal subset for the Stitch spec) ────────────────────────


def parse_front_matter(text: str) -> tuple[str, str]:
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n?(.*)", text, re.DOTALL)
    if not m:
        raise ValueError(
            "No YAML front matter found. A Stitch-compliant DESIGN.md must start with --- ... ---"
        )
    return m.group(1), m.group(2)


def _strip_quotes(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and (
        (value[0] == '"' and value[-1] == '"') or (value[0] == "'" and value[-1] == "'")
    ):
        return value[1:-1]
    return value


def parse_yaml(text: str) -> dict:
    """Minimal nested-mapping YAML parser. Handles `key: value` leaves,
    nested mappings, hyphenated keys, `#` line comments, and blank lines."""
    entries: list[tuple[int, str, str]] = []
    for raw in text.split("\n"):
        if not raw.strip():
            continue
        if raw.lstrip().startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        content = raw[indent:]
        if ":" not in content:
            continue
        key, _, value = content.partition(":")
        entries.append((indent, key.strip(), value.strip()))

    root: dict[str, Any] = {}
    stack: list[tuple[int, dict[str, Any]]] = [(-1, root)]

    for indent, key, value in entries:
        while len(stack) > 1 and stack[-1][0] >= indent:
            stack.pop()
        parent = stack[-1][1]
        if value == "":
            new_dict: dict[str, Any] = {}
            parent[key] = new_dict
            stack.append((indent, new_dict))
        else:
            parent[key] = _strip_quotes(value)

    return root


# ─── Token reference resolution ───────────────────────────────────────────────


TOKEN_RE = re.compile(r"\{([\w.-]+)\}")


def _lookup_path(path: str, data: dict) -> Any | None:
    node = data
    for segment in path.split("."):
        if isinstance(node, dict) and segment in node:
            node = node[segment]
        else:
            return None
    return node


def resolve(value: Any, data: dict) -> Any:
    if not isinstance(value, str):
        return value
    m = TOKEN_RE.fullmatch(value)
    if m:
        resolved = _lookup_path(m.group(1), data)
        return value if resolved is None else resolved
    if "{" not in value:
        return value

    def _repl(match: re.Match) -> str:
        node = _lookup_path(match.group(1), data)
        if node is None:
            return match.group(0)
        if isinstance(node, dict):
            return match.group(0)
        return str(node)

    return TOKEN_RE.sub(_repl, value)


def _fmt_resolved(value: Any) -> str:
    if isinstance(value, dict):
        inner = " · ".join(f"{k}: {v}" for k, v in value.items() if not isinstance(v, dict))
        return inner or "(nested)"
    return str(value)


# ─── WCAG contrast ratio ─────────────────────────────────────────────────────


def hex_to_rgb(hex_color: str) -> tuple[int, int, int] | None:
    h = hex_color.lstrip("#").strip()
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    if len(h) != 6 or any(c not in "0123456789abcdefABCDEF" for c in h):
        return None
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def _relative_luminance(rgb: tuple[int, int, int]) -> float:
    def srgb(c: int) -> float:
        v = c / 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = rgb
    return 0.2126 * srgb(r) + 0.7152 * srgb(g) + 0.0722 * srgb(b)


def contrast_ratio(c1: str, c2: str) -> float | None:
    rgb1, rgb2 = hex_to_rgb(c1), hex_to_rgb(c2)
    if rgb1 is None or rgb2 is None:
        return None
    l1, l2 = _relative_luminance(rgb1), _relative_luminance(rgb2)
    lighter, darker = max(l1, l2), min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)


def wcag_grade(ratio: float | None) -> str:
    if ratio is None:
        return "N/A"
    if ratio >= 7.0:
        return "AAA"
    if ratio >= 4.5:
        return "AA"
    if ratio >= 3.0:
        return "AA Large"
    return "Fail"


# ─── Markdown section extraction ──────────────────────────────────────────────


SECTION_RE = re.compile(r"^##\s+(.+?)\s*$", re.MULTILINE)
SUBSECTION_RE = re.compile(r"^###\s+(.+?)\s*$", re.MULTILINE)


def extract_sections(body: str) -> dict[str, str]:
    out: dict[str, str] = {}
    matches = list(SECTION_RE.finditer(body))
    for i, m in enumerate(matches):
        name = m.group(1).strip()
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(body)
        out[name] = body[start:end].strip()
    return out


def extract_subsections(section_body: str) -> list[tuple[str, str]]:
    """Return [(name, prose), …] for each ### subheading in a section body."""
    out: list[tuple[str, str]] = []
    matches = list(SUBSECTION_RE.finditer(section_body))
    for i, m in enumerate(matches):
        name = m.group(1).strip()
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(section_body)
        out.append((name, section_body[start:end].strip()))
    return out


def md_to_html(text: str) -> str:
    if not text.strip():
        return ""
    lines = text.split("\n")
    out: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if "|" in line and i + 1 < len(lines) and re.match(r"^\|?\s*:?-", lines[i + 1]):
            table_lines = []
            while i < len(lines) and "|" in lines[i]:
                table_lines.append(lines[i])
                i += 1
            out.append(_render_table(table_lines))
            continue
        if line.startswith("### "):
            out.append(f'<h3>{_inline(line[4:])}</h3>')
            i += 1
            continue
        if line.startswith("> "):
            out.append(f"<blockquote>{_inline(line[2:])}</blockquote>")
            i += 1
            continue
        if re.match(r"^\s*[-*]\s+", line):
            items = []
            while i < len(lines) and re.match(r"^\s*[-*]\s+", lines[i]):
                items.append(_inline(re.sub(r"^\s*[-*]\s+", "", lines[i])))
                i += 1
            out.append("<ul>" + "".join(f"<li>{it}</li>" for it in items) + "</ul>")
            continue
        if line.strip():
            para: list[str] = [line]
            i += 1
            while i < len(lines) and lines[i].strip() and not lines[i].startswith(("#", ">", "|")) and not re.match(r"^\s*[-*]\s+", lines[i]):
                para.append(lines[i])
                i += 1
            out.append(f"<p>{_inline(' '.join(para))}</p>")
        else:
            i += 1
    return "\n".join(out)


def _inline(s: str) -> str:
    s = html_mod.escape(s)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"\*([^*]+)\*", r"<em>\1</em>", s)
    s = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', s)
    return s


def _render_table(lines: list[str]) -> str:
    def cells(row: str) -> list[str]:
        return [c.strip() for c in row.strip().strip("|").split("|")]
    header = cells(lines[0])
    rows = [cells(ln) for ln in lines[2:] if ln.strip()]
    thead = "<thead><tr>" + "".join(f"<th>{_inline(h)}</th>" for h in header) + "</tr></thead>"
    tbody = "<tbody>" + "".join(
        "<tr>" + "".join(f"<td>{_inline(c)}</td>" for c in r) + "</tr>" for r in rows
    ) + "</tbody>"
    return f"<table>{thead}{tbody}</table>"


def _slug(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")


# ─── CSS ──────────────────────────────────────────────────────────────────────


CSS = """
:root {
  --bg: #F7F7F8; --panel: #FFFFFF; --fg: #0F1115; --fg-muted: #5A6070;
  --fg-subtle: #8A8F9C; --border: #E6E8EC; --surface: #F1F2F5;
  --accent: #E31B8E; --accent-muted: #F472B6; --accent-fg: #FFFFFF;
  --shadow-card: 0 1px 2px rgba(15,17,21,0.04), 0 1px 3px rgba(15,17,21,0.02);
  --mono: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  --sans: Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  --radius: 10px;
  --sidebar-w: 260px;
}
[data-theme="dark"] {
  --bg: #0C0D10; --panel: #15171B; --fg: #EFF1F4; --fg-muted: #A5ABB8;
  --fg-subtle: #6B7180; --border: #26292F; --surface: #1B1E24;
  --shadow-card: 0 1px 2px rgba(0,0,0,0.4), 0 1px 3px rgba(0,0,0,0.2);
}
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; font-family: var(--sans); background: var(--bg); color: var(--fg); line-height: 1.6; -webkit-font-smoothing: antialiased; }
a { color: var(--fg); text-decoration: none; }

.layout { display: grid; grid-template-columns: var(--sidebar-w) 1fr; min-height: 100vh; }

/* ─── Sidebar ──────────────────────────────────────────── */
.sidebar { position: sticky; top: 0; height: 100vh; overflow-y: auto; background: var(--panel); border-right: 1px solid var(--border); padding: 24px 16px 32px; }
.sidebar .brand { display: flex; gap: 12px; align-items: flex-start; padding: 0 8px 20px; border-bottom: 1px solid var(--border); margin-bottom: 20px; }
.sidebar .brand .mark { width: 40px; height: 40px; border-radius: 9px; flex-shrink: 0; display: flex; align-items: center; justify-content: center; color: #fff; font-weight: 800; font-size: 18px; letter-spacing: -0.02em; box-shadow: inset 0 0 0 1px rgba(255,255,255,0.12); }
.sidebar .brand .name { font-weight: 700; font-size: 15px; line-height: 1.3; letter-spacing: -0.01em; color: var(--fg); }
.sidebar .brand .sub { font-size: 12px; color: var(--fg-muted); margin-top: 2px; }
.sidebar .nav-group { margin-bottom: 20px; }
.sidebar .nav-group-title { text-transform: uppercase; font-size: 11px; font-weight: 600; letter-spacing: 0.08em; color: var(--fg-subtle); padding: 0 8px; margin-bottom: 6px; }
.sidebar .nav-group a { display: block; padding: 6px 10px; border-radius: 6px; font-size: 14px; color: var(--fg-muted); transition: background 0.1s, color 0.1s; }
.sidebar .nav-group a:hover { background: var(--surface); color: var(--fg); }
.sidebar .nav-group a.active { background: var(--surface); color: var(--fg); font-weight: 500; }

/* ─── Main ─────────────────────────────────────────────── */
main { padding: 48px 48px 96px; max-width: 1120px; }
.page-header { display: flex; align-items: flex-start; justify-content: space-between; gap: 24px; margin-bottom: 48px; }
.page-header h1 { margin: 0 0 10px; font-size: 44px; font-weight: 700; letter-spacing: -0.02em; line-height: 1.15; }
.page-header .description { margin: 0; color: var(--fg-muted); font-size: 17px; max-width: 720px; }
.page-header .meta { margin-top: 14px; font-size: 13px; color: var(--fg-subtle); display: flex; gap: 14px; flex-wrap: wrap; }
.page-header .meta code { font-family: var(--mono); background: var(--surface); padding: 2px 6px; border-radius: 4px; }
.dark-toggle { background: var(--panel); border: 1px solid var(--border); color: var(--fg); padding: 8px 14px; border-radius: 999px; font-size: 13px; font-weight: 500; cursor: pointer; display: inline-flex; align-items: center; gap: 6px; transition: background 0.12s; white-space: nowrap; }
.dark-toggle:hover { background: var(--surface); }

section.sec { margin: 0 0 64px; scroll-margin-top: 16px; }
section.sec > h2 { margin: 0 0 6px; font-size: 32px; font-weight: 700; letter-spacing: -0.02em; }
section.sec > .intro { margin: 0 0 28px; color: var(--fg-muted); max-width: 760px; }
section.sec h3 { font-size: 19px; font-weight: 600; margin: 36px 0 14px; letter-spacing: -0.01em; }
section.sec h4 { font-size: 15px; font-weight: 600; margin: 20px 0 10px; color: var(--fg); }
section.sec p { margin: 10px 0; max-width: 760px; color: var(--fg); }
code { font-family: var(--mono); font-size: 0.9em; background: var(--surface); padding: 1px 6px; border-radius: 4px; color: var(--fg); }
blockquote { border-left: 3px solid var(--accent); padding: 6px 16px; margin: 16px 0; color: var(--fg-muted); background: var(--panel); border-radius: 4px; }

/* ─── Gradient hero ────────────────────────────────────── */
.gradient-hero { position: relative; border-radius: var(--radius); overflow: hidden; min-height: 260px; display: flex; align-items: center; justify-content: space-between; padding: 32px 40px; color: #fff; box-shadow: var(--shadow-card); }
.gradient-hero .brand-badge { display: flex; gap: 10px; align-items: center; font-size: 28px; font-weight: 700; letter-spacing: -0.01em; }
.gradient-hero .brand-badge .mono { font-family: var(--sans); }
.gradient-hero .brand-badge .sub { font-size: 14px; font-weight: 500; opacity: 0.9; margin-left: 2px; }
.gradient-hero .details { font-family: var(--mono); font-size: 11.5px; line-height: 1.6; color: rgba(255,255,255,0.92); text-align: right; max-width: 320px; }
.gradient-hero .details strong { font-weight: 700; font-family: var(--mono); letter-spacing: 0.04em; }
.gradient-hero + .hero-caption { color: var(--fg-muted); font-size: 13px; margin: 10px 4px 20px; max-width: 760px; }

/* ─── Palette group ────────────────────────────────────── */
.palette-group { background: var(--panel); border: 1px solid var(--border); border-radius: var(--radius); padding: 20px; margin: 16px 0 28px; }
.palette-group .group-header { display: flex; align-items: baseline; justify-content: space-between; margin-bottom: 14px; }
.palette-group .group-header h4 { margin: 0; font-size: 15px; font-weight: 600; }
.palette-group .group-header .note { font-size: 12px; color: var(--fg-muted); }
.palette-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 16px; }
.swatch-card { background: var(--panel); border: 1px solid var(--border); border-radius: 10px; overflow: hidden; box-shadow: var(--shadow-card); }
.swatch-card .chip { height: 96px; position: relative; }
.swatch-card .chip::after { content: ""; position: absolute; inset: 0; box-shadow: inset 0 0 0 1px rgba(0,0,0,0.04); }
.swatch-card .meta { padding: 12px 14px 14px; }
.swatch-card .label { font-weight: 600; font-size: 14px; color: var(--fg); }
.swatch-card .hex { font-family: var(--mono); font-size: 12px; color: var(--fg-muted); margin-top: 3px; }
.swatch-card .path { font-family: var(--mono); font-size: 11px; color: var(--fg-subtle); margin-top: 4px; cursor: pointer; user-select: all; display: inline-block; }
.swatch-card .path:hover { color: var(--accent); }
.swatch-card .grade { display: inline-block; font-size: 10.5px; font-weight: 600; padding: 1px 6px; border-radius: 4px; background: var(--surface); color: var(--fg-muted); margin-top: 6px; border: 1px solid var(--border); }

/* ─── Typography specimens ─────────────────────────────── */
.type-specimens { display: grid; gap: 14px; margin: 16px 0; }
.specimen { border: 1px solid var(--border); border-radius: 10px; padding: 22px; background: var(--panel); box-shadow: var(--shadow-card); }
.specimen .path { font-family: var(--mono); font-size: 12px; color: var(--fg-muted); cursor: pointer; user-select: all; display: block; margin-bottom: 12px; }
.specimen .sample { color: var(--fg); word-break: break-word; }
.specimen .sub { font-family: var(--mono); font-size: 11px; color: var(--fg-subtle); margin-top: 14px; }

/* ─── Scale rows (spacing) ─────────────────────────────── */
.scale-list { background: var(--panel); border: 1px solid var(--border); border-radius: var(--radius); padding: 8px; margin: 16px 0; box-shadow: var(--shadow-card); }
.scale-row { display: grid; grid-template-columns: 200px 1fr 100px; gap: 20px; align-items: center; padding: 12px 16px; border-radius: 6px; }
.scale-row:nth-child(odd) { background: var(--surface); }
.scale-row .label { font-family: var(--mono); font-size: 13px; color: var(--fg); }
.scale-row .bar { background: var(--accent); height: 20px; border-radius: 3px; }
.scale-row .meta { font-family: var(--mono); font-size: 12px; color: var(--fg-muted); text-align: right; }

/* ─── Radii / elevation / motion grids ─────────────────── */
.sample-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 16px; margin: 16px 0; }
.sample-grid .card { background: var(--panel); border: 1px solid var(--border); padding: 20px; text-align: center; font-family: var(--mono); font-size: 12px; min-height: 140px; display: flex; flex-direction: column; justify-content: center; gap: 6px; box-shadow: var(--shadow-card); }
.sample-grid .card strong { color: var(--fg); font-size: 14px; }
.sample-grid .card .path { color: var(--fg-subtle); cursor: pointer; user-select: all; }
.sample-grid .card .path:hover { color: var(--accent); }
.radius-demo { width: 72px; height: 72px; background: linear-gradient(135deg, var(--accent) 0%, var(--accent-muted) 100%); margin: 0 auto 4px; }

/* ─── Components gallery ───────────────────────────────── */
.component { background: var(--panel); border: 1px solid var(--border); border-radius: var(--radius); padding: 24px; margin: 14px 0 22px; box-shadow: var(--shadow-card); scroll-margin-top: 16px; }
.component h3 { margin: 0 0 14px !important; font-size: 20px; }
.component .preview { padding: 28px; background: var(--surface); border-radius: 8px; display: flex; gap: 12px; flex-wrap: wrap; align-items: center; }
.component .variants { display: flex; gap: 6px; flex-wrap: wrap; margin-top: 14px; font-size: 12px; align-items: baseline; }
.component .variants .pill { padding: 3px 8px; background: var(--surface); border: 1px solid var(--border); border-radius: 6px; font-family: var(--mono); color: var(--fg-muted); }
.component .props { margin-top: 16px; }
.component .props table { width: 100%; border-collapse: collapse; font-size: 13px; }
.component .props th, .component .props td { text-align: left; padding: 8px 10px; border-bottom: 1px solid var(--border); font-family: var(--mono); vertical-align: top; }
.component .props th { color: var(--fg-muted); font-weight: 500; width: 170px; }
.component .props td:last-child { color: var(--fg-muted); }

/* ─── Tables (contrast + generic) ──────────────────────── */
table { width: 100%; border-collapse: collapse; margin: 16px 0; font-size: 14px; background: var(--panel); border: 1px solid var(--border); border-radius: var(--radius); overflow: hidden; box-shadow: var(--shadow-card); }
table th, table td { text-align: left; padding: 10px 14px; border-bottom: 1px solid var(--border); }
table th { font-weight: 600; color: var(--fg-muted); background: var(--surface); }
table tr:last-child td { border-bottom: none; }

.contrast-grade { display: inline-block; font-size: 12px; font-weight: 700; padding: 2px 8px; border-radius: 4px; }
.contrast-grade.aaa { background: #1E8E3E; color: #fff; }
.contrast-grade.aa { background: #1A73E8; color: #fff; }
.contrast-grade.aa-large { background: #F9AB00; color: #202124; }
.contrast-grade.fail { background: #D93025; color: #fff; }

/* ─── Patterns ─────────────────────────────────────────── */
.pattern { background: var(--panel); border: 1px solid var(--border); border-radius: var(--radius); padding: 20px 24px; margin: 14px 0 22px; box-shadow: var(--shadow-card); scroll-margin-top: 16px; }
.pattern h3 { margin: 0 0 8px !important; font-size: 18px; }

/* ─── Responsive ───────────────────────────────────────── */
@media (max-width: 960px) {
  .layout { grid-template-columns: 1fr; }
  .sidebar { position: static; height: auto; border-right: none; border-bottom: 1px solid var(--border); }
  main { padding: 32px 24px 64px; }
  .page-header { flex-direction: column; }
}
"""


SCRIPT = """
// Dark mode toggle — persist to localStorage, honour system default on first visit
(function () {
  const root = document.documentElement;
  const key = 'bmad-design-theme';
  const stored = localStorage.getItem(key);
  const prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
  const initial = stored || (prefersDark ? 'dark' : 'light');
  if (initial === 'dark') root.setAttribute('data-theme', 'dark');
  const btn = document.querySelector('.dark-toggle');
  if (btn) {
    const labelize = () => {
      const isDark = root.getAttribute('data-theme') === 'dark';
      btn.textContent = isDark ? '☀ Light mode' : '☾ Dark mode';
    };
    labelize();
    btn.addEventListener('click', () => {
      const isDark = root.getAttribute('data-theme') === 'dark';
      if (isDark) { root.removeAttribute('data-theme'); localStorage.setItem(key, 'light'); }
      else { root.setAttribute('data-theme', 'dark'); localStorage.setItem(key, 'dark'); }
      labelize();
    });
  }
})();

// Click-to-copy token paths
document.querySelectorAll('.path').forEach(el => {
  el.addEventListener('click', (e) => {
    e.stopPropagation();
    navigator.clipboard?.writeText(el.textContent).then(() => {
      const original = el.textContent;
      el.textContent = 'Copied!';
      setTimeout(() => { el.textContent = original; }, 900);
    });
  });
});

// Scroll-spy: highlight sidebar entry for currently-visible section
(function () {
  const links = Array.from(document.querySelectorAll('.sidebar a[href^="#"]'));
  const byId = new Map(links.map(a => [a.getAttribute('href').slice(1), a]));
  const targets = Array.from(document.querySelectorAll('[id]')).filter(el => byId.has(el.id));
  if (!targets.length) return;
  const setActive = (id) => {
    links.forEach(a => a.classList.remove('active'));
    const a = byId.get(id);
    if (a) a.classList.add('active');
  };
  const observer = new IntersectionObserver((entries) => {
    const visible = entries.filter(e => e.isIntersecting).sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top);
    if (visible.length) setActive(visible[0].target.id);
  }, { rootMargin: '-30% 0px -60% 0px', threshold: 0 });
  targets.forEach(t => observer.observe(t));
})();
"""


# ─── Brand mark / gradient helpers ───────────────────────────────────────────


def _first_gradient(data: dict) -> str | None:
    """Return the first value of data['gradients'] — falls back to a
    synthesized gradient from the first 2–3 hex colors if no gradients block exists."""
    grads = data.get("gradients")
    if isinstance(grads, dict):
        for value in grads.values():
            if isinstance(value, str) and ("gradient" in value or "linear-" in value):
                return value
    return None


def _synthesize_gradient(colors_flat: list[tuple[str, str]]) -> str:
    """Build a soft brand gradient from the first few palette colors."""
    hexes = [v for _, v in colors_flat if isinstance(v, str) and v.startswith("#")][:3]
    if len(hexes) < 2:
        return "linear-gradient(135deg, #6B2FD6 0%, #E31B8E 100%)"
    stops = [f"{h} {int(100 * i / (len(hexes) - 1))}%" for i, h in enumerate(hexes)]
    return f"linear-gradient(90deg, {', '.join(stops)})"


def _brand_initial(name: str) -> str:
    name = (name or "?").strip()
    return name[0].upper() if name else "?"


# ─── Color palette grouping ───────────────────────────────────────────────────


SCALE_RE = re.compile(r"^([A-Za-z][A-Za-z0-9]*)-(\d+)$")


def _flatten_colors(colors: dict, data: dict) -> list[tuple[str, str, str, str]]:
    """Return a flat list of (group, label, token_path, resolved_hex) tuples."""
    out: list[tuple[str, str, str, str]] = []
    if not isinstance(colors, dict):
        return out
    for key, value in colors.items():
        if isinstance(value, dict):
            # Nested: primary: {50: "#...", 100: "#..."}
            for sub_key, sub_val in value.items():
                resolved = resolve(sub_val, data) if isinstance(sub_val, str) else sub_val
                if isinstance(resolved, str) and resolved.startswith("#"):
                    out.append((key, f"{key.title()} {sub_key}", f"{{colors.{key}.{sub_key}}}", resolved))
            continue
        if not isinstance(value, str):
            continue
        resolved = resolve(value, data)
        if not (isinstance(resolved, str) and resolved.startswith("#")):
            continue
        m = SCALE_RE.match(key)
        if m:
            group, step = m.group(1), m.group(2)
            out.append((group, f"{group.title()} {step}", f"{{colors.{key}}}", resolved))
        else:
            out.append(("", key, f"{{colors.{key}}}", resolved))
    return out


def _group_palette(flat: list[tuple[str, str, str, str]]) -> list[tuple[str, list[tuple[str, str, str, str]]]]:
    """Group flattened colors by first tuple element (group name).
    Returns [(group_title, [(_, label, path, hex), …]), …] with scales sorted by step."""
    groups: dict[str, list[tuple[str, str, str, str]]] = {}
    for g, label, path, hx in flat:
        groups.setdefault(g, []).append((g, label, path, hx))

    # Order: scales first (alphabetical by group), then singletons last
    scale_groups = [k for k in groups if k]
    singles = [k for k in groups if not k]
    ordered: list[tuple[str, list[tuple[str, str, str, str]]]] = []
    for g in sorted(scale_groups):
        items = groups[g]
        # Try to sort by trailing number in label if present
        def sort_key(t):
            m = re.search(r"(\d+)$", t[1])
            return (0, int(m.group(1))) if m else (1, t[1])
        items.sort(key=sort_key)
        title = f"Brand — {g.replace('-', ' ').title()}"
        ordered.append((title, items))
    if singles:
        ordered.append(("Tokens", groups[""]))
    return ordered


def render_palette(colors: dict, data: dict) -> str:
    flat = _flatten_colors(colors, data)
    if not flat:
        return "<p><em>No colors declared.</em></p>"

    # Figure out "background" color for contrast grading
    bg = None
    for _, label, _, hx in flat:
        if "background" in label.lower() or "surface" in label.lower() or label.lower().endswith(" 50"):
            bg = hx
            break
    if bg is None:
        bg = "#FFFFFF"

    groups = _group_palette(flat)
    html_parts: list[str] = []
    for title, items in groups:
        cards: list[str] = []
        for _, label, path, hx in items:
            ratio = contrast_ratio(hx, bg)
            grade = wcag_grade(ratio)
            grade_html = f'<span class="grade">vs bg · {ratio:.1f}:1 · {html_mod.escape(grade)}</span>' if ratio else ""
            cards.append(
                '<div class="swatch-card">'
                f'<div class="chip" style="background: {html_mod.escape(hx)};"></div>'
                '<div class="meta">'
                f'<div class="label">{html_mod.escape(label)}</div>'
                f'<div class="hex">{html_mod.escape(hx.upper())}</div>'
                f'<div class="path">{html_mod.escape(path)}</div>'
                f'{grade_html}'
                '</div></div>'
            )
        html_parts.append(
            '<div class="palette-group">'
            f'<div class="group-header"><h4>{html_mod.escape(title)}</h4>'
            f'<span class="note">{len(items)} tokens</span></div>'
            f'<div class="palette-grid">{"".join(cards)}</div>'
            '</div>'
        )
    return "".join(html_parts)


def render_gradient_hero(data: dict, project_name: str) -> str:
    grad = _first_gradient(data)
    if not grad:
        return ""
    initial = _brand_initial(project_name)
    # Extract stops for display
    stops_display: list[str] = []
    for m in re.finditer(r"#[0-9a-fA-F]{3,8}", grad):
        stops_display.append(m.group(0))
    stops_html = "<br>".join(html_mod.escape(s) for s in stops_display) if stops_display else ""
    gradient_token = ""
    grads = data.get("gradients")
    if isinstance(grads, dict):
        first_key = next(iter(grads))
        gradient_token = f"{{gradients.{first_key}}}"
    return (
        '<div class="gradient-hero" style="background: ' + html_mod.escape(grad) + '">'
        '<div class="brand-badge">'
        f'<span class="mono">{html_mod.escape(project_name)}</span>'
        '</div>'
        '<div class="details">'
        f'<strong>{html_mod.escape(gradient_token)}</strong><br>'
        f'{html_mod.escape(grad)}'
        '</div></div>'
        '<div class="hero-caption">Use the gradient on hero surfaces, onboarding welcome screens, and brand moments. '
        'For solid-color UI (buttons, chips, focus rings) pivot around the palette tokens below.</div>'
    )


# ─── Typography / scales / components ─────────────────────────────────────────


def render_typography(typography: dict) -> str:
    if not typography:
        return "<p><em>No typography declared.</em></p>"
    blocks: list[str] = []
    for name, props in typography.items():
        if not isinstance(props, dict):
            continue
        styles: list[str] = []
        if props.get("fontFamily"): styles.append(f"font-family: {props['fontFamily']}, var(--sans)")
        if props.get("fontSize"):   styles.append(f"font-size: {props['fontSize']}")
        if props.get("fontWeight"): styles.append(f"font-weight: {props['fontWeight']}")
        if props.get("lineHeight"): styles.append(f"line-height: {props['lineHeight']}")
        if props.get("letterSpacing"): styles.append(f"letter-spacing: {props['letterSpacing']}")
        style = "; ".join(styles)
        meta_parts = [f"{k}: {v}" for k, v in props.items()]
        blocks.append(
            '<div class="specimen">'
            f'<span class="path">{{typography.{html_mod.escape(name)}}}</span>'
            f'<div class="sample" style="{html_mod.escape(style)}">The quick brown fox jumps over the lazy dog — 0123456789</div>'
            f'<div class="sub">{html_mod.escape(" · ".join(meta_parts))}</div>'
            '</div>'
        )
    return f'<div class="type-specimens">{"".join(blocks)}</div>'


def render_scale(name: str, scale: dict) -> str:
    if not scale:
        return ""
    rows: list[str] = []

    def _px(v: str) -> float:
        m = re.match(r"([\d.]+)", str(v))
        return float(m.group(1)) if m else 0

    items = sorted(scale.items(), key=lambda kv: _px(str(kv[1])))
    max_px = max((_px(str(v)) for _, v in items), default=1) or 1
    for key, value in items:
        value = str(value)
        bar_width = min(100, (_px(value) / max_px) * 100)
        rows.append(
            '<div class="scale-row">'
            f'<span class="label">{{{name}.{html_mod.escape(key)}}}</span>'
            f'<div class="bar" style="width: {bar_width:.1f}%"></div>'
            f'<span class="meta">{html_mod.escape(value)}</span>'
            '</div>'
        )
    return f'<div class="scale-list">{"".join(rows)}</div>'


def render_radii(rounded: dict) -> str:
    if not rounded:
        return ""
    cards: list[str] = []
    for key, value in rounded.items():
        cards.append(
            '<div class="card">'
            f'<div class="radius-demo" style="border-radius: {html_mod.escape(str(value))}"></div>'
            f'<strong>{html_mod.escape(key)}</strong>'
            f'<span>{html_mod.escape(str(value))}</span>'
            f'<span class="path">{{rounded.{html_mod.escape(key)}}}</span>'
            '</div>'
        )
    return f'<div class="sample-grid">{"".join(cards)}</div>'


def render_elevation() -> str:
    levels = [
        ("Level 0", "none"),
        ("Level 1", "0 1px 2px rgba(0,0,0,0.10)"),
        ("Level 2", "0 2px 8px rgba(0,0,0,0.15)"),
        ("Level 3", "0 4px 16px rgba(0,0,0,0.20)"),
    ]
    cards = [
        '<div class="card" style="box-shadow: ' + shadow + ';">'
        f'<strong>{html_mod.escape(name)}</strong>'
        f'<span style="font-size: 10.5px;">{html_mod.escape(shadow)}</span>'
        '</div>'
        for name, shadow in levels
    ]
    return f'<div class="sample-grid">{"".join(cards)}</div>'


def render_motion(motion: dict) -> str:
    if not motion:
        return (
            "<p><em>No motion tokens declared. Add a <code>motion:</code> block to the YAML front matter to document easings and durations — e.g. </em>"
            "<code>fast: 120ms ease-out</code>.</p>"
        )
    cards: list[str] = []
    for key, value in motion.items():
        value_str = str(value)
        cards.append(
            '<div class="card">'
            f'<strong>{html_mod.escape(key)}</strong>'
            f'<span>{html_mod.escape(value_str)}</span>'
            f'<span class="path">{{motion.{html_mod.escape(key)}}}</span>'
            '</div>'
        )
    return f'<div class="sample-grid">{"".join(cards)}</div>'


# ─── Component rendering (one section per component) ─────────────────────────


def _component_preview(base: str, variants: dict, data: dict) -> str:
    def style(props: dict) -> str:
        bg = resolve(props.get("backgroundColor", ""), data)
        fg = resolve(props.get("textColor", ""), data)
        pad = resolve(props.get("padding", ""), data)
        radius = resolve(props.get("rounded", ""), data)
        typo = resolve(props.get("typography", ""), data)
        parts = []
        if bg: parts.append(f"background: {bg}")
        if fg: parts.append(f"color: {fg}")
        if pad: parts.append(f"padding: {pad}")
        if radius: parts.append(f"border-radius: {radius}")
        if isinstance(typo, dict):
            if typo.get("fontSize"):   parts.append(f"font-size: {typo['fontSize']}")
            if typo.get("fontWeight"): parts.append(f"font-weight: {typo['fontWeight']}")
            if typo.get("fontFamily"): parts.append(f"font-family: {typo['fontFamily']}, var(--sans)")
            if typo.get("lineHeight"): parts.append(f"line-height: {typo['lineHeight']}")
        parts.append("border: none; cursor: pointer;")
        return "; ".join(parts)

    lower = base.lower()
    if "button" in lower:
        return "".join(
            f'<button style="{html_mod.escape(style(p))}">{html_mod.escape(n)}</button>'
            for n, p in variants.items()
        )
    if "input" in lower:
        props = variants.get(base, next(iter(variants.values())))
        return f'<input type="text" placeholder="Sample input" style="{html_mod.escape(style(props))} border: 1px solid var(--border);" />'
    if "card" in lower:
        props = variants.get(base, next(iter(variants.values())))
        return (
            f'<div style="{html_mod.escape(style(props))} min-width: 240px;">'
            f'<strong>Card title</strong><p style="margin: 8px 0 0; font-size: 14px;">Card body content.</p>'
            '</div>'
        )
    props = variants.get(base, next(iter(variants.values())))
    return f'<div style="{html_mod.escape(style(props))} min-width: 160px; text-align: center;">{html_mod.escape(base)}</div>'


def iter_components(components: dict) -> list[tuple[str, dict[str, dict]]]:
    """Group variants under the base component name. Returns [(base, {name: props, …}), …]."""
    if not components:
        return []
    base_names = {k.split("-")[0] for k in components}
    groups: dict[str, dict[str, dict]] = {}
    for name, props in components.items():
        if not isinstance(props, dict):
            continue
        base = name
        for candidate in base_names:
            if name == candidate or name.startswith(candidate + "-"):
                if candidate in components or candidate == name:
                    base = candidate
                    break
        groups.setdefault(base, {})[name] = props
    return list(groups.items())


def render_component_card(base: str, variants: dict, data: dict) -> str:
    main_props = variants.get(base) or next(iter(variants.values()))
    variant_names = [v for v in variants if v != base]
    variant_pills = ""
    if variant_names:
        spans = "".join(f'<span class="pill">{html_mod.escape(v)}</span>' for v in variant_names)
        variant_pills = f'<div class="variants"><span style="color: var(--fg-subtle);">Variants:</span>{spans}</div>'

    def _resolved_cell(v: Any) -> str:
        if not isinstance(v, str) or "{" not in v:
            return ""
        return _fmt_resolved(resolve(v, data))

    rows = "".join(
        f'<tr><td>{html_mod.escape(k)}</td><td>{html_mod.escape(str(v))}</td><td>{html_mod.escape(_resolved_cell(v))}</td></tr>'
        for k, v in main_props.items()
    )
    return (
        f'<div class="component" id="{_slug(base)}">'
        f'<h3>{html_mod.escape(base)}</h3>'
        f'<div class="preview">{_component_preview(base, variants, data)}</div>'
        f'{variant_pills}'
        '<div class="props">'
        '<table><thead><tr><th>Property</th><th>Value</th><th>Resolved</th></tr></thead>'
        f'<tbody>{rows}</tbody></table>'
        '</div></div>'
    )


def render_contrast(components: dict, data: dict) -> str:
    if not components:
        return ""
    rows: list[str] = []
    for name, props in components.items():
        if not isinstance(props, dict):
            continue
        bg = resolve(props.get("backgroundColor", ""), data)
        fg = resolve(props.get("textColor", ""), data)
        if not (isinstance(bg, str) and bg.startswith("#") and isinstance(fg, str) and fg.startswith("#")):
            continue
        ratio = contrast_ratio(fg, bg)
        grade = wcag_grade(ratio)
        grade_class = grade.lower().replace(" ", "-")
        rows.append(
            '<tr>'
            f'<td><code>{html_mod.escape(name)}</code></td>'
            f'<td><code>{html_mod.escape(fg)}</code></td>'
            f'<td><code>{html_mod.escape(bg)}</code></td>'
            f'<td>{ratio:.2f}:1</td>'
            f'<td><span class="contrast-grade {grade_class}">{html_mod.escape(grade)}</span></td>'
            '</tr>'
        )
    if not rows:
        return "<p><em>No backgroundColor/textColor pairs in components yet.</em></p>"
    return (
        "<table>"
        "<thead><tr><th>Component</th><th>Foreground</th><th>Background</th><th>Ratio</th><th>WCAG</th></tr></thead>"
        f"<tbody>{''.join(rows)}</tbody></table>"
    )


# ─── Sidebar + full-page assembly ─────────────────────────────────────────────


def build_sidebar(data: dict, components_list: list[tuple[str, dict[str, dict]]],
                  patterns: list[tuple[str, str]], project_name: str, version: str) -> str:
    grad = _first_gradient(data) or _synthesize_gradient(
        [(k, v) for k, v in data.get("colors", {}).items() if isinstance(v, str)]
    )
    initial = _brand_initial(project_name)
    nav_groups: list[str] = []

    # Foundations
    foundations = [("Colors", "colors"), ("Typography", "typography")]
    if data.get("spacing"):  foundations.append(("Spacing", "spacing"))
    if data.get("rounded"):  foundations.append(("Radius", "radius"))
    foundations.append(("Shadows", "shadows"))
    foundations.append(("Motion", "motion"))
    nav_groups.append(_nav_group("Foundations", foundations))

    # Components
    if components_list:
        comp_links = [(name, _slug(name)) for name, _ in components_list]
        nav_groups.append(_nav_group("Components", comp_links))

    # Patterns
    if patterns:
        pat_links = [(name, f"pattern-{_slug(name)}") for name, _ in patterns]
        nav_groups.append(_nav_group("Patterns", pat_links))

    # Principles
    nav_groups.append(_nav_group("Principles", [("Design principles", "dos-and-donts"),
                                                 ("Accessibility", "accessibility")]))

    return (
        '<aside class="sidebar">'
        '<div class="brand">'
        f'<div class="mark" style="background: {html_mod.escape(grad)}">{html_mod.escape(initial)}</div>'
        '<div>'
        f'<div class="name">{html_mod.escape(project_name)}</div>'
        f'<div class="sub">v{html_mod.escape(version)}</div>'
        '</div></div>'
        + "".join(nav_groups) +
        '</aside>'
    )


def _nav_group(title: str, items: list[tuple[str, str]]) -> str:
    links = "".join(f'<a href="#{slug}">{html_mod.escape(label)}</a>' for label, slug in items)
    return (
        '<div class="nav-group">'
        f'<div class="nav-group-title">{html_mod.escape(title)}</div>'
        f'{links}'
        '</div>'
    )


def build_html(data: dict, sections: dict[str, str], source_path: Path) -> str:
    name = str(data.get("name", "Design System"))
    version = str(data.get("version", "alpha"))
    description = str(data.get("description", ""))
    colors = data.get("colors", {}) or {}
    typography = data.get("typography", {}) or {}
    spacing = data.get("spacing", {}) or {}
    rounded = data.get("rounded", {}) or {}
    motion = data.get("motion", {}) or {}
    components = data.get("components", {}) or {}

    components_list = iter_components(components)
    patterns_body = sections.get("Patterns", "")
    patterns = extract_subsections(patterns_body) if patterns_body else []

    today = dt.date.today().isoformat()

    def _prose(section_name: str) -> str:
        body = sections.get(section_name, "")
        return f'<p class="intro">{_inline(body.split(chr(10))[0])}</p>' if body else ""

    def _section(id_: str, title: str, prose_key: str, body: str) -> str:
        intro_text = sections.get(prose_key, "")
        intro_html = ""
        if intro_text:
            # Take the first paragraph as intro
            first_para = intro_text.split("\n\n", 1)[0].strip()
            if first_para and not first_para.startswith(("|", "-", "*")):
                intro_html = f'<p class="intro">{_inline(first_para)}</p>'
        return (
            f'<section class="sec" id="{id_}">'
            f'<h2>{html_mod.escape(title)}</h2>'
            f'{intro_html}'
            f'{body}'
            '</section>'
        )

    overview_body = md_to_html(sections.get("Overview", ""))

    components_sections = ""
    if components_list:
        components_sections = "".join(
            render_component_card(base, variants, data)
            for base, variants in components_list
        )

    patterns_sections = ""
    if patterns:
        for pname, pbody in patterns:
            patterns_sections += (
                f'<div class="pattern" id="pattern-{_slug(pname)}">'
                f'<h3>{html_mod.escape(pname)}</h3>'
                f'{md_to_html(pbody)}'
                '</div>'
            )

    dos_donts = md_to_html(sections.get("Do's and Don'ts", ""))

    sidebar = build_sidebar(data, components_list, patterns, name, version)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html_mod.escape(name)} — Design System</title>
<style>{CSS}</style>
</head>
<body>
<div class="layout">
{sidebar}
<main>

<div class="page-header">
  <div>
    <h1>{html_mod.escape(name)}</h1>
    <p class="description">{html_mod.escape(description)}</p>
    <div class="meta">
      <span>Version <code>{html_mod.escape(version)}</code></span>
      <span>Format: <code>Google Stitch DESIGN.md</code></span>
      <span>Source: <code>{html_mod.escape(str(source_path))}</code></span>
      <span>Generated: <code>{today}</code></span>
    </div>
  </div>
  <button class="dark-toggle" type="button">☾ Dark mode</button>
</div>

{_section("overview", "Overview", "Overview", overview_body) if overview_body else ""}

<section class="sec" id="colors">
  <h2>Colors</h2>
  {_section_prose_html(sections.get("Colors", ""))}
  {render_gradient_hero(data, name)}
  {render_palette(colors, data)}
</section>

<section class="sec" id="typography">
  <h2>Typography</h2>
  {_section_prose_html(sections.get("Typography", ""))}
  {render_typography(typography)}
</section>

<section class="sec" id="spacing">
  <h2>Spacing</h2>
  {_section_prose_html(sections.get("Layout", ""))}
  {render_scale("spacing", spacing)}
</section>

<section class="sec" id="radius">
  <h2>Radius</h2>
  {_section_prose_html(sections.get("Shapes", ""))}
  {render_radii(rounded)}
</section>

<section class="sec" id="shadows">
  <h2>Shadows</h2>
  {_section_prose_html(sections.get("Elevation & Depth", ""))}
  {render_elevation()}
</section>

<section class="sec" id="motion">
  <h2>Motion</h2>
  {render_motion(motion)}
</section>

{f'<section class="sec" id="components-root"><h2>Components</h2>{_section_prose_html(sections.get("Components", ""))}{components_sections}</section>' if components_list else ""}

{f'<section class="sec" id="patterns-root"><h2>Patterns</h2>{patterns_sections}</section>' if patterns_sections else ""}

<section class="sec" id="accessibility">
  <h2>Accessibility — Contrast Report</h2>
  <p class="intro">Every component's <code>backgroundColor</code>/<code>textColor</code> pair is evaluated against WCAG 2.2. AA requires 4.5:1 for body text and 3:1 for large text; AAA requires 7:1 and 4.5:1 respectively.</p>
  {render_contrast(components, data)}
</section>

<section class="sec" id="dos-and-donts">
  <h2>Design principles</h2>
  {dos_donts}
</section>

</main>
</div>

<script>{SCRIPT}</script>
</body>
</html>
"""


def _section_prose_html(body: str) -> str:
    if not body:
        return ""
    first_para = body.split("\n\n", 1)[0].strip()
    if not first_para or first_para.startswith(("|", "-", "*")):
        return ""
    return f'<p class="intro">{_inline(first_para)}</p>'


# ─── CLI ──────────────────────────────────────────────────────────────────────


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Render DESIGN.md to a self-contained HTML visualization.")
    parser.add_argument("--input", "-i", default="docs/ux/DESIGN.md")
    parser.add_argument("--output", "-o", default=None)
    args = parser.parse_args(argv)

    in_path = Path(args.input)
    if not in_path.exists():
        print(f"error: input not found: {in_path}", file=sys.stderr)
        return 1

    text = in_path.read_text(encoding="utf-8")
    try:
        yaml_text, body = parse_front_matter(text)
    except ValueError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2
    data = parse_yaml(yaml_text)
    sections = extract_sections(body)

    out_path = Path(args.output) if args.output else in_path.with_suffix(".html")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(build_html(data, sections, in_path), encoding="utf-8")

    colors_flat = _flatten_colors(data.get("colors", {}) or {}, data)
    n_typo = len(data.get("typography", {}) or {})
    n_components = len(iter_components(data.get("components", {}) or {}))
    print(f"✓ Rendered {in_path} -> {out_path}")
    print(f"  {len(colors_flat)} colors · {n_typo} type tokens · {n_components} components")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
