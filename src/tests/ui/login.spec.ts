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
