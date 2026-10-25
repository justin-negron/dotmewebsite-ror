import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { reloadOnStaleChunk } from '@/utils/reloadOnStaleChunk'

function preloadError() {
  const event = new Event('vite:preloadError', { cancelable: true })
  window.dispatchEvent(event)
  return event
}

describe('reloadOnStaleChunk', () => {
  let remove: () => void
  const reload = vi.fn()

  beforeEach(() => {
    sessionStorage.clear()
    reload.mockReset()
    vi.useFakeTimers({ toFake: ['Date'] })
    vi.setSystemTime(new Date('2026-10-14T12:00:00Z'))
    remove = reloadOnStaleChunk(reload)
  })

  afterEach(() => {
    remove()
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  it('reloads once on a failed chunk load and lets a second failure surface', () => {
    const first = preloadError()
    const second = preloadError()

    expect(reload).toHaveBeenCalledTimes(1)
    expect([first.defaultPrevented, second.defaultPrevented]).toEqual([true, false])
  })

  it('reloads again for a failure after the guard window', () => {
    preloadError()
    vi.setSystemTime(new Date('2026-10-14T12:00:11Z'))
    preloadError()

    expect(reload).toHaveBeenCalledTimes(2)
  })

  it('never reloads when it cannot record the guard', () => {
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
      throw new DOMException('denied', 'SecurityError')
    })

    const event = preloadError()

    expect(reload).toHaveBeenCalledTimes(0)
    expect(event.defaultPrevented).toBe(false)
  })
})
