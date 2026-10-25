import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import type { InternalAxiosRequestConfig } from 'axios'
import { createPinia, setActivePinia } from 'pinia'
import api from '@/services/api'
import { getRecentPosts } from '@/services/blog'
import { useExperiencesStore } from '@/stores/experiences'
import { useProjectsStore } from '@/stores/projects'
import { ok } from '@/test/axios'

describe('list requests ask for every row the API allows', () => {
  const requests: { url: string | undefined; params: Record<string, unknown> }[] = []
  const defaultAdapter = api.defaults.adapter

  beforeEach(() => {
    setActivePinia(createPinia())
    requests.length = 0
    api.defaults.adapter = vi.fn(async (config: InternalAxiosRequestConfig) => {
      const { _t, ...params } = config.params
      expect(typeof _t).toBe('number')
      requests.push({ url: config.url, params })
      return ok(config, { success: true, data: [] })
    })
  })

  afterEach(() => {
    api.defaults.adapter = defaultAdapter
  })

  it('projects store', async () => {
    const store = useProjectsStore()
    await store.fetchFeaturedProjects()
    await store.fetchProjects()

    expect(requests).toEqual([
      { url: '/api/v1/projects', params: { featured: true, per_page: 100 } },
      { url: '/api/v1/projects', params: { per_page: 100 } },
    ])
  })

  it('experiences store', async () => {
    await useExperiencesStore().fetchExperiences()

    expect(requests).toEqual([{ url: '/api/v1/experiences', params: { per_page: 100 } }])
  })

  it('recent blog posts send per_page, which the API reads', async () => {
    await getRecentPosts(3)

    expect(requests).toEqual([
      { url: '/api/v1/blog_posts', params: { published: true, per_page: 3 } },
    ])
  })
})
