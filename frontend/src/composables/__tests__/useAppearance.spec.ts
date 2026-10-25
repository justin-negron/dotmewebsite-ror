/// <reference types="node" />
import { readdirSync, readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { nextTick } from 'vue'

// Read from disk: a ?raw import would replace each file's real coverage with its one-line raw module.
const srcDir = resolve(__dirname, '../..')
const sources = readdirSync(srcDir, { recursive: true, encoding: 'utf8' })
  .filter((file) => /\.(vue|ts|css)$/.test(file) && !file.includes('__tests__'))
  .map((file) => readFileSync(resolve(srcDir, file), 'utf8'))

async function importAppearance() {
  vi.resetModules()
  return import('@/composables/useAppearance')
}

describe('useAppearance', () => {
  beforeEach(() => {
    localStorage.clear()
    document.documentElement.removeAttribute('style')
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('rejects background ids inherited from Object.prototype', async () => {
    localStorage.setItem('appearance-bg', 'constellations')
    const { useAppearance } = await importAppearance()
    const { background, setBackground } = useAppearance()

    setBackground('constructor')
    setBackground('geometric-drift')
    setBackground('toString')

    expect(background.value).toBe('geometric-drift')
  })

  it('rejects skin ids inherited from Object.prototype', async () => {
    localStorage.setItem('appearance-skin', 'sage')
    const { useAppearance } = await importAppearance()
    const { skin, setSkin } = useAppearance()

    setSkin('constructor')

    expect(skin.value).toBe('sage')
  })

  it('replaces a stored Object.prototype name with a real id on load', async () => {
    localStorage.setItem('appearance-bg', 'constructor')
    localStorage.setItem('appearance-skin', 'hasOwnProperty')
    vi.spyOn(Math, 'random').mockReturnValue(0)

    const { useAppearance } = await importAppearance()
    const { background, skin } = useAppearance()

    expect(background.value).toBe('flow-field')
    expect(skin.value).toBe('amber')
  })

  it('loads with random picks when storage access throws', async () => {
    vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
      throw new DOMException('denied', 'SecurityError')
    })
    vi.spyOn(Math, 'random').mockReturnValue(0.99)

    const { useAppearance } = await importAppearance()
    const { background, skin } = useAppearance()

    expect(background.value).toBe('constellations')
    expect(skin.value).toBe('sage')
    expect(document.documentElement.style.getPropertyValue('--skin-600')).toBe('#059669')
  })

  it('defines every skin token the code references, in every skin', async () => {
    const { SKINS } = await importAppearance()
    const referenced = new Set(
      sources.flatMap((src) => [...src.matchAll(/var\((--skin-[a-z0-9-]+)/g)].map((m) => m[1]!))
    )

    const missing = Object.values(SKINS).flatMap((skin) =>
      [...referenced]
        .filter((token) => !Object.hasOwn(skin.vars, token))
        .map((t) => `${skin.id} ${t}`)
    )

    expect(missing).toEqual([])
  })

  it('applies and persists a new skin once across several callers', async () => {
    localStorage.setItem('appearance-skin', 'amber')
    const { useAppearance } = await importAppearance()
    const setItem = vi.spyOn(Storage.prototype, 'setItem')
    useAppearance()
    const { setSkin } = useAppearance()

    setSkin('ocean')
    await nextTick()

    expect(setItem.mock.calls).toEqual([['appearance-skin', 'ocean']])
    expect(document.documentElement.style.getPropertyValue('--skin-600')).toBe('#0891b2')
  })
})
