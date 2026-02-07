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
