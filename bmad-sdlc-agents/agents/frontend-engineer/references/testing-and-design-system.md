# Testing Strategy & Design System Guide

> Reference file for the BMAD Frontend Engineer agent.

### 7. Testing Strategy

**Mandate:** Ensure code quality through comprehensive testing.

**Unit Tests:**
- Test components in isolation with mocked children and props
- Test logic (functions, reducers, selectors)
- Aim for >80% coverage on business logic
- Use React Testing Library (behavior-driven, not implementation-driven)

**Integration Tests:**
- Test component interactions and state changes
- Test form submission and validation
- Test API integration with mocked endpoints

**E2E Tests:**
- Test complete user flows (login → navigate → submit form)
- Use tools like Playwright or Cypress
- Test on multiple browsers

**Testing pattern:**

```tsx
// components/UserForm.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { UserForm } from './UserForm';

describe('UserForm', () => {
  it('renders form with required fields', () => {
    render(<UserForm onSubmit={jest.fn()} />);
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument();
  });

  it('validates email format', async () => {
    const handleSubmit = jest.fn();
    render(<UserForm onSubmit={handleSubmit} />);

    await userEvent.type(screen.getByLabelText(/email/i), 'invalid-email');
    await userEvent.click(screen.getByRole('button', { name: /submit/i }));

    await waitFor(() => {
      expect(screen.getByText(/invalid email/i)).toBeInTheDocument();
    });
    expect(handleSubmit).not.toHaveBeenCalled();
  });

  it('submits form with valid data', async () => {
    const handleSubmit = jest.fn();
    render(<UserForm onSubmit={handleSubmit} />);

    await userEvent.type(screen.getByLabelText(/email/i), 'user@example.com');
    await userEvent.type(screen.getByLabelText(/password/i), 'SecurePass123');
    await userEvent.click(screen.getByRole('button', { name: /submit/i }));

    await waitFor(() => {
      expect(handleSubmit).toHaveBeenCalledWith({
        email: 'user@example.com',
        password: 'SecurePass123',
      });
    });
  });
});

// pages/Dashboard.test.tsx (Integration test)
import { render, screen, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Dashboard } from './Dashboard';

// Mock API client
jest.mock('../api/client', () => ({
  createApiClient: () => ({
    get: jest.fn().mockResolvedValue({
      data: [{ id: '1', name: 'John', email: 'john@example.com' }],
    }),
  }),
}));

describe('Dashboard', () => {
  it('displays user list after loading', async () => {
    const queryClient = new QueryClient();
    render(
      <QueryClientProvider client={queryClient}>
        <Dashboard />
      </QueryClientProvider>
    );

    expect(screen.getByText(/loading/i)).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('John')).toBeInTheDocument();
    });
  });
});
```

### 8. Design System and Component Library

**Mandate:** Build a shared component library that scales across products.

- Maintain a living component library in Storybook
- Document design tokens: colors, typography, spacing, shadows, animations
- Create component variants for all use cases
- Use consistent naming: Component, ComponentVariant, ComponentSize
- Export TypeScript types for all components
- Publish to npm or internal registry for sharing across teams
- Version components and maintain changelog

**Design system structure:**

```
src/
├── design-system/
│   ├── tokens/
│   │   ├── colors.ts
│   │   ├── typography.ts
│   │   ├── spacing.ts
│   │   └── shadows.ts
│   ├── components/
│   │   ├── Button/
│   │   ├── Input/
│   │   ├── Card/
│   │   ├── Modal/
│   │   └── ...
│   └── index.ts
```

