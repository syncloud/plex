import { Page, expect } from '@playwright/test'
import { env } from './env'

const ASSET_PATHS = ['/web/', '/auth/']

export function trackBrokenAssets(page: Page): string[] {
  const broken: string[] = []
  const host = env('PLAYWRIGHT_APP_DOMAIN')
  page.on('response', response => {
    const url = new URL(response.url())
    if (url.host !== host) {
      return
    }
    if (!ASSET_PATHS.some(prefix => url.pathname.startsWith(prefix))) {
      return
    }
    if (response.status() >= 400) {
      broken.push(`${response.status()} ${url.pathname}`)
    }
  })
  return broken
}

export async function openWebClient(page: Page) {
  const response = await page.goto('/web/index.html')
  expect(response?.status()).toBeLessThan(400)
  await expect(page).toHaveTitle(/Plex/i)
  await page.waitForFunction(() => {
    const urls = Array.from(document.querySelectorAll<HTMLElement>('#plex *'))
      .map(element => /url\("?(.*?)"?\)/.exec(getComputedStyle(element).backgroundImage)?.[1])
      .filter((url): url is string => Boolean(url))
    if (urls.length === 0) {
      return false
    }
    return urls.every(url => {
      const image = new Image()
      image.src = url
      return image.complete
    })
  }, null, { timeout: 60_000 })
}
