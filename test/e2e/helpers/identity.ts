import { APIRequestContext } from '@playwright/test'
import * as path from 'node:path'
import * as fs from 'node:fs'
import { env } from './env'

const file = () => path.join(env('PLAYWRIGHT_STATE_DIR'), 'machine-identifier.txt')

export async function readMachineIdentifier(request: APIRequestContext): Promise<string> {
  const response = await request.get('/identity')
  if (!response.ok()) {
    throw new Error(`/identity returned ${response.status()}`)
  }
  const body = await response.text()
  const match = body.match(/machineIdentifier="([^"]+)"/)
  if (!match) {
    throw new Error(`no machineIdentifier in /identity: ${body}`)
  }
  return match[1]
}

export function saveMachineIdentifier(value: string) {
  fs.mkdirSync(path.dirname(file()), { recursive: true })
  fs.writeFileSync(file(), value)
}

export function loadMachineIdentifier(): string {
  return fs.readFileSync(file(), 'utf8').trim()
}
