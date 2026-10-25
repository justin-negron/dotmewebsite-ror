import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { nextTick } from 'vue'

function stubMedia(matching: string[]) {
  vi.spyOn(window, 'matchMedia').mockImplementation(
    (query: string) =>
      ({
        matches: matching.includes(query),
        media: query,
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      }) as unknown as MediaQueryList
  )
}

async function importTheme() {
  vi.resetModules()
  return import('@/composables/useTheme')
}

describe('useTheme', () => {
  beforeEach(() => {
    localStorage.clear()
    document.documentElement.className = ''
    stubMedia([])
  })

  afterEach(() => {
    vi.restoreAllMocks()
    Reflect.deleteProperty(document, 'startViewTransition')
  })

  it('falls back to light when storage access throws at import', async () => {
    vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
      throw new DOMException('denied', 'SecurityError')
    })

    const { activeTheme } = await importTheme()

    expect(activeTheme.value).toBe('light')
  })

  it('accepts a stored dark theme and ignores an unknown stored value', async () => {
    localStorage.setItem('theme-preference', 'dark')
    expect((await importTheme()).activeTheme.value).toBe('dark')
    expect(document.documentElement.classList.contains('dark')).toBe(true)

    localStorage.setItem('theme-preference', 'purple')
    expect((await importTheme()).activeTheme.value).toBe('light')
  })

  it('persists a toggle once no matter how many components call useTheme', async () => {
    const { useTheme } = await importTheme()
    const setItem = vi.spyOn(Storage.prototype, 'setItem')
    useTheme()
    useTheme()
    const { toggleTheme } = useTheme()

    toggleTheme()
    await nextTick()

    expect(setItem.mock.calls).toEqual([['theme-preference', 'dark']])
  })

  it('still flips the theme when storage writes throw', async () => {
    const { useTheme } = await importTheme()
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
      throw new DOMException('full', 'QuotaExceededError')
    })
    const { theme, toggleTheme } = useTheme()

    toggleTheme()
    await nextTick()

    expect(theme.value).toBe('dark')
    expect(document.documentElement.classList.contains('dark')).toBe(true)
  })

  describe('view transition', () => {
    let startViewTransition: ReturnType<typeof vi.fn>

    beforeEach(() => {
      startViewTransition = vi.fn((update: () => void) => {
        update()
        return { ready: Promise.resolve() }
      })
      Object.defineProperty(document, 'startViewTransition', {
        configurable: true,
        value: startViewTransition,
      })
      document.documentElement.animate = vi.fn()
    })

    it('skips the animation when the visitor prefers reduced motion', async () => {
      stubMedia(['(prefers-reduced-motion: reduce)'])
      const { useTheme } = await importTheme()
      const { theme, toggleTheme } = useTheme()

      toggleTheme()

      expect(startViewTransition).toHaveBeenCalledTimes(0)
      expect(theme.value).toBe('dark')
    })

    it('animates the toggle otherwise', async () => {
      const { useTheme } = await importTheme()
      const { theme, toggleTheme } = useTheme()

      toggleTheme()

      expect(startViewTransition).toHaveBeenCalledTimes(1)
      expect(theme.value).toBe('dark')
    })
  })
})
