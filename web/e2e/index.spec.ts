import { test, expect } from '@playwright/test'

test('plex web index responds', async ({ page }) => {
  const response = await page.goto('/web/index.html')
  expect(response?.status()).toBeLessThan(400)
  await expect(page).toHaveTitle(/Plex/i)
})
