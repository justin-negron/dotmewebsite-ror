import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { defineComponent } from 'vue'
import { useDraftAutoSave } from '@/composables/useDraftAutoSave'

const DAY_MS = 24 * 60 * 60 * 1000

function withDraft(postId: string | number) {
  let result!: ReturnType<typeof useDraftAutoSave>
  mount(
    defineComponent({
      setup() {
        result = useDraftAutoSave(postId)
        return () => null
      },
    })
  )
  return result
}

function stored(key: string) {
  const raw = localStorage.getItem(key)
  return raw === null ? null : JSON.parse(raw)
}

describe('useDraftAutoSave', () => {
  beforeEach(() => {
    localStorage.clear()
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-10-14T12:00:00Z'))
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('saves once, two seconds after the last change', () => {
    const { saveDraft, hasDraft } = withDraft('new')

    saveDraft({ title: 'a', content: 'x', slug: 'a', tags: [] })
    vi.advanceTimersByTime(500)
    saveDraft({ title: 'b', content: 'x', slug: 'a', tags: [] })
    vi.advanceTimersByTime(1999)
    expect(stored('blog-draft-new')).toBeNull()

    vi.advanceTimersByTime(1)
    expect(stored('blog-draft-new')).toEqual({
      title: 'b',
      content: 'x',
      slug: 'a',
      tags: [],
      savedAt: '2026-10-14T12:00:02.500Z',
    })
    expect(hasDraft.value).toBe(true)
  })

  it('drops a draft older than seven days and keeps a recent one', () => {
    const old = { title: 'old', content: '', slug: 'old', tags: [] }
    localStorage.setItem(
      'blog-draft-3',
      JSON.stringify({ ...old, savedAt: new Date(Date.now() - 8 * DAY_MS).toISOString() })
    )
    localStorage.setItem(
      'blog-draft-4',
      JSON.stringify({ ...old, savedAt: new Date(Date.now() - DAY_MS).toISOString() })
    )

    const expired = withDraft(3)
    const recent = withDraft(4)

    expect(expired.loadDraft()).toBeNull()
    expect(localStorage.getItem('blog-draft-3')).toBeNull()
    expect(expired.hasDraft.value).toBe(false)
    expect(recent.loadDraft()?.savedAt).toBe('2026-10-13T12:00:00.000Z')
    expect(recent.hasDraft.value).toBe(true)
  })
})
