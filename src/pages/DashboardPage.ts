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
