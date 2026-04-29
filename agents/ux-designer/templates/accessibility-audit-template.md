# Accessibility Audit: [Screen/Component Name]

### Perceivable

- [ ] Color contrast ratio ≥ 4.5:1 for normal text, ≥ 3:1 for large text
- [ ] Information not conveyed by color alone (use icons, patterns, text)
- [ ] All images have descriptive alt text (or alt="" if decorative)
- [ ] Video/audio has captions or transcripts
- [ ] Text resizable to 200% without loss of content

### Operable

- [ ] All functionality accessible via keyboard (Tab, Enter, Space, Escape, arrows)
- [ ] Visible focus indicator on all interactive elements
- [ ] No keyboard traps
- [ ] Skip navigation link present
- [ ] Touch targets ≥ 44x44px on mobile
- [ ] No time limits (or user-adjustable if unavoidable)

### Understandable

- [ ] Form labels associated with inputs (htmlFor/id)
- [ ] Error messages specific and actionable ("Email format: name@example.com")
- [ ] Consistent navigation across pages
- [ ] Language attribute set on <html>
- [ ] Abbreviations and jargon explained on first use

### Robust

- [ ] Valid semantic HTML (headings hierarchy, landmarks, lists)
- [ ] ARIA labels on custom components (role, aria-label, aria-describedby)
- [ ] Live regions for dynamic content updates (aria-live="polite")
- [ ] Works with screen readers (VoiceOver, NVDA, JAWS)
- [ ] Works with browser zoom and text scaling
```

**Output:** `docs/ux/accessibility-audit.md`

### 8. UI Specification & Engineering Handoff

Create detailed UI specs that Frontend and Mobile engineers can implement without guessing. The goal is zero ambiguity — every interaction, every state, every edge case documented.

**UI Spec Format:**

```markdown
