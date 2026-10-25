import { readStorage, writeStorage } from '@/utils/storage'

const GUARD_KEY = 'stale-chunk-reload-at'
const GUARD_MS = 10_000

/**
 * A second failure inside the guard window means the reload did not help, so the error surfaces
 * instead of looping.
 */
export function reloadOnStaleChunk(
  reload: () => void = () => window.location.reload()
): () => void {
  function onPreloadError(event: Event) {
    const last = Number(readStorage(GUARD_KEY, 'session'))
    if (Number.isFinite(last) && Date.now() - last < GUARD_MS) return
    if (!writeStorage(GUARD_KEY, String(Date.now()), 'session')) return
    event.preventDefault()
    reload()
  }

  window.addEventListener('vite:preloadError', onPreloadError)
  return () => window.removeEventListener('vite:preloadError', onPreloadError)
}
