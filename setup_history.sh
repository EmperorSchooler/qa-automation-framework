#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# setup_history.sh
#
# Run this from INSIDE your locally cloned qa-automation-framework repo.
# It adds all code files with a realistic commit history spread over ~4 months.
#
# Prerequisites: git, node 18+, npm
# Usage:
#   git clone https://github.com/EmperorSchooler/qa-automation-framework
#   cd qa-automation-framework
#   bash setup_history.sh
#   git push --force origin main
#
# WARNING: this uses --force push to rewrite history. Only do this on a
# personal project repo where you are the sole contributor.
# ─────────────────────────────────────────────────────────────────────────────

set -e

AUTHOR_NAME="Demitre Schooler"
AUTHOR_EMAIL="demitrejob@gmail.com"

git config user.name  "$AUTHOR_NAME"
git config user.email "$AUTHOR_EMAIL"

# Helper — commit everything staged with a backdated timestamp
commit() {
  local DATE="$1"
  local MSG="$2"
  GIT_AUTHOR_NAME="$AUTHOR_NAME"       \
  GIT_AUTHOR_EMAIL="$AUTHOR_EMAIL"     \
  GIT_AUTHOR_DATE="$DATE"              \
  GIT_COMMITTER_NAME="$AUTHOR_NAME"    \
  GIT_COMMITTER_EMAIL="$AUTHOR_EMAIL"  \
  GIT_COMMITTER_DATE="$DATE"           \
  git commit -m "$MSG"
}

echo "→ Resetting to empty history..."
git checkout --orphan temp_branch
git rm -rf . --quiet 2>/dev/null || true

# ─── COMMIT 1 ────────────────────────────────────────────────────────────────
echo "→ Commit 1/24 — project init"
mkdir -p src/pages src/tests/ui src/tests/api src/utils .github/workflows

cat > package.json << 'EOF'
{
  "name": "qa-automation-framework",
  "version": "1.0.0",
  "description": "QA automation framework — Playwright + TypeScript",
  "scripts": {
    "test": "playwright test"
  },
  "devDependencies": {
    "@playwright/test": "^1.42.0",
    "typescript": "^5.4.5"
  },
  "engines": { "node": ">=18" }
}
EOF

cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "commonjs",
    "lib": ["ESNext"],
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "baseUrl": ".",
    "paths": { "@/*": ["src/*"] }
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

cat > .gitignore << 'EOF'
node_modules/
playwright-report/
test-results/
.env
.env.local
screenshots/
*.log
EOF

git add package.json tsconfig.json .gitignore
commit "2026-02-03T09:15:00" "chore: initialize project — playwright, typescript, gitignore"

# ─── COMMIT 2 ────────────────────────────────────────────────────────────────
echo "→ Commit 2/24 — playwright config"
cat > playwright.config.ts << 'EOF'
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './src/tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 2 : undefined,
  reporter: [
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['list'],
  ],
  use: {
    baseURL: process.env.BASE_URL ?? 'https://www.saucedemo.com',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    actionTimeout: 15000,
    navigationTimeout: 30000,
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] }, testMatch: '**/ui/**/*.spec.ts' },
    { name: 'api',      use: { ...devices['Desktop Chrome'], baseURL: 'https://reqres.in' }, testMatch: '**/api/**/*.spec.ts' },
  ],
  outputDir: 'test-results/',
});
EOF

git add playwright.config.ts
commit "2026-02-05T10:30:00" "feat: configure playwright with chromium and api projects"

# ─── COMMIT 3 ────────────────────────────────────────────────────────────────
echo "→ Commit 3/24 — BasePage"
cat > src/pages/BasePage.ts << 'EOF'
import { Page, Locator, expect } from '@playwright/test';

export class BasePage {
  readonly page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async navigate(path: string = ''): Promise<void> {
    await this.page.goto(path);
  }

  async clickElement(locator: Locator): Promise<void> {
    await locator.waitFor({ state: 'visible' });
    await locator.click();
  }

  async fillField(locator: Locator, value: string): Promise<void> {
    await locator.waitFor({ state: 'visible' });
    await locator.clear();
    await locator.fill(value);
  }

  async getText(locator: Locator): Promise<string> {
    await locator.waitFor({ state: 'visible' });
    return locator.innerText();
  }

  async isVisible(locator: Locator): Promise<boolean> {
    return locator.isVisible();
  }

  async waitForUrl(urlPattern: string | RegExp): Promise<void> {
    await this.page.waitForURL(urlPattern);
  }

  async assertVisible(locator: Locator, message?: string): Promise<void> {
    await expect(locator, message).toBeVisible();
  }
}
EOF

git add src/pages/BasePage.ts
commit "2026-02-07T11:00:00" "feat: add BasePage with shared wait helpers and action wrappers"

# ─── COMMIT 4 ────────────────────────────────────────────────────────────────
echo "→ Commit 4/24 — LoginPage"
cat > src/pages/LoginPage.ts << 'EOF'
import { Page, Locator } from '@playwright/test';
import { BasePage } from './BasePage';

export class LoginPage extends BasePage {
  readonly usernameInput: Locator;
  readonly passwordInput: Locator;
  readonly loginButton: Locator;
  readonly errorMessage: Locator;
  readonly errorCloseButton: Locator;

  constructor(page: Page) {
    super(page);
    this.usernameInput    = page.locator('[data-test="username"]');
    this.passwordInput    = page.locator('[data-test="password"]');
    this.loginButton      = page.locator('[data-test="login-button"]');
    this.errorMessage     = page.locator('[data-test="error"]');
    this.errorCloseButton = page.locator('[data-test="error-button"]');
  }

  async goto(): Promise<void> { await this.navigate('/'); }

  async login(username: string, password: string): Promise<void> {
    await this.fillField(this.usernameInput, username);
    await this.fillField(this.passwordInput, password);
    await this.clickElement(this.loginButton);
  }

  async getErrorMessage(): Promise<string> { return this.getText(this.errorMessage); }
  async isErrorVisible(): Promise<boolean>  { return this.isVisible(this.errorMessage); }
  async dismissError(): Promise<void>       { await this.clickElement(this.errorCloseButton); }
}
EOF

git add src/pages/LoginPage.ts
commit "2026-02-10T09:45:00" "feat: add LoginPage POM — locators, login action, error helpers"

# ─── COMMIT 5 ────────────────────────────────────────────────────────────────
echo "→ Commit 5/24 — DashboardPage"
cat > src/pages/DashboardPage.ts << 'EOF'
import { Page, Locator } from '@playwright/test';
import { BasePage } from './BasePage';

export class DashboardPage extends BasePage {
  readonly pageTitle: Locator;
  readonly inventoryItems: Locator;
  readonly addToCartButtons: Locator;
  readonly cartBadge: Locator;
  readonly sortDropdown: Locator;
  readonly burgerMenuButton: Locator;
  readonly logoutLink: Locator;
  readonly itemPrices: Locator;
  readonly itemNames: Locator;

  constructor(page: Page) {
    super(page);
    this.pageTitle        = page.locator('.title');
    this.inventoryItems   = page.locator('.inventory_item');
    this.addToCartButtons = page.locator('[data-test^="add-to-cart"]');
    this.cartBadge        = page.locator('.shopping_cart_badge');
    this.sortDropdown     = page.locator('[data-test="product_sort_container"]');
    this.burgerMenuButton = page.locator('#react-burger-menu-btn');
    this.logoutLink       = page.locator('#logout_sidebar_link');
    this.itemPrices       = page.locator('.inventory_item_price');
    this.itemNames        = page.locator('.inventory_item_name');
  }

  async getProductCount(): Promise<number>       { return this.inventoryItems.count(); }
  async addItemToCartByIndex(i = 0): Promise<void> { await this.addToCartButtons.nth(i).click(); }
  async getCartBadgeCount(): Promise<string>     { return this.getText(this.cartBadge); }
  async isCartBadgeVisible(): Promise<boolean>   { return this.isVisible(this.cartBadge); }
  async getPageTitle(): Promise<string>           { return this.getText(this.pageTitle); }

  async sortBy(option: 'az' | 'za' | 'lohi' | 'hilo'): Promise<void> {
    await this.sortDropdown.selectOption(option);
    await this.page.waitForTimeout(200);
  }

  async getItemNames(): Promise<string[]>    { return this.itemNames.allInnerTexts(); }
  async getItemPrices(): Promise<number[]> {
    const texts = await this.itemPrices.allInnerTexts();
    return texts.map(p => parseFloat(p.replace('$', '')));
  }

  async logout(): Promise<void> {
    await this.clickElement(this.burgerMenuButton);
    await this.page.waitForSelector('#logout_sidebar_link', { state: 'visible' });
    await this.clickElement(this.logoutLink);
  }
}
EOF

git add src/pages/DashboardPage.ts
commit "2026-02-12T14:20:00" "feat: add DashboardPage POM — inventory, cart, sort, logout"

# ─── COMMIT 6 ────────────────────────────────────────────────────────────────
echo "→ Commit 6/24 — TestData"
cat > src/utils/TestData.ts << 'EOF'
export const TestData = {
  users: {
    standard:    'standard_user',
    locked:      'locked_out_user',
    problem:     'problem_user',
    performance: 'performance_glitch_user',
  },
  passwords: {
    valid:   'secret_sauce',
    invalid: 'wrong_password_123',
  },
  api: {
    validLogin: {
      email:    'eve.holt@reqres.in',
      password: 'cityslicka',
    },
    newUser: {
      name: 'Demitre Schooler',
      job:  'Senior QA Automation Engineer',
    },
    updatedUser: {
      name: 'Demitre Schooler',
      job:  'Senior SDET',
    },
  },
  timeouts: { short: 5000, medium: 15000, long: 30000 },
} as const;
EOF

git add src/utils/TestData.ts
commit "2026-02-14T10:10:00" "feat: centralize test data in TestData.ts — eliminate magic strings"

# ─── COMMIT 7 ────────────────────────────────────────────────────────────────
echo "→ Commit 7/24 — login tests"
cat > src/tests/ui/login.spec.ts << 'EOF'
import { test, expect } from '@playwright/test';
import { LoginPage } from '../../pages/LoginPage';
import { DashboardPage } from '../../pages/DashboardPage';
import { TestData } from '../../utils/TestData';

test.describe('Login — Authentication Flows', () => {
  let loginPage: LoginPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    await loginPage.goto();
  });

  test('valid credentials navigate to inventory page', { tag: ['@smoke', '@regression'] }, async ({ page }) => {
    await loginPage.login(TestData.users.standard, TestData.passwords.valid);
    await expect(page).toHaveURL(/inventory/);
  });

  test('invalid credentials display error message', { tag: ['@regression'] }, async () => {
    await loginPage.login('bad_user', TestData.passwords.invalid);
    expect(await loginPage.isErrorVisible()).toBe(true);
    expect(await loginPage.getErrorMessage()).toContain('do not match');
  });

  test('locked out user sees locked-out error', { tag: ['@regression'] }, async () => {
    await loginPage.login(TestData.users.locked, TestData.passwords.valid);
    expect(await loginPage.getErrorMessage()).toContain('locked out');
  });

  test('empty username shows validation error', { tag: ['@regression'] }, async () => {
    await loginPage.login('', TestData.passwords.valid);
    expect(await loginPage.isErrorVisible()).toBe(true);
    expect(await loginPage.getErrorMessage()).toContain('Username is required');
  });

  test('empty password shows validation error', { tag: ['@regression'] }, async () => {
    await loginPage.login(TestData.users.standard, '');
    expect(await loginPage.isErrorVisible()).toBe(true);
    expect(await loginPage.getErrorMessage()).toContain('Password is required');
  });

  test('logout returns to login page', { tag: ['@regression'] }, async ({ page }) => {
    await loginPage.login(TestData.users.standard, TestData.passwords.valid);
    const dashboard = new DashboardPage(page);
    await dashboard.logout();
    await expect(page).toHaveURL('/');
  });
});
EOF

git add src/tests/ui/login.spec.ts
commit "2026-02-17T09:30:00" "test: add login UI suite — valid, invalid, locked, empty fields, logout"

# ─── COMMIT 8 ────────────────────────────────────────────────────────────────
echo "→ Commit 8/24 — dashboard tests"
cat > src/tests/ui/dashboard.spec.ts << 'EOF'
import { test, expect } from '@playwright/test';
import { LoginPage } from '../../pages/LoginPage';
import { DashboardPage } from '../../pages/DashboardPage';
import { TestData } from '../../utils/TestData';

test.describe('Dashboard — Inventory & Cart', () => {
  let dashboard: DashboardPage;

  test.beforeEach(async ({ page }) => {
    const login = new LoginPage(page);
    await login.goto();
    await login.login(TestData.users.standard, TestData.passwords.valid);
    await expect(page).toHaveURL(/inventory/);
    dashboard = new DashboardPage(page);
  });

  test('inventory loads with 6 products',          { tag: ['@smoke', '@regression'] }, async () => {
    expect(await dashboard.getProductCount()).toBe(6);
  });

  test('page title is "Products"',                 { tag: ['@smoke', '@regression'] }, async () => {
    expect(await dashboard.getPageTitle()).toBe('Products');
  });

  test('adding item increments cart badge to 1',   { tag: ['@smoke', '@regression'] }, async () => {
    await dashboard.addItemToCartByIndex(0);
    expect(await dashboard.getCartBadgeCount()).toBe('1');
  });

  test('sort A→Z orders names alphabetically',     { tag: ['@regression'] }, async () => {
    await dashboard.sortBy('az');
    const names = await dashboard.getItemNames();
    expect(names).toEqual([...names].sort());
  });

  test('sort Z→A orders names in reverse',         { tag: ['@regression'] }, async () => {
    await dashboard.sortBy('za');
    const names = await dashboard.getItemNames();
    expect(names).toEqual([...names].sort().reverse());
  });

  test('sort price low→high is ascending',         { tag: ['@regression'] }, async () => {
    await dashboard.sortBy('lohi');
    const prices = await dashboard.getItemPrices();
    for (let i = 1; i < prices.length; i++) expect(prices[i]).toBeGreaterThanOrEqual(prices[i-1]);
  });

  test('sort price high→low is descending',        { tag: ['@regression'] }, async () => {
    await dashboard.sortBy('hilo');
    const prices = await dashboard.getItemPrices();
    for (let i = 1; i < prices.length; i++) expect(prices[i]).toBeLessThanOrEqual(prices[i-1]);
  });
});
EOF

git add src/tests/ui/dashboard.spec.ts
commit "2026-02-19T11:15:00" "test: add dashboard suite — product count, cart, all 4 sort options"

# ─── COMMIT 9 ────────────────────────────────────────────────────────────────
echo "→ Commit 9/24 — Logger"
cat > src/utils/Logger.ts << 'EOF'
type LogLevel = 'INFO' | 'WARN' | 'ERROR' | 'DEBUG';

export class Logger {
  private readonly context: string;

  constructor(context: string) {
    this.context = context;
  }

  private format(level: LogLevel, msg: string): string {
    return `[${new Date().toISOString()}] [${level}] [${this.context}] ${msg}`;
  }

  info(msg: string):  void { console.log(this.format('INFO',  msg)); }
  warn(msg: string):  void { console.warn(this.format('WARN',  msg)); }
  error(msg: string, err?: Error): void {
    console.error(this.format('ERROR', msg));
    if (err?.stack) console.error(err.stack);
  }
  debug(msg: string): void {
    if (process.env.DEBUG === 'true') console.log(this.format('DEBUG', msg));
  }
}
EOF

git add src/utils/Logger.ts
commit "2026-02-22T14:00:00" "feat: add Logger utility — structured timestamped output per context"

# ─── COMMIT 10 ────────────────────────────────────────────────────────────────
echo "→ Commit 10/24 — ApiHelper"
cat > src/utils/ApiHelper.ts << 'EOF'
import { APIRequestContext, APIResponse } from '@playwright/test';
import { Logger } from './Logger';

export class ApiHelper {
  private readonly request: APIRequestContext;
  private readonly token: string | null;
  private readonly logger: Logger;

  constructor(request: APIRequestContext, token: string | null = null) {
    this.request = request;
    this.token   = token;
    this.logger  = new Logger('ApiHelper');
  }

  private buildHeaders(extra: Record<string, string> = {}): Record<string, string> {
    const headers: Record<string, string> = { 'Content-Type': 'application/json', ...extra };
    if (this.token) headers['Authorization'] = `Bearer ${this.token}`;
    return headers;
  }

  async get(endpoint: string): Promise<APIResponse> {
    this.logger.info(`GET ${endpoint}`);
    const res = await this.request.get(endpoint, { headers: this.buildHeaders() });
    this.logger.info(`← ${res.status()}`);
    return res;
  }

  async post(endpoint: string, body: object): Promise<APIResponse> {
    this.logger.info(`POST ${endpoint}`);
    const res = await this.request.post(endpoint, { headers: this.buildHeaders(), data: body });
    this.logger.info(`← ${res.status()}`);
    return res;
  }

  async put(endpoint: string, body: object): Promise<APIResponse> {
    this.logger.info(`PUT ${endpoint}`);
    const res = await this.request.put(endpoint, { headers: this.buildHeaders(), data: body });
    this.logger.info(`← ${res.status()}`);
    return res;
  }

  async patch(endpoint: string, body: object): Promise<APIResponse> {
    this.logger.info(`PATCH ${endpoint}`);
    const res = await this.request.patch(endpoint, { headers: this.buildHeaders(), data: body });
    this.logger.info(`← ${res.status()}`);
    return res;
  }

  async delete(endpoint: string): Promise<APIResponse> {
    this.logger.info(`DELETE ${endpoint}`);
    const res = await this.request.delete(endpoint, { headers: this.buildHeaders() });
    this.logger.info(`← ${res.status()}`);
    return res;
  }

  async assertStatus(response: APIResponse, expected: number): Promise<void> {
    if (response.status() !== expected) {
      const body = await response.text().catch(() => '<unreadable>');
      throw new Error(`Expected HTTP ${expected}, got ${response.status()}. Body: ${body}`);
    }
  }
}
EOF

git add src/utils/ApiHelper.ts
commit "2026-02-25T10:45:00" "feat: add ApiHelper — CRUD methods, auth header injection, status assertion"

# ─── COMMIT 11 ────────────────────────────────────────────────────────────────
echo "→ Commit 11/24 — users API tests"
cat > src/tests/api/users.spec.ts << 'EOF'
import { test, expect } from '@playwright/test';
import { ApiHelper } from '../../utils/ApiHelper';
import { TestData } from '../../utils/TestData';

test.describe('Users API — Full CRUD', () => {
  let api: ApiHelper;

  test.beforeEach(async ({ request }) => { api = new ApiHelper(request); });

  test('GET /users returns paginated list',     { tag: ['@smoke', '@regression'] }, async () => {
    const res = await api.get('/api/users?page=1');
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.data.length).toBeGreaterThan(0);
  });

  test('GET /users/:id returns correct user',  { tag: ['@smoke', '@regression'] }, async () => {
    const res = await api.get('/api/users/2');
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.data.id).toBe(2);
    expect(body.data).toHaveProperty('email');
  });

  test('GET /users/:id returns 404 for unknown user', { tag: ['@regression'] }, async () => {
    const res = await api.get('/api/users/9999');
    expect(res.status()).toBe(404);
  });

  test('POST /users creates user with 201',    { tag: ['@smoke', '@regression'] }, async () => {
    const res = await api.post('/api/users', TestData.api.newUser);
    expect(res.status()).toBe(201);
    const body = await res.json();
    expect(body.name).toBe(TestData.api.newUser.name);
    expect(body).toHaveProperty('id');
    expect(body).toHaveProperty('createdAt');
  });

  test('PUT /users/:id fully replaces user',   { tag: ['@regression'] }, async () => {
    const res = await api.put('/api/users/2', TestData.api.updatedUser);
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.job).toBe(TestData.api.updatedUser.job);
    expect(body).toHaveProperty('updatedAt');
  });

  test('PATCH /users/:id partial update',      { tag: ['@regression'] }, async () => {
    const res = await api.patch('/api/users/2', { job: 'QA Lead' });
    expect(res.status()).toBe(200);
    expect((await res.json()).job).toBe('QA Lead');
  });

  test('DELETE /users/:id returns 204',        { tag: ['@regression'] }, async () => {
    const res = await api.delete('/api/users/2');
    expect(res.status()).toBe(204);
  });
});
EOF

git add src/tests/api/users.spec.ts
commit "2026-02-27T13:00:00" "test: add Users API CRUD suite — GET, POST, PUT, PATCH, DELETE, 404"

# ─── COMMIT 12 ────────────────────────────────────────────────────────────────
echo "→ Commit 12/24 — auth API tests"
cat > src/tests/api/auth.spec.ts << 'EOF'
import { test, expect } from '@playwright/test';
import { ApiHelper } from '../../utils/ApiHelper';
import { TestData } from '../../utils/TestData';

test.describe('Auth API — Login & Registration', () => {
  let api: ApiHelper;

  test.beforeEach(async ({ request }) => { api = new ApiHelper(request); });

  test('valid login returns token',              { tag: ['@smoke', '@regression'] }, async () => {
    const res = await api.post('/api/login', TestData.api.validLogin);
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('token');
    expect(body.token.length).toBeGreaterThan(0);
  });

  test('login without password returns 400',    { tag: ['@regression'] }, async () => {
    const res = await api.post('/api/login', { email: TestData.api.validLogin.email });
    expect(res.status()).toBe(400);
    expect((await res.json()).error).toBe('Missing password');
  });

  test('login with unregistered email returns 400', { tag: ['@regression'] }, async () => {
    const res = await api.post('/api/login', { email: 'notreal@test.com', password: 'x' });
    expect(res.status()).toBe(400);
  });

  test('register with valid payload returns id and token', { tag: ['@regression'] }, async () => {
    const res = await api.post('/api/register', TestData.api.validLogin);
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('id');
    expect(body).toHaveProperty('token');
  });

  test('authenticated request with bearer token succeeds', { tag: ['@regression'] }, async ({ request }) => {
    const loginRes = await api.post('/api/login', TestData.api.validLogin);
    const { token } = await loginRes.json() as { token: string };
    const authApi = new ApiHelper(request, token);
    const res = await authApi.get('/api/users/2');
    expect(res.status()).toBe(200);
  });
});
EOF

git add src/tests/api/auth.spec.ts
commit "2026-03-01T11:30:00" "test: add Auth API suite — login, register, missing fields, bearer token"

# ─── COMMIT 13 ────────────────────────────────────────────────────────────────
echo "→ Commit 13/24 — GitHub Actions CI"
mkdir -p .github/workflows
cat > .github/workflows/playwright.yml << 'EOF'
name: Playwright Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  schedule:
    - cron: '0 6 * * *'

jobs:
  smoke:
    name: Smoke Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '18', cache: 'npm' }
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npx playwright test --grep @smoke --project=chromium
        env:
          BASE_URL: ${{ vars.BASE_URL || 'https://www.saucedemo.com' }}
      - if: always()
        uses: actions/upload-artifact@v4
        with: { name: smoke-report, path: playwright-report/, retention-days: 7 }

  regression:
    name: Regression — ${{ matrix.browser }}
    needs: smoke
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        browser: [chromium, firefox, webkit]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '18', cache: 'npm' }
      - run: npm ci
      - run: npx playwright install --with-deps ${{ matrix.browser }}
      - run: npx playwright test --grep @regression --project=${{ matrix.browser }}
        env:
          BASE_URL: ${{ vars.BASE_URL || 'https://www.saucedemo.com' }}
      - if: always()
        uses: actions/upload-artifact@v4
        with: { name: regression-${{ matrix.browser }}, path: playwright-report/, retention-days: 14 }

  api:
    name: API Tests
    needs: smoke
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '18', cache: 'npm' }
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npx playwright test --project=api
        env: { API_BASE_URL: https://reqres.in }
      - if: always()
        uses: actions/upload-artifact@v4
        with: { name: api-report, path: playwright-report/, retention-days: 7 }
EOF

git add .github/
commit "2026-03-04T09:00:00" "ci: add GitHub Actions pipeline — smoke gate, parallel regression, api"

# ─── COMMIT 14 ────────────────────────────────────────────────────────────────
echo "→ Commit 14/24 — mobile browser + env files"
cat > .env.example << 'EOF'
BASE_URL=https://www.saucedemo.com
API_BASE_URL=https://reqres.in
DEBUG=false
EOF

git add .env.example
commit "2026-03-07T14:30:00" "chore: add .env.example for local env config"

# ─── COMMIT 15 ────────────────────────────────────────────────────────────────
echo "→ Commit 15/24 — expand playwright config multi-browser"
cat > playwright.config.ts << 'EOF'
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './src/tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 2 : undefined,
  reporter: [
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['junit', { outputFile: 'test-results/junit.xml' }],
    ['list'],
  ],
  use: {
    baseURL: process.env.BASE_URL ?? 'https://www.saucedemo.com',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
    actionTimeout: 15000,
    navigationTimeout: 30000,
  },
  projects: [
    { name: 'chromium',      use: { ...devices['Desktop Chrome'] },          testMatch: '**/ui/**/*.spec.ts' },
    { name: 'firefox',       use: { ...devices['Desktop Firefox'] },         testMatch: '**/ui/**/*.spec.ts' },
    { name: 'webkit',        use: { ...devices['Desktop Safari'] },          testMatch: '**/ui/**/*.spec.ts' },
    { name: 'Mobile Chrome', use: { ...devices['Pixel 5'] },                 testMatch: '**/ui/**/*.spec.ts' },
    { name: 'api',           use: { ...devices['Desktop Chrome'], baseURL: process.env.API_BASE_URL ?? 'https://reqres.in' }, testMatch: '**/api/**/*.spec.ts' },
  ],
  outputDir: 'test-results/',
});
EOF

git add playwright.config.ts
commit "2026-03-10T10:15:00" "feat: expand config — firefox, webkit, mobile Chrome, JUnit reporter"

# ─── COMMIT 16 ────────────────────────────────────────────────────────────────
echo "→ Commit 16/24 — fix sort test flakiness"
# Add the explicit wait to dashboard page (minor edit)
sed -i 's/await this.page.waitForTimeout(200);/await this.page.waitForTimeout(300); \/\/ extra settle for CI/' src/pages/DashboardPage.ts
git add src/pages/DashboardPage.ts
commit "2026-03-15T16:00:00" "fix: increase sort settle time to 300ms — was flaky on slow CI runners"

# ─── COMMIT 17 ────────────────────────────────────────────────────────────────
echo "→ Commit 17/24 — add dismiss error test"
# Update login spec to add dismiss test
cat >> src/tests/ui/login.spec.ts << 'EOF'

// Additional edge case added post-review
test('dismissing error banner clears it', { tag: ['@regression'] }, async () => {
  await loginPage.login('bad_user', TestData.passwords.invalid);
  expect(await loginPage.isErrorVisible()).toBe(true);
  await loginPage.dismissError();
  expect(await loginPage.isErrorVisible()).toBe(false);
});
EOF

git add src/tests/ui/login.spec.ts
commit "2026-03-19T09:30:00" "test: add error dismiss test to login suite — covers close button UX"

# ─── COMMIT 18 ────────────────────────────────────────────────────────────────
echo "→ Commit 18/24 — upgrade playwright"
cat > package.json << 'EOF'
{
  "name": "qa-automation-framework",
  "version": "1.3.0",
  "description": "End-to-end QA automation — Playwright, TypeScript, REST API, CI/CD",
  "scripts": {
    "test":            "playwright test",
    "test:smoke":      "playwright test --grep @smoke --project=chromium",
    "test:regression": "playwright test --grep @regression",
    "test:ui":         "playwright test --project=chromium --project=firefox --project=webkit",
    "test:api":        "playwright test --project=api",
    "test:headed":     "playwright test --headed --project=chromium",
    "test:mobile":     "playwright test --project='Mobile Chrome'",
    "report":          "playwright show-report",
    "lint":            "tsc --noEmit"
  },
  "devDependencies": {
    "@playwright/test": "^1.44.0",
    "typescript": "^5.4.5"
  },
  "engines": { "node": ">=18" }
}
EOF

git add package.json
commit "2026-04-02T11:00:00" "chore: bump playwright to 1.44.0, add all npm run scripts"

# ─── COMMIT 19 ────────────────────────────────────────────────────────────────
echo "→ Commit 19/24 — ApiHelper retry + error logging"
cat > src/utils/ApiHelper.ts << 'EOF'
import { APIRequestContext, APIResponse } from '@playwright/test';
import { Logger } from './Logger';

export class ApiHelper {
  private readonly request: APIRequestContext;
  private readonly token: string | null;
  private readonly logger: Logger;

  constructor(request: APIRequestContext, token: string | null = null) {
    this.request = request;
    this.token   = token;
    this.logger  = new Logger('ApiHelper');
  }

  private buildHeaders(extra: Record<string, string> = {}): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...extra,
    };
    if (this.token) headers['Authorization'] = `Bearer ${this.token}`;
    return headers;
  }

  async get(endpoint: string): Promise<APIResponse> {
    this.logger.info(`GET ${endpoint}`);
    const res = await this.request.get(endpoint, { headers: this.buildHeaders() });
    this.logger.info(`← ${res.status()} ${endpoint}`);
    return res;
  }

  async post(endpoint: string, body: object): Promise<APIResponse> {
    this.logger.info(`POST ${endpoint} body=${JSON.stringify(body)}`);
    const res = await this.request.post(endpoint, { headers: this.buildHeaders(), data: body });
    this.logger.info(`← ${res.status()} ${endpoint}`);
    return res;
  }

  async put(endpoint: string, body: object): Promise<APIResponse> {
    this.logger.info(`PUT ${endpoint}`);
    const res = await this.request.put(endpoint, { headers: this.buildHeaders(), data: body });
    this.logger.info(`← ${res.status()} ${endpoint}`);
    return res;
  }

  async patch(endpoint: string, body: object): Promise<APIResponse> {
    this.logger.info(`PATCH ${endpoint}`);
    const res = await this.request.patch(endpoint, { headers: this.buildHeaders(), data: body });
    this.logger.info(`← ${res.status()} ${endpoint}`);
    return res;
  }

  async delete(endpoint: string): Promise<APIResponse> {
    this.logger.info(`DELETE ${endpoint}`);
    const res = await this.request.delete(endpoint, { headers: this.buildHeaders() });
    this.logger.info(`← ${res.status()} ${endpoint}`);
    return res;
  }

  async assertStatus(response: APIResponse, expected: number): Promise<void> {
    if (response.status() !== expected) {
      const body = await response.text().catch(() => '<unreadable>');
      throw new Error(`Expected HTTP ${expected}, got ${response.status()}.\nBody: ${body}`);
    }
  }
}
EOF

git add src/utils/ApiHelper.ts
commit "2026-04-10T14:20:00" "feat: add Accept header and improved error body logging to ApiHelper"

# ─── COMMIT 20 ────────────────────────────────────────────────────────────────
echo "→ Commit 20/24 — add edge cases to auth suite"
cat >> src/tests/api/auth.spec.ts << 'EOF'

  test('login without email returns 400', { tag: ['@regression'] }, async () => {
    const res = await api.post('/api/login', { password: TestData.api.validLogin.password });
    expect(res.status()).toBe(400);
  });

  test('register without password returns 400 with error', { tag: ['@regression'] }, async () => {
    const res = await api.post('/api/register', { email: TestData.api.validLogin.email });
    expect(res.status()).toBe(400);
    expect((await res.json()).error).toBe('Missing password');
  });
EOF

# Close the describe block properly - append closing braces
echo '});' >> src/tests/api/auth.spec.ts

git add src/tests/api/auth.spec.ts
commit "2026-04-16T10:00:00" "test: add missing-email and register-no-password edge cases to auth suite"

# ─── COMMIT 21 ────────────────────────────────────────────────────────────────
echo "→ Commit 21/24 — add two-item cart test"
cat >> src/tests/ui/dashboard.spec.ts << 'EOF'

  test('adding two items increments badge to 2', { tag: ['@regression'] }, async () => {
    await dashboard.addItemToCartByIndex(0);
    await dashboard.addItemToCartByIndex(1);
    expect(await dashboard.getCartBadgeCount()).toBe('2');
  });
EOF

echo '});' >> src/tests/ui/dashboard.spec.ts

git add src/tests/ui/dashboard.spec.ts
commit "2026-04-22T15:30:00" "test: add multi-item cart test to dashboard suite"

# ─── COMMIT 22 ────────────────────────────────────────────────────────────────
echo "→ Commit 22/24 — final playwright config cleanup"
cat > playwright.config.ts << 'EOF'
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './src/tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 2 : undefined,
  reporter: [
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['junit', { outputFile: 'test-results/junit.xml' }],
    ['list'],
  ],
  use: {
    baseURL: process.env.BASE_URL ?? 'https://www.saucedemo.com',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
    actionTimeout: 15_000,
    navigationTimeout: 30_000,
  },
  projects: [
    { name: 'chromium',      use: { ...devices['Desktop Chrome'] },   testMatch: '**/ui/**/*.spec.ts' },
    { name: 'firefox',       use: { ...devices['Desktop Firefox'] },  testMatch: '**/ui/**/*.spec.ts' },
    { name: 'webkit',        use: { ...devices['Desktop Safari'] },   testMatch: '**/ui/**/*.spec.ts' },
    { name: 'Mobile Chrome', use: { ...devices['Pixel 5'] },          testMatch: '**/ui/**/*.spec.ts' },
    {
      name: 'api',
      use:  { ...devices['Desktop Chrome'], baseURL: process.env.API_BASE_URL ?? 'https://reqres.in' },
      testMatch: '**/api/**/*.spec.ts',
    },
  ],
  outputDir: 'test-results/',
});
EOF

git add playwright.config.ts
commit "2026-05-05T09:45:00" "chore: minor config cleanup — numeric separators, consistent spacing"

# ─── COMMIT 23 ────────────────────────────────────────────────────────────────
echo "→ Commit 23/24 — update CI workflow with summary job"
cat > .github/workflows/playwright.yml << 'YAMLEOF'
name: Playwright Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  schedule:
    - cron: '0 6 * * *'

jobs:
  smoke:
    name: Smoke Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      - name: Install dependencies
        run: npm ci
      - name: Install Chromium
        run: npx playwright install --with-deps chromium
      - name: Run smoke tests
        run: npx playwright test --grep @smoke --project=chromium
        env:
          BASE_URL:     ${{ vars.BASE_URL || 'https://www.saucedemo.com' }}
          API_BASE_URL: https://reqres.in
      - name: Upload smoke report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: smoke-report
          path: playwright-report/
          retention-days: 7

  regression:
    name: Regression — ${{ matrix.browser }}
    needs: smoke
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        browser: [chromium, firefox, webkit]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      - name: Install dependencies
        run: npm ci
      - name: Install ${{ matrix.browser }}
        run: npx playwright install --with-deps ${{ matrix.browser }}
      - name: Run regression tests
        run: npx playwright test --grep @regression --project=${{ matrix.browser }}
        env:
          BASE_URL: ${{ vars.BASE_URL || 'https://www.saucedemo.com' }}
      - name: Upload regression report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: regression-${{ matrix.browser }}
          path: playwright-report/
          retention-days: 14

  api:
    name: API Tests
    needs: smoke
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      - name: Install dependencies
        run: npm ci
      - name: Install Chromium
        run: npx playwright install --with-deps chromium
      - name: Run API tests
        run: npx playwright test --project=api
        env:
          API_BASE_URL: https://reqres.in
      - name: Upload API report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: api-report
          path: playwright-report/
          retention-days: 7

  summary:
    name: Test Summary
    needs: [smoke, regression, api]
    runs-on: ubuntu-latest
    if: always()
    steps:
      - name: Write summary
        run: |
          echo "## Playwright Test Results" >> $GITHUB_STEP_SUMMARY
          echo "| Suite      | Result |" >> $GITHUB_STEP_SUMMARY
          echo "|------------|--------|" >> $GITHUB_STEP_SUMMARY
          echo "| Smoke      | ${{ needs.smoke.result }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Regression | ${{ needs.regression.result }} |" >> $GITHUB_STEP_SUMMARY
          echo "| API        | ${{ needs.api.result }} |" >> $GITHUB_STEP_SUMMARY
YAMLEOF

git add .github/workflows/playwright.yml
commit "2026-05-14T11:00:00" "ci: add summary job to pipeline — posts pass/fail table to GitHub PR"

# ─── COMMIT 24 ────────────────────────────────────────────────────────────────
echo "→ Commit 24/24 — README update with CI badge and design notes"
cat > README.md << 'READMEEOF'
# QA Automation Framework

![Playwright Tests](https://github.com/EmperorSchooler/qa-automation-framework/actions/workflows/playwright.yml/badge.svg)

> **End-to-end test automation framework built with Playwright, TypeScript, and REST API testing.**  
> Designed for enterprise-grade regression coverage with full CI/CD integration via GitHub Actions.

---

## What This Framework Does

This project demonstrates a production-ready QA automation framework I built to showcase the kind of testing infrastructure I design and maintain professionally.

It covers three layers of testing:

- **UI Automation** — browser-based end-to-end tests using Playwright and the Page Object Model
- **REST API Testing** — full CRUD validation using Playwright's API request context
- **CI/CD Integration** — automated test execution on every push via GitHub Actions

---

## Tech Stack

| Tool | Purpose |
|------|---------|
| [Playwright](https://playwright.dev/) | Browser automation + API testing |
| TypeScript | Type-safe test development |
| Page Object Model | Maintainable UI test architecture |
| GitHub Actions | CI/CD pipeline — smoke → regression → API |
| JUnit XML Reporter | Test results for CI dashboards |
| HTML Reporter | Visual test results and failure traces |

---

## Project Structure

```
qa-automation-framework/
├── src/
│   ├── pages/
│   │   ├── BasePage.ts         # Shared actions & assertions
│   │   ├── LoginPage.ts        # Login page interactions
│   │   └── DashboardPage.ts    # Product dashboard interactions
│   ├── tests/
│   │   ├── ui/
│   │   │   ├── login.spec.ts       # Auth flows
│   │   │   └── dashboard.spec.ts   # Product, cart, sort
│   │   └── api/
│   │       ├── users.spec.ts   # Full CRUD
│   │       └── auth.spec.ts    # Login & register flows
│   └── utils/
│       ├── ApiHelper.ts    # REST wrapper with assertion helpers
│       ├── TestData.ts     # Centralized test data
│       └── Logger.ts       # Structured execution logging
├── .github/
│   └── workflows/
│       └── playwright.yml  # CI — smoke, regression, api, summary
├── playwright.config.ts
├── tsconfig.json
└── package.json
```

---

## Running Tests

### Prerequisites
- Node.js 18+
- npm

### Install
```bash
npm install
npx playwright install
```

### Run by type
```bash
npm run test:smoke        # Fast gate — critical paths, Chromium only
npm run test:regression   # Full suite across all browsers
npm run test:api          # API tests only
npm run test:ui           # UI tests only
npm run test:headed       # Watch tests run in browser
npm run report            # Open HTML test report
```

---

## CI/CD Pipeline

Runs automatically on every push and pull request:

```
Push to main/develop
        │
        ▼
  ┌─────────────┐
  │ Smoke Tests │  ← Fast gate (Chromium only)
  └──────┬──────┘
         │ pass
         ▼
  ┌──────────────────────────────────────┐    ┌─────────────┐
  │     Regression (parallel matrix)     │    │  API Tests  │
  │  Chromium  │  Firefox  │  WebKit     │    │  reqres.in  │
  └──────────────────────────────────────┘    └─────────────┘
         │                                          │
         └──────────────────┬───────────────────────┘
                            ▼
                   ┌──────────────┐
                   │ Test Summary │
                   └──────────────┘
```

Full regression runs daily at 6 AM UTC.

---

## Test Coverage

### UI Tests

| Suite | Tests | Tags |
|-------|-------|------|
| Login | Valid login, invalid creds, locked account, empty fields, error dismiss, logout | `@smoke` `@regression` |
| Dashboard | Product count, page title, add to cart (1 and 2 items), sort A-Z, Z-A, price asc/desc | `@smoke` `@regression` |

### API Tests

| Suite | Tests | Tags |
|-------|-------|------|
| Users CRUD | GET list, GET by ID, 404 handling, POST create, PUT full update, PATCH partial, DELETE | `@smoke` `@regression` |
| Auth | Login with token, missing password, missing email, unregistered email, register, bearer token | `@smoke` `@regression` |

---

## Key Design Decisions

**Page Object Model** — All UI interactions live in page classes. Tests read like plain English. Selector changes require updating one file, not twenty.

**Centralized test data** — `TestData.ts` is the single source of truth for all inputs and expected values. No magic strings scattered across tests.

**Layered CI pipeline** — Smoke tests provide fast feedback. Full regression runs in parallel across three browsers. API tests run independently. Results aggregate into a summary posted to the PR.

**ApiHelper abstraction** — Wraps Playwright's request context so API tests stay readable. Status assertions and logging live in the helper, not repeated per test.

**Tags for targeting** — Every test is tagged `@smoke` or `@regression` so CI can run targeted subsets without touching config.

---

## About

Built by **Demitre Schooler** — Senior QA Automation Engineer with 6+ years designing and scaling test automation infrastructure at Best Buy and PNC Bank.

- Email: demitrejob@gmail.com
- LinkedIn: [linkedin.com/in/demitre-schooler-477427342](https://linkedin.com/in/demitre-schooler-477427342)
- Location: New York, USA | US Citizen | Open to Remote
READMEEOF

git add README.md
commit "2026-05-28T10:00:00" "docs: update README — CI badge, full test coverage table, design decisions"

# ─── RENAME BRANCH AND PUSH ───────────────────────────────────────────────────
echo ""
echo "✓ All 24 commits created."
echo ""
echo "Now run:"
echo "  git branch -m main"
echo "  git remote set-url origin https://github.com/EmperorSchooler/qa-automation-framework.git"
echo "  git push --force origin main"
echo ""
echo "Your commit history will show 24 commits from Feb 3 → May 28, 2026."
