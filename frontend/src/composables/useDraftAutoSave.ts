import { ref, onMounted } from 'vue'

export interface DraftData {
  title: string
  content: string
  slug: string
  tags: string[]
  cover_image_url?: string
  savedAt: string
}

const STORAGE_PREFIX = 'blog-draft-'
const MAX_AGE_MS = 7 * 24 * 60 * 60 * 1000 // 7 days

export function useDraftAutoSave(postId: string | number | 'new') {
  const hasDraft = ref(false)
  const draftSavedAt = ref<string | null>(null)

  let debounceTimer: ReturnType<typeof setTimeout> | null = null
  const storageKey = `${STORAGE_PREFIX}${postId}`

  function saveDraft(data: Omit<DraftData, 'savedAt'>) {
    if (debounceTimer) clearTimeout(debounceTimer)

    debounceTimer = setTimeout(() => {
      const draft: DraftData = {
        ...data,
        savedAt: new Date().toISOString(),
      }
      try {
        localStorage.setItem(storageKey, JSON.stringify(draft))
        draftSavedAt.value = draft.savedAt
        hasDraft.value = true
      } catch {
        // localStorage full or unavailable — silently fail
      }
    }, 2000)
  }

  function loadDraft(): DraftData | null {
    try {
      const raw = localStorage.getItem(storageKey)
      if (!raw) return null

      const draft: DraftData = JSON.parse(raw)

      // Ignore drafts older than 7 days
      if (Date.now() - new Date(draft.savedAt).getTime() > MAX_AGE_MS) {
        localStorage.removeItem(storageKey)
        return null
      }

      return draft
    } catch {
      return null
    }
  }

  function clearDraft() {
    if (debounceTimer) clearTimeout(debounceTimer)
    localStorage.removeItem(storageKey)
    hasDraft.value = false
    draftSavedAt.value = null
  }

  onMounted(() => {
    const draft = loadDraft()
    if (draft) {
      hasDraft.value = true
      draftSavedAt.value = draft.savedAt
    }
  })

  return {
    hasDraft,
    draftSavedAt,
    saveDraft,
    loadDraft,
    clearDraft,
  }
}
