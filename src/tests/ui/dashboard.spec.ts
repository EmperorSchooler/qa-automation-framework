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

  test('adding two items increments badge to 2', { tag: ['@regression'] }, async () => {
    await dashboard.addItemToCartByIndex(0);
    await dashboard.addItemToCartByIndex(1);
    expect(await dashboard.getCartBadgeCount()).toBe('2');
  });
});
