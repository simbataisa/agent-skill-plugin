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

---

## Troubleshooting

### One-shot shortcut — `scripts/check-playwright-env.sh`

**Before walking the manual ladder below, run the packaged diagnostic.** Available from two locations — use whichever exists on the machine:

```bash
# From a BMAD repo clone:
bash scripts/check-playwright-env.sh                # human-readable, coloured
bash scripts/check-playwright-env.sh --json         # machine-readable (for CI gates)
bash scripts/check-playwright-env.sh --port 3100    # override auto-detected port

# From any project after install-global.sh (script deployed to ~/.bmad/scripts/):
bash "$HOME/.bmad/scripts/check-playwright-env.sh" --project-root "$(pwd)"
bash "$HOME/.bmad/scripts/check-playwright-env.sh" --project-root "$(pwd)" --json
```

What it does in one pass:

1. Locates `playwright.config.{ts,js,mjs,cjs}` and auto-detects the port from `url:` or `port:`.
2. Runs a Node `bind()` test on `127.0.0.1:<port>` (Step 1 below, inline — no Playwright needed).
3. If loopback fails, retries on `0.0.0.0:<port>` to distinguish between loopback-only blocks and full sandbox blocks.
4. Parses `EPERM` / `EACCES` specifically to separate policy denial from other failures.
5. Emits one of five verdicts with the exact next action:

| Verdict | Exit | Meaning |
|---|---|---|
| `READY`  | 0 | Environment can bind; run `npx playwright test` as configured. |
| `FIX_A`  | 1 | Port-specific block — use a different port, update `playwright.config`. See **Fix A** below. |
| `FIX_B`  | 2 | Sandbox blocks all local listens (EPERM on loopback **and** 0.0.0.0) — drop `webServer`, run against a deployed URL. See **Fix B** — default for MCP-hosted sandboxes. |
| `FIX_C`  | 3 | `127.0.0.1` blocked but `0.0.0.0` works — start the app with `HOST=0.0.0.0`, keep Playwright pointed at `http://127.0.0.1:<port>`. See **Fix C**. |
| `NO_NODE`| 4 | Node not on PATH — escalate as environment setup. |

Run the script once, act on the verdict, then consult the section below for the full config snippet. The rest of this troubleshooting section is the underlying manual ladder the script automates — retained for debugging, CI gate authoring, and any case where you need to reason about a non-standard failure.

### `listen EPERM 127.0.0.1:3000` (or similar port) when running `playwright test`

**What the error actually means.** `EPERM` is POSIX *operation not permitted* — the OS or runtime blocked the `bind()/listen()` call. It is **not** "port in use" (that would be `EADDRINUSE`). The Node process is not allowed to open a local listening socket at all.

**Where it surfaces.** Almost always during `webServer.command` startup in `playwright.config.ts`: Playwright spawns your app (e.g. `npm run start` on `localhost:3000`) and waits for the URL; the bind fails, so Playwright never reaches the tests.

**Most common causes, in order.**

1. **Environment forbids opening local listening ports.** Common in MCP-hosted sandboxes, hardened containers, remote runners, and some corporate endpoints. No app configuration change will work — the kernel/policy won't allow the bind.
2. **App startup itself is failing** (independent of Playwright). `webServer` faithfully runs your command; if the command can't bind, the whole run fails even though Playwright itself is fine.
3. **Endpoint security or container policy** blocking loopback binds on specific ports (often 80, 443, <1024, or product-specific ones).

**Diagnostic ladder — run these in order.**

**Step 1 — is this an environment bind-block, or something else?** Run outside Playwright entirely:

```bash
node -e "require('http').createServer((_,r)=>r.end('ok')).listen(3000,'127.0.0.1',()=>console.log('listening'))"
```

- Fails with `EPERM` → the runtime/OS/container forbids the bind. Playwright cannot fix this. Jump to Fix B.
- Listens successfully → the problem is inside your app or config. Go to Step 2.

**Step 2 — enable Playwright's webServer debug logs.** Exposes whether the failure is at `webServer.command` or later.

```bash
DEBUG=pw:webserver npx playwright test
```

**Step 3 — try a different port.** If an environment or tool is blocking port 3000 specifically:

```bash
PORT=3100 npm run start   # run standalone to confirm it binds
```

Then update `playwright.config.ts` to use 3100 (see Fix A below).

**Fixes, by cause.**

**Fix A — app can bind locally, just needed a different port.** Move the app (and Playwright) off the blocked port:

```ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  use: { baseURL: 'http://127.0.0.1:3100' },
  webServer: {
    command: 'PORT=3100 npm run start',
    url: 'http://127.0.0.1:3100',
    reuseExistingServer: true,
    timeout: 120_000,
    stdout: 'pipe',
    stderr: 'pipe',
  },
});
```

**Fix B — environment forbids listening sockets (MCP sandbox / restricted container).** Do NOT have Playwright start a local server at all. Point tests at an already-running deployment (staging, preview URL, ngrok tunnel into a dev host):

```ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  use: { baseURL: process.env.BASE_URL ?? 'https://staging.example.com' },
  // no webServer block — deliberately omitted
});
```

Then run with `BASE_URL=https://...  npx playwright test`. This is the **default recommended mode for BMAD's MCP-hosted tester-qe** — E2E in sandbox environments should always target a deployed URL, not a local dev server.

**Fix C — framework binds strictly to `127.0.0.1` and the sandbox only permits `0.0.0.0`.** Force the bind host:

```bash
HOST=0.0.0.0 PORT=3100 npm run start
```

Then keep Playwright's `url` as `http://127.0.0.1:3100` (most sandboxes route loopback to `0.0.0.0` listeners).

**Minimal working config that works in most sandboxes** (combines A + C with a remote fallback):

```ts
import { defineConfig } from '@playwright/test';

const remote = process.env.BASE_URL;

export default defineConfig({
  use: { baseURL: remote ?? 'http://127.0.0.1:3100' },
  webServer: remote ? undefined : {
    command: 'HOST=0.0.0.0 PORT=3100 npm run start',
    url: 'http://127.0.0.1:3100',
    reuseExistingServer: true,
    timeout: 120_000,
    stdout: 'pipe',
    stderr: 'pipe',
  },
});
```

**What tester-qe must NOT do when it sees `EPERM`.**

- Do not retry the same command in a loop — `EPERM` is a policy/permission denial, not a transient error.
- Do not rewrite Playwright internals, reinstall the browser, or bump versions — none of those touch `bind()`.
- Do not assume the port is "in use" and try to kill processes — that's the `EADDRINUSE` playbook and is irrelevant here.

**Escalation checklist.** If Fix A/B/C all fail, capture and report:

1. Output of the Step 1 Node bind test.
2. `DEBUG=pw:webserver` output up to the failure line.
3. Contents of `playwright.config.*` and the `start` script from `package.json`.
4. Environment signals: Docker/devcontainer? MCP sandbox? CI runner brand? OS + Node version (`node -v && uname -a`).

File this as a DevSecOps / infrastructure ticket, not a Playwright bug — the resolution is almost always environmental.
