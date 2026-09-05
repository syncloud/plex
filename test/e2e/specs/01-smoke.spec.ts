import { test, expect } from '../helpers/fixtures'
import { shoot } from '../helpers/screenshot'
import { readMachineIdentifier } from '../helpers/identity'

test.describe('plex smoke', () => {
  test('web client loads', async ({ page }, testInfo) => {
    const response = await page.goto('/web/index.html')
    expect(response?.status()).toBeLessThan(400)
    await expect(page).toHaveTitle(/Plex/i)
    await shoot(page, testInfo, 'web')
  })

  test('server reports an identity', async ({ request }) => {
    expect(await readMachineIdentifier(request)).not.toEqual('')
  })
})
