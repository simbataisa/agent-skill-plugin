# Component Implementation & Layout Guide

> Reference file for the BMAD Frontend Engineer agent.

### 1. Implement Components and Layouts

**Mandate:** Build reusable, well-tested UI components that follow design specifications.

- Read implementation stories and design specifications from `docs/stories/` and design system documentation
- Review the **Solution Architecture** to understand frontend topology (SPA, SSR, micro frontends)
- Implement components following established patterns in the component library
- Use semantic HTML5; avoid divitis (excessive nested divs)
- Implement layout systems using modern CSS (Grid, Flexbox)
- Ensure pixel-perfect alignment with design specifications
- Use consistent naming conventions (BEM, Atomic, or component-based)
- Document component props, usage examples, and variants

**Component development checklist:**
- [ ] Component matches design specification in all states (default, hover, focus, disabled, error)
- [ ] Props are clearly defined with TypeScript/PropTypes
- [ ] Component is reusable and not tightly coupled to parent
- [ ] Accessibility is built in (ARIA labels, semantic HTML)
- [ ] Responsive breakpoints match design system
- [ ] Component has comprehensive Storybook stories
- [ ] Unit tests cover all variations and edge cases

**Example: Building a Button Component**

```tsx
// components/Button/Button.tsx
import React, { ReactNode, ButtonHTMLAttributes } from 'react';
import styles from './Button.module.css';

export type ButtonVariant = 'primary' | 'secondary' | 'tertiary' | 'danger';
export type ButtonSize = 'sm' | 'md' | 'lg';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  /** Visual style variant */
  variant?: ButtonVariant;
  /** Button size */
  size?: ButtonSize;
  /** Loading state - shows spinner, disables button */
  isLoading?: boolean;
  /** Icon to display before text */
  icon?: ReactNode;
  /** Icon to display after text */
  iconAfter?: ReactNode;
  /** Full width button */
  fullWidth?: boolean;
  /** Button text */
  children: ReactNode;
}

export const Button: React.FC<ButtonProps> = ({
  variant = 'primary',
  size = 'md',
  isLoading = false,
  icon,
  iconAfter,
  fullWidth = false,
  disabled = false,
  className,
  ...props
}) => {
  const classNames = [
    styles.button,
    styles[variant],
    styles[size],
    fullWidth && styles.fullWidth,
    isLoading && styles.loading,
    disabled && styles.disabled,
    className,
  ].filter(Boolean).join(' ');

  return (
    <button
      className={classNames}
      disabled={disabled || isLoading}
      aria-disabled={disabled || isLoading}
      aria-busy={isLoading}
      {...props}
    >
      {isLoading && <span className={styles.spinner} aria-hidden="true" />}
      {icon && <span className={styles.iconBefore}>{icon}</span>}
      <span>{children}</span>
      {iconAfter && <span className={styles.iconAfter}>{iconAfter}</span>}
    </button>
  );
};

// components/Button/Button.module.css
.button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--spacing-2);
  font-family: var(--font-family-sans);
  font-weight: 600;
  border: none;
  border-radius: var(--border-radius-md);
  cursor: pointer;
  transition: all var(--transition-duration-normal);
  white-space: nowrap;
}

.button:hover:not(.disabled) {
  transform: translateY(-1px);
  box-shadow: var(--shadow-sm);
}

.button:focus-visible {
  outline: 2px solid var(--color-focus);
  outline-offset: 2px;
}

.button:disabled,
.button.disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.primary {
  background-color: var(--color-primary);
  color: var(--color-white);
}

.primary:hover:not(.disabled) {
  background-color: var(--color-primary-dark);
}

.secondary {
  background-color: var(--color-secondary);
  color: var(--color-text-primary);
  border: 1px solid var(--color-border);
}

.secondary:hover:not(.disabled) {
  background-color: var(--color-secondary-dark);
}

/* Size variants */
.sm {
  padding: var(--spacing-1) var(--spacing-3);
  font-size: var(--font-size-sm);
  height: 32px;
}

.md {
  padding: var(--spacing-2) var(--spacing-4);
  font-size: var(--font-size-base);
  height: 40px;
}

.lg {
  padding: var(--spacing-3) var(--spacing-5);
  font-size: var(--font-size-lg);
  height: 48px;
}

.fullWidth {
  width: 100%;
}

.loading {
  opacity: 0.7;
}

.spinner {
  display: inline-block;
  width: 1em;
  height: 1em;
  border: 2px solid currentColor;
  border-right-color: transparent;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

// components/Button/Button.stories.tsx
import { StoryObj } from '@storybook/react';
import { Button } from './Button';

const meta = {
  title: 'Components/Button',
  component: Button,
  argTypes: {
    variant: {
      options: ['primary', 'secondary', 'tertiary', 'danger'],
      control: { type: 'radio' },
    },
    size: {
      options: ['sm', 'md', 'lg'],
      control: { type: 'radio' },
    },
  },
};

export default meta;
type Story = StoryObj<typeof Button>;

export const Primary: Story = {
  args: {
    variant: 'primary',
    children: 'Click Me',
  },
};

export const Secondary: Story = {
  args: {
    variant: 'secondary',
    children: 'Secondary Button',
  },
};

export const Loading: Story = {
  args: {
    variant: 'primary',
    isLoading: true,
    children: 'Loading...',
  },
};

export const Disabled: Story = {
  args: {
    variant: 'primary',
    disabled: true,
    children: 'Disabled',
  },
};

// components/Button/Button.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Button } from './Button';

describe('Button', () => {
  it('renders button with text', () => {
    render(<Button>Click Me</Button>);
    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument();
  });

  it('calls onClick handler when clicked', async () => {
    const handleClick = jest.fn();
    render(<Button onClick={handleClick}>Click Me</Button>);

    await userEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('is disabled when disabled prop is true', () => {
    render(<Button disabled>Disabled</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });

  it('shows loading state when isLoading is true', () => {
    render(<Button isLoading>Loading</Button>);
    expect(screen.getByRole('button')).toHaveAttribute('aria-busy', 'true');
    expect(screen.getByRole('button')).toBeDisabled();
  });

  it('applies variant class', () => {
    const { container } = render(<Button variant="secondary">Button</Button>);
    expect(container.firstChild).toHaveClass('secondary');
  });

  it('applies size class', () => {
    const { container } = render(<Button size="lg">Button</Button>);
    expect(container.firstChild).toHaveClass('lg');
  });
});
```

### 2. Responsive Design and Breakpoints

**Mandate:** Ensure interfaces work seamlessly across all device sizes.

- Review design system breakpoints: mobile-first approach (sm: 480px, md: 768px, lg: 1024px, xl: 1280px)
- Implement CSS media queries or CSS-in-JS breakpoints consistently
- Test on actual devices and emulators (Chrome DevTools, BrowserStack)
- Use relative units (em, rem) instead of fixed pixels for scalability
- Implement touch-friendly targets (minimum 48x48px)
- Optimize images for different viewport sizes (picture element, srcset)
- Test text readability, button sizes, and spacing at all breakpoints

**Responsive checklist:**
- [ ] Mobile layout tested on phones (375px, 390px, 414px widths)
- [ ] Tablet layout tested (768px+)
- [ ] Desktop layout tested (1024px+)
- [ ] Touch targets are at least 48x48px
- [ ] Images respond to viewport (srcset, picture element)
- [ ] No horizontal scrolling on mobile
- [ ] Typography scales appropriately
- [ ] Performance tested (Lighthouse score >90)

