# Accessibility & State Management Guide

> Reference file for the BMAD Frontend Engineer agent.

### 3. Accessibility (WCAG 2.1 AA)

**Mandate:** Build interfaces that are usable by everyone, including people with disabilities.

- Use semantic HTML: `<button>` not `<div onclick>`, `<nav>`, `<main>`, `<article>`, etc.
- Provide ARIA labels and descriptions where semantic HTML is insufficient
- Ensure 4.5:1 color contrast ratio for normal text, 3:1 for large text
- Implement keyboard navigation: Tab order, Enter/Space activation, Escape to close
- Test with screen readers (NVDA, JAWS, VoiceOver)
- Implement focus management for modals, drawers, and dynamic content
- Use ARIA live regions for dynamic updates (alerts, notifications)
- Test with accessibility tools (Axe, Lighthouse, WebAIM)

**Accessibility example:**

```tsx
// Modal with proper focus management and ARIA
interface ModalProps {
  isOpen: boolean;
  title: string;
  onClose: () => void;
  children: ReactNode;
}

export const Modal: React.FC<ModalProps> = ({ isOpen, title, onClose, children }) => {
  const modalRef = useRef<HTMLDivElement>(null);
  const initialFocusRef = useRef<HTMLButtonElement>(null);

  // Focus management: return focus to trigger button when closing
  useEffect(() => {
    if (isOpen) {
      // Focus first focusable element in modal
      initialFocusRef.current?.focus();
      // Prevent body scroll
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }
  }, [isOpen]);

  // Close on Escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };

    if (isOpen) {
      document.addEventListener('keydown', handleKeyDown);
      return () => document.removeEventListener('keydown', handleKeyDown);
    }
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div
      className="modal-overlay"
      onClick={onClose}
      role="presentation"
      aria-hidden={!isOpen}
    >
      <div
        ref={modalRef}
        className="modal-content"
        role="dialog"
        aria-modal="true"
        aria-labelledby="modal-title"
        onClick={(e) => e.stopPropagation()}
      >
        <h2 id="modal-title">{title}</h2>
        {children}
        <button
          ref={initialFocusRef}
          onClick={onClose}
          aria-label="Close modal"
        >
          Close
        </button>
      </div>
    </div>
  );
};
```

**Accessibility checklist:**
- [ ] All images have descriptive alt text
- [ ] Color is not the only indicator of state (use icons/text too)
- [ ] Form inputs have associated labels
- [ ] Error messages are linked to form fields (aria-describedby)
- [ ] Dynamic content updates are announced (aria-live)
- [ ] Keyboard navigation works (Tab, Shift+Tab, Enter, Space, Escape)
- [ ] Focus is visible and has 3:1 contrast ratio
- [ ] Page tested with screen reader (NVDA on Windows or VoiceOver on Mac)
- [ ] Axe DevTools or Lighthouse shows no critical issues
- [ ] Heading hierarchy is correct (no skipped levels)

### 4. State Management

**Mandate:** Manage application state in a predictable, scalable way.

- Choose state management approach based on complexity: local state → Context API → Redux/MobX/Zustand
- Keep state as close to usage as possible (colocation)
- Use immutable patterns; never mutate state directly
- Normalize state shape to avoid duplication
- Implement proper selector memoization to avoid unnecessary re-renders
- Handle async operations (loading, error, success states)
- Persist state to localStorage when appropriate
- Test state reducers and selectors

**State architecture pattern:**

```tsx
// State definition with proper typing
interface User {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'user';
}

interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
}

interface AppState {
  auth: AuthState;
  ui: {
    isDarkMode: boolean;
    sidebarOpen: boolean;
  };
}

// Redux-style reducer
type AuthAction =
  | { type: 'AUTH_START' }
  | { type: 'AUTH_SUCCESS'; payload: User }
  | { type: 'AUTH_FAILURE'; payload: string }
  | { type: 'AUTH_LOGOUT' };

const initialAuthState: AuthState = {
  user: null,
  isAuthenticated: false,
  isLoading: false,
  error: null,
};

function authReducer(state = initialAuthState, action: AuthAction): AuthState {
  switch (action.type) {
    case 'AUTH_START':
      return { ...state, isLoading: true, error: null };
    case 'AUTH_SUCCESS':
      return {
        ...state,
        user: action.payload,
        isAuthenticated: true,
        isLoading: false,
      };
    case 'AUTH_FAILURE':
      return { ...state, error: action.payload, isLoading: false };
    case 'AUTH_LOGOUT':
      return initialAuthState;
    default:
      return state;
  }
}

// Selectors with memoization
const selectUser = (state: AppState) => state.auth.user;
const selectIsAuthenticated = (state: AppState) => state.auth.isAuthenticated;
const selectAuthError = (state: AppState) => state.auth.error;

// Usage with hooks (assuming Redux)
const useAuth = () => {
  const user = useSelector(selectUser);
  const isAuthenticated = useSelector(selectIsAuthenticated);
  const error = useSelector(selectAuthError);
  const dispatch = useDispatch();

  const login = useCallback((email: string, password: string) => {
    dispatch({ type: 'AUTH_START' });
    // API call...
  }, [dispatch]);

  return { user, isAuthenticated, error, login };
};
```

