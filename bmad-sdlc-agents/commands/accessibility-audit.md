---
description: Run a WCAG 2.2 AA accessibility audit against the current UX designs or a deployed URL. Produces docs/ux/accessibility-audit.md.
argument-hint: "[target: 'designs' | URL]"
---

Run a comprehensive WCAG 2.2 AA accessibility audit against design artifacts or a live URL.

## Steps

1. Parse $ARGUMENTS to determine the audit target: 'designs' (audit UX files) or a URL (live site audit).

2. If target is 'designs':
   - Read `docs/ux/design-system.md` and `docs/ux/ui-spec.md` if they exist.
   - Identify all wireframe files in `docs/ux/wireframes/` directory.
   - Review each wireframe for WCAG violations:
     - **Color Contrast**: text contrast ratio 4.5:1 (normal text), 3:1 (large text >= 18pt)
     - **Keyboard Navigation**: all interactive elements reachable via Tab, focus visible
     - **Focus Indicators**: visible focus styling on all focusable elements
     - **Alt Text**: images have descriptive alt text (not redundant with caption)
     - **Heading Hierarchy**: headings follow logical order (H1 → H2 → H3, no skipping)
     - **Form Labels**: all form inputs have associated labels
     - **ARIA Landmarks**: semantic HTML or ARIA roles (main, nav, complementary)
     - **Color Dependency**: information not conveyed by color alone (use icons, text, pattern)

3. If target is a URL:
   - Use browser tools to navigate to the URL.
   - Capture screenshots and analyze rendered output.
   - Run automated checks (via console JavaScript if available) and manual keyboard navigation testing.
   - Check the same criteria as above plus:
     - **Skip Links**: ability to skip to main content
     - **Focus Management**: focus moves to new content on page changes
     - **ARIA Live Regions**: dynamic updates announced to screen readers

4. For each violation found:
   - Severity: Critical (blocks access), High (major usability issue), Medium (minor usability), Low (minor inconsistency)
   - WCAG criterion violated (e.g. 1.4.3 Contrast Minimum)
   - Description of the issue
   - Remediation guidance

5. Fill the audit template with: Audit Scope, Summary (# of Critical/High/Medium/Low violations), Detailed Findings (organized by WCAG criterion), Remediation Roadmap.

6. Save to `docs/ux/accessibility-audit.md`.

7. Confirm: "Accessibility audit completed → `docs/ux/accessibility-audit.md`. [N] violations found ([C] critical, [H] high)."
