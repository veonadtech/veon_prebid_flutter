import { expect, test } from '@playwright/test';

test('stage app is available in a browser', async ({ page }) => {
  const url = process.env.STAGE_URL;
  if (!url) throw new Error('STAGE_URL must point to the deployed stage app');
  const response = await page.goto(url);
  expect(response?.ok()).toBe(true);
  await expect(page.locator('body')).not.toBeEmpty();
});
