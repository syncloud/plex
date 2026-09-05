import { test, expect } from '../helpers/fixtures'
import { shoot } from '../helpers/screenshot'
import { readMachineIdentifier, loadMachineIdentifier } from '../helpers/identity'

test.describe('plex after upgrade', () => {
  test('server identity survived the refresh', async ({ page, request }, testInfo) => {
    await page.goto('/web/index.html')
    await expect(page).toHaveTitle(/Plex/i)
    await shoot(page, testInfo, 'web-after-upgrade')

    expect(await readMachineIdentifier(request)).toEqual(loadMachineIdentifier())
  })
})
