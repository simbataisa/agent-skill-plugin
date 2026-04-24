---
name: "Vikki Design System"
version: "0.2"
description: "A consistent, accessible, regulator-aware UI language for Vietnam's digital bank."
gradients:
  brand: "linear-gradient(90deg, #6B2FD6 0%, #E31B8E 52%, #F97316 100%)"
colors:
  primary-50: "#FDF2F9"
  primary-100: "#FCE7F3"
  primary-200: "#FBCFE8"
  primary-300: "#F9A8D4"
  primary-400: "#F472B6"
  primary-500: "#E31B8E"
  primary-600: "#BE1479"
  primary-700: "#931060"
  primary-800: "#720C4B"
  primary-900: "#5B0939"
  accent-300: "#FBBF24"
  accent-500: "#F97316"
  accent-700: "#C2410C"
  neutral-0: "#FFFFFF"
  neutral-50: "#F7F7F8"
  neutral-200: "#E6E8EC"
  neutral-500: "#5A6070"
  neutral-900: "#0F1115"
  success: "#16A34A"
  warning: "#F59E0B"
  danger: "#DC2626"
typography:
  display-lg:
    fontFamily: "Inter"
    fontSize: "40px"
    fontWeight: 700
    lineHeight: "48px"
    letterSpacing: "-0.02em"
  body-md:
    fontFamily: "Inter"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: "24px"
  label:
    fontFamily: "Inter"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: "16px"
    letterSpacing: "0.04em"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  base: "16px"
  lg: "24px"
  xl: "32px"
rounded:
  sm: "4px"
  md: "10px"
  lg: "16px"
  full: "9999px"
motion:
  fast: "120ms ease-out"
  base: "220ms ease-out"
  slow: "360ms ease-out"
components:
  button:
    backgroundColor: "{colors.primary-500}"
    textColor: "{colors.neutral-0}"
    typography: "{typography.body-md}"
    rounded: "{rounded.md}"
    padding: "{spacing.md} {spacing.lg}"
  button-hover:
    backgroundColor: "{colors.primary-600}"
    textColor: "{colors.neutral-0}"
  button-secondary:
    backgroundColor: "{colors.neutral-0}"
    textColor: "{colors.primary-500}"
    rounded: "{rounded.md}"
    padding: "{spacing.md} {spacing.lg}"
  input:
    backgroundColor: "{colors.neutral-0}"
    textColor: "{colors.neutral-900}"
    rounded: "{rounded.sm}"
    padding: "{spacing.sm} {spacing.md}"
  card:
    backgroundColor: "{colors.neutral-0}"
    textColor: "{colors.neutral-900}"
    rounded: "{rounded.lg}"
    padding: "{spacing.lg}"
---

## Overview

Vikki is a gradient, not a single color. Purple on the left, magenta through the middle, orange on the right — plus a cyan accent carried over from the tagline. Every color in production must be a token; no hex literals in components.

## Colors

Vikki's palette centers on the Primary Magenta ramp. Use `{colors.primary-500}` for solid-color UI (buttons, focus rings, chips) and the brand gradient for hero surfaces only.

## Typography

Inter across every platform. Three tiers only: display for page-level hierarchy, body for reading, label for metadata and chrome.

## Patterns

### VNeID onboarding

Vietnamese National ID verification flow. Three steps: capture → verify → confirm. Each step uses a `card` component stack with the `button` primary action at the bottom.

### Transfer flow

Recipient → amount → review → confirm. Amount input uses the `input` component with the `display-lg` type token.

### Transactions list

Infinite-scroll list of transaction rows. Row: avatar (brand gradient initial) + description + amount. Amounts >= 0 use `{colors.success}`, negative use `{colors.danger}`.

## Do's and Don'ts

### Do

- Use the brand gradient for onboarding hero, app launch, first-touch moments.
- Pair amounts with a sign or direction icon — never colour alone.
- Reference every colour via a token path like `{colors.primary-500}`.

### Don't

- Don't apply the brand gradient to form buttons. Use `{colors.primary-500}` for buttons.
- Don't ship PII in synthetic preview data.

### Changelog

| Date       | Version | Change                            | Driven by                          |
|------------|---------|-----------------------------------|------------------------------------|
| 2026-04-22 | 0.2.0   | Gradient brand refresh + scales   | Q2 brand refresh                   |
| 2026-04-01 | 0.1.0   | Initial seed                      | UX Designer — project init         |
