---
description: "[Frontend Engineer] Create a React component following the project's design system and conventions. Includes component, tests, and Storybook story."
argument-hint: "[component name] [type: 'page' | 'feature' | 'ui']"
---

Create a new React component with tests and Storybook story following the design system.

## Steps

1. Parse $ARGUMENTS to extract:
   - Component name (e.g., 'UserCard', 'LoginForm')
   - Component type: 'page' (full page), 'feature' (feature-level), 'ui' (reusable UI component)

2. Read `.bmad/team-conventions.md` for naming patterns and folder structure.

3. Read `docs/ux/DESIGN.md` to understand design tokens (colors, typography, spacing, shadows).

4. Read `.bmad/tech-stack.md` to confirm React version and UI framework if applicable.

5. Determine component folder location:
   - **Page components**: `src/pages/[ComponentName]/`
   - **Feature components**: `src/features/[FeatureName]/components/[ComponentName]/`
   - **UI components**: `src/ui/components/[ComponentName]/` or `src/components/`

6. Create the component structure:
   - **Component file** (TypeScript): `[ComponentName].tsx`
     - Proper TypeScript typing for props
     - Accessibility attributes (aria-*, role)
     - Responsive design considerations
     - Error boundary wrapper if needed
   - **Test file**: `[ComponentName].test.tsx`
     - Unit tests for component behavior
     - Props validation tests
     - Accessibility testing (at least one a11y assertion)
     - Happy path and edge case coverage
   - **Storybook story** (optional): `[ComponentName].stories.tsx`
     - Default story with typical props
     - Stories for different states (loading, error, disabled)
     - Interactive story controls (if applicable)

7. If Pencil or Figma MCP is available:
   - Search the design file for the component's visual spec (frame/component)
   - Reference design tokens from the spec in the implementation
   - Ensure visual fidelity

8. Fill in the component with:
   - Proper TypeScript interfaces for props
   - JSX matching the design system design
   - Event handlers (onChange, onClick, etc.)
   - Conditional rendering for different states

9. Write unit tests covering:
   - Rendering with different props
   - User interactions (clicks, form input)
   - Accessibility (keyboard navigation, focus, ARIA)
   - Error states

10. Confirm: "Component [ComponentName] created. [location]. Tests: [N] passing. Ready for use."
