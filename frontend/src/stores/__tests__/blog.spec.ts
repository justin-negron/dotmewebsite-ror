import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import type { BlogPost } from '@/types'
import { getBlogPost, getPublishedPosts } from '@/services/blog'
import { useBlogStore } from '@/stores/blog'

vi.mock('@/services/blog', () => ({
  getPublishedPosts: vi.fn(),
  getBlogPost: vi.fn(),
  getRecentPosts: vi.fn(),
}))

function post(id: number, slug: string, tags: string[]): BlogPost {
  return {
    id,
    title: slug,
    slug,
    content: '',
    published: true,
    tags,
    view_count: 0,
    reading_time: 1,
    excerpt: '',
    cover_image_url: null,
    published_at: '2026-10-01T00:00:00Z',
    created_at: '2026-10-01T00:00:00Z',
    updated_at: '2026-10-01T00:00:00Z',
  }
}

const rubyPost = post(1, 'a', ['Ruby'])
const jsPost = post(2, 'b', ['JS'])

describe('blog store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.mocked(getPublishedPosts).mockReset()
    vi.mocked(getBlogPost).mockReset()
    vi.mocked(getPublishedPosts).mockImplementation(async (params = {}) => ({
      success: true,
      data: params.tag === 'Ruby' ? [rubyPost] : [rubyPost, jsPost],
    }))
  })

  it('clears a failed post lookup when a cached post opens next', async () => {
    const store = useBlogStore()
    await store.fetchPosts()
    await store.fetchPost('b')
    vi.mocked(getBlogPost).mockRejectedValueOnce({ message: 'Not found', errors: [], status: 404 })

    await store.fetchPost('missing')
    expect(store.error).toEqual({ message: 'Not found', errors: [], status: 404 })
    expect(store.currentPost).toBeNull()

    await store.fetchPost('a')
    expect(store.error).toBeNull()
    expect(store.currentPost?.id).toBe(1)
  })

  it('refetches the full list after a tag filter', async () => {
    const store = useBlogStore()

    await store.fetchPostsByTag('Ruby')
    await store.fetchPosts()

    expect(vi.mocked(getPublishedPosts).mock.calls).toEqual([[{ tag: 'Ruby' }], [{}]])
    expect(store.posts.map((p) => p.id)).toEqual([1, 2])
    expect(store.currentTag).toBeNull()
  })

  it('serves the unfiltered list from cache on a repeat visit', async () => {
    const store = useBlogStore()

    await store.fetchPosts()
    await store.fetchPosts()

    expect(vi.mocked(getPublishedPosts)).toHaveBeenCalledTimes(1)
    expect(store.posts.map((p) => p.id)).toEqual([1, 2])
  })
})
