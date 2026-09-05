import { test, expect } from '../helpers/fixtures'
import { shoot } from '../helpers/screenshot'
import { readMachineIdentifier, saveMachineIdentifier } from '../helpers/identity'

test.describe('plex before upgrade', () => {
  test('record the server identity', async ({ page, request }, testInfo) => {
    await page.goto('/web/index.html')
    await expect(page).toHaveTitle(/Plex/i)
    await shoot(page, testInfo, 'web-before-upgrade')

    const identifier = await readMachineIdentifier(request)
    expect(identifier).not.toEqual('')
    saveMachineIdentifier(identifier)
  })
})
