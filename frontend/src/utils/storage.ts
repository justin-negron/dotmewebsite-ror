type StorageArea = 'local' | 'session'

// Browsers that block site data throw on any storage access, including the getter itself.
function area(kind: StorageArea): Storage {
  return kind === 'local' ? window.localStorage : window.sessionStorage
}

export function readStorage(key: string, kind: StorageArea = 'local'): string | null {
  try {
    return area(kind).getItem(key)
  } catch {
    return null
  }
}

export function writeStorage(key: string, value: string, kind: StorageArea = 'local'): boolean {
  try {
    area(kind).setItem(key, value)
    return true
  } catch {
    return false
  }
}
