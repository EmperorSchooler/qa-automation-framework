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
