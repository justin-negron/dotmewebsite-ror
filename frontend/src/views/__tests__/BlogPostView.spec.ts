import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import type { BlogPost } from '@/types'

vi.mock('@/services/blog', () => ({
  getPublishedPosts: vi.fn(),
  getBlogPost: vi.fn(),
  getRecentPosts: vi.fn(),
}))

const post: BlogPost = {
  id: 1,
  title: 'Hello',
  slug: 'hello',
  content: 'Body',
  published: true,
  tags: [],
  view_count: 0,
  reading_time: 1,
  excerpt: 'Short',
  cover_image_url: null,
  published_at: '2026-10-01T00:00:00Z',
  created_at: '2026-10-01T00:00:00Z',
  updated_at: '2026-10-01T00:00:00Z',
}

async function mountPost(slug: string) {
  vi.resetModules()
  const pinia = createPinia()
  setActivePinia(pinia)
  const { getBlogPost } = await import('@/services/blog')
  const { default: BlogPostView } = await import('@/views/BlogPostView.vue')
  const { useBlogStore } = await import('@/stores/blog')
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/blog', name: 'blog', component: { template: '<div />' } },
      { path: '/blog/:slug', name: 'blog-post', component: BlogPostView },
    ],
  })
  await router.push(`/blog/${slug}`)
  return { getBlogPost: vi.mocked(getBlogPost), BlogPostView, pinia, router, useBlogStore }
}

function robots() {
  return document.querySelector('meta[name="robots"]')?.getAttribute('content') ?? null
}

function canonical() {
  return document.querySelector('link[rel="canonical"]')?.getAttribute('href') ?? null
}

describe('BlogPostView', () => {
  beforeEach(() => {
    document.head.innerHTML = ''
    vi.stubEnv('VITE_SITE_URL', 'https://justinnegron.dev')
  })

  afterEach(() => {
    vi.unstubAllEnvs()
  })

  it('marks a missing post noindex and clears the error when the visitor leaves', async () => {
    const ctx = await mountPost('gone')
    ctx.getBlogPost.mockRejectedValueOnce({ message: 'Not found', errors: [], status: 404 })

    const wrapper = mount(ctx.BlogPostView, { global: { plugins: [ctx.pinia, ctx.router] } })
    await flushPromises()

    expect(wrapper.get('.error-title').text()).toBe('Post not found')
    expect(robots()).toBe('noindex')
    expect(canonical()).toBe('https://justinnegron.dev/')

    wrapper.unmount()
    expect(ctx.useBlogStore().error).toBeNull()
  })

  it('indexes a post that loads, with its own canonical', async () => {
    const ctx = await mountPost('hello')
    ctx.getBlogPost.mockResolvedValueOnce({ success: true, data: post })

    mount(ctx.BlogPostView, { global: { plugins: [ctx.pinia, ctx.router] } })
    await flushPromises()

    expect(robots()).toBeNull()
    expect(canonical()).toBe('https://justinnegron.dev/blog/hello')
  })
})
