import { vi } from 'vitest'

// jsdom ships none of these. useTheme calls matchMedia at import time and every
// section component builds an IntersectionObserver in onMounted.
if (typeof window.matchMedia !== 'function') {
  window.matchMedia = (query: string) =>
    ({
      matches: false,
      media: query,
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      dispatchEvent: vi.fn(() => false),
    }) as unknown as MediaQueryList
}

class ObserverStub {
  readonly root = null
  readonly rootMargin = ''
  readonly thresholds: ReadonlyArray<number> = []
  observe = vi.fn()
  unobserve = vi.fn()
  disconnect = vi.fn()
  takeRecords = vi.fn(() => [])
}

for (const name of ['IntersectionObserver', 'ResizeObserver'] as const) {
  if (!(name in window)) {
    Object.defineProperty(window, name, { configurable: true, writable: true, value: ObserverStub })
    Object.defineProperty(globalThis, name, {
      configurable: true,
      writable: true,
      value: ObserverStub,
    })
  }
}
