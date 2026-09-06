import { test, expect } from '../helpers/fixtures'
import { shoot } from '../helpers/screenshot'
import { openWebClient, trackBrokenAssets } from '../helpers/plex'
import { readMachineIdentifier } from '../helpers/identity'

test.describe('plex smoke', () => {
  test('web client loads with every asset served', async ({ page }, testInfo) => {
    const broken = trackBrokenAssets(page)
    await openWebClient(page)
    await shoot(page, testInfo, 'web')
    expect(broken).toEqual([])
  })

  test('server reports an identity', async ({ request }) => {
    expect(await readMachineIdentifier(request)).not.toEqual('')
  })
})
