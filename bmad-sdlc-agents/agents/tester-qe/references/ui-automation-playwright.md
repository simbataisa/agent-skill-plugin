# UI Automation with Playwright MCP

> Load this reference when `mcp__playwright__*` tools are available in your session, or when writing Playwright test code for the project's test suite. Covers live browser automation via MCP and authored `.spec.ts` test file patterns.

---

## Two Modes of Playwright Usage

| Mode | When to use | How |
|---|---|---|
| **MCP Live Automation** | Exploratory testing, verifying a bug, taking screenshots of failures, running quick checks | `mcp__playwright__*` tools directly in the session |
| **Authored Test Files** | Sprint deliverables — E2E test suite committed to the repo | Write `.spec.ts` files using Playwright Test framework |

Always use MCP live automation first to explore and validate, then codify the working flow into a `.spec.ts` file.

---

## MCP Tool Reference (Playwright MCP — Microsoft Official)

### Navigation

| Tool | Purpose |
|---|---|
| `mcp__playwright__browser_navigate` | Navigate to a URL |
| `mcp__playwright__browser_navigate_back` | Go back in browser history |
| `mcp__playwright__browser_navigate_forward` | Go forward in browser history |

### Reading Page State

| Tool | Purpose |
|---|---|
| `mcp__playwright__browser_snapshot` | Get accessibility tree snapshot — the primary way to read page structure |
| `mcp__playwright__browser_take_screenshot` | Capture a screenshot (use after actions to verify state) |
| `mcp__playwright__browser_get_console_messages` | Read browser console — check for JS errors |
| `mcp__playwright__browser_network_requests` | Inspect network requests made by the page |

### Interacting with the Page

| Tool | Purpose |
|---|---|
| `mcp__playwright__browser_click` | Click an element (by role/label/text from the snapshot) |
| `mcp__playwright__browser_type` | Type into an input field |
| `mcp__playwright__browser_fill` | Fill a form field (clears existing value first) |
| `mcp__playwright__browser_select_option` | Select a dropdown option |
| `mcp__playwright__browser_check` | Check a checkbox |
| `mcp__playwright__browser_uncheck` | Uncheck a checkbox |
| `mcp__playwright__browser_hover` | Hover over an element |
| `mcp__playwright__browser_press_key` | Press a keyboard key |
| `mcp__playwright__browser_drag` | Drag an element to a target |

### Waiting & Timing

| Tool | Purpose |
|---|---|
| `mcp__playwright__browser_wait_for` | Wait for a text, element, or URL condition |

### Tab & Session Management

| Tool | Purpose |
|---|---|
| `mcp__playwright__browser_tab_new` | Open a new browser tab |
| `mcp__playwright__browser_tab_list` | List all open tabs |
| `mcp__playwright__browser_tab_select` | Switch to a specific tab |
| `mcp__playwright__browser_tab_close` | Close a tab |
| `mcp__playwright__browser_close` | Close the browser |

### File Handling

| Tool | Purpose |
|---|---|
| `mcp__playwright__browser_file_upload` | Upload a file to a file input |
| `mcp__playwright__browser_pdf_save` | Save the current page as PDF |

### JavaScript Execution

| Tool | Purpose |
|---|---|
| `mcp__playwright__browser_evaluate` | Run JavaScript in the browser context |

---

## Live Automation Workflow (MCP)

### Smoke Test a New Feature

```
1. mcp__playwright__browser_navigate     → open the app (staging URL)
2. mcp__playwright__browser_snapshot     → inspect the page structure
3. mcp__playwright__browser_click        → interact with the feature
4. mcp__playwright__browser_take_screenshot → capture state after action
5. mcp__playwright__browser_snapshot     → verify expected UI state
6. mcp__playwright__browser_get_console_messages → check for JS errors
```

### Reproduce a Bug

```
1. mcp__playwright__browser_navigate     → go to the affected page
2. mcp__playwright__browser_snapshot     → baseline state
3. [perform the steps that reproduce the bug]
4. mcp__playwright__browser_take_screenshot → capture the broken state
5. Save screenshot to docs/testing/defects/<ticket-id>-screenshot.png
6. Document in defect report using templates/defect-report.md
```

### Accessibility Audit

```
1. mcp__playwright__browser_navigate     → load the screen under test
2. mcp__playwright__browser_snapshot     → accessibility tree = full ARIA structure
3. Check: roles, labels, headings hierarchy, focus order, alt text
4. mcp__playwright__browser_press_key    → Tab through the UI to verify focus order
5. Document findings in docs/ux/accessibility-audit.md
```

---

## Authored Test Files (Playwright Test Framework)

### File Location

```
tests/
├── e2e/
│   ├── auth/
│   │   └── login.spec.ts
│   ├── [feature]/
│   │   └── [scenario].spec.ts
│   └── smoke.spec.ts
├── fixtures/
│   └── test-data.ts
└── playwright.config.ts
```

### Test File Pattern

```typescript
import { test, expect } from '@playwright/test';

test.describe('User Login', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
  });

  test('should log in with valid credentials', async ({ page }) => {
    // Arrange
    await page.getByLabel('Email').fill('user@example.com');
    await page.getByLabel('Password').fill('password123');

    // Act
    await page.getByRole('button', { name: 'Sign in' }).click();

    // Assert
    await expect(page).toHaveURL('/dashboard');
    await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
  });

  test('should show error with invalid credentials', async ({ page }) => {
    await page.getByLabel('Email').fill('wrong@example.com');
    await page.getByLabel('Password').fill('wrongpassword');
    await page.getByRole('button', { name: 'Sign in' }).click();

    await expect(page.getByRole('alert')).toContainText('Invalid credentials');
  });
});
```

### Selector Priority (most to least preferred)

1. `getByRole('button', { name: 'Submit' })` — semantic, accessible
2. `getByLabel('Email address')` — form labels
3. `getByText('Sign in')` — visible text
4. `getByTestId('submit-btn')` — `data-testid` attribute (add to component when needed)
5. `locator('.css-class')` — last resort, brittle

Never use XPath or positional selectors like `nth-child` in committed tests.

### Page Object Model (for complex flows)

```typescript
// tests/pages/LoginPage.ts
export class LoginPage {
  constructor(private page: Page) {}

  async goto() { await this.page.goto('/login'); }
  async fillEmail(email: string) { await this.page.getByLabel('Email').fill(email); }
  async fillPassword(pw: string) { await this.page.getByLabel('Password').fill(pw); }
  async submit() { await this.page.getByRole('button', { name: 'Sign in' }).click(); }

  async loginAs(email: string, password: string) {
    await this.fillEmail(email);
    await this.fillPassword(password);
    await this.submit();
  }
}
```

### playwright.config.ts (baseline)

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  reporter: [['html', { open: 'never' }], ['github']],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'Mobile Safari', use: { ...devices['iPhone 14'] } },
  ],
});
```

---

## CI Integration

Add to your CI pipeline (GitHub Actions example):

```yaml
- name: Install Playwright browsers
  run: npx playwright install --with-deps chromium

- name: Run E2E tests
  run: npx playwright test
  env:
    BASE_URL: ${{ env.STAGING_URL }}

- name: Upload test report
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: playwright-report
    path: playwright-report/
```

---

## Quality Gate Criteria

E2E tests must pass before `E2-tqe-done` is written:

- [ ] All `tests/e2e/smoke.spec.ts` tests pass against staging
- [ ] All story-specific E2E tests pass (one spec file per story)
- [ ] No skipped tests without a documented reason
- [ ] Screenshot/video artifacts uploaded for any retried tests
- [ ] Console errors reviewed — no uncaught exceptions from app code
- [ ] Accessibility snapshot checked for WCAG 2.2 AA violations on each new screen
