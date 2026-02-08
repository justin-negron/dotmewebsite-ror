import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { getPublishedPosts, getBlogPost, getRecentPosts, incrementViewCount } from '@/services/blog'
import type { BlogPost, ApiError, PaginationMeta } from '@/types'

export const useBlogStore = defineStore('blog', () => {
  // State
  const posts = ref<BlogPost[]>([])
  const currentPost = ref<BlogPost | null>(null)
  const recentPosts = ref<BlogPost[]>([])
  const loading = ref(false)
  const error = ref<ApiError | null>(null)

  // Pagination
  const pagination = ref<PaginationMeta | null>(null)
  const currentPage = ref(1)
  const currentTag = ref<string | null>(null)

  // Cache flags
  const postsLoaded = ref(false)
  const recentLoaded = ref(false)

  // Getters
  const totalPages = computed(() => pagination.value?.total_pages ?? 1)
  const totalCount = computed(() => pagination.value?.total_count ?? 0)
  const hasPosts = computed(() => posts.value.length > 0)
  const hasNextPage = computed(() => currentPage.value < totalPages.value)
  const hasPreviousPage = computed(() => currentPage.value > 1)

  const allTags = computed(() => {
    const tagSet = new Set<string>()
    posts.value.forEach((post) => post.tags.forEach((tag) => tagSet.add(tag)))
    return Array.from(tagSet).sort()
  })

  // Actions
  async function fetchPosts(
    params: { page?: number; per_page?: number; tag?: string } = {},
    force = false
  ): Promise<void> {
    const tagChanged = params.tag !== undefined && params.tag !== currentTag.value
    const pageChanged = params.page !== undefined && params.page !== currentPage.value

    if (postsLoaded.value && !force && !tagChanged && !pageChanged) return

    loading.value = true
    error.value = null

    try {
      const response = await getPublishedPosts(params)
      posts.value = response.data
      pagination.value = response.meta ?? null
      currentPage.value = params.page ?? 1
      currentTag.value = params.tag ?? null
      postsLoaded.value = true
    } catch (err) {
      error.value = err as ApiError
    } finally {
      loading.value = false
    }
  }

  async function fetchPost(slug: string): Promise<void> {
    const cached = posts.value.find((p) => p.slug === slug)

    if (cached) {
      currentPost.value = cached
      // Fire-and-forget: track the view without blocking
      incrementViewCount(slug).catch(() => {})
      return
    }

    loading.value = true
    error.value = null

    try {
      const response = await getBlogPost(slug)
      currentPost.value = response.data
      // Fire-and-forget: track the view without blocking
      incrementViewCount(slug).catch(() => {})
    } catch (err) {
      error.value = err as ApiError
    } finally {
      loading.value = false
    }
  }

  async function fetchRecentPosts(limit = 5, force = false): Promise<void> {
    if (recentLoaded.value && !force) return

    loading.value = true
    error.value = null

    try {
      const response = await getRecentPosts(limit)
      recentPosts.value = response.data
      recentLoaded.value = true
    } catch (err) {
      error.value = err as ApiError
    } finally {
      loading.value = false
    }
  }

  async function fetchPostsByTag(tag: string): Promise<void> {
    await fetchPosts({ tag }, true)
  }

  function setPage(page: number) {
    fetchPosts({ page, tag: currentTag.value ?? undefined })
  }

  function clearCurrentPost() {
    currentPost.value = null
  }

  function clearError() {
    error.value = null
  }

  function $reset() {
    posts.value = []
    currentPost.value = null
    recentPosts.value = []
    loading.value = false
    error.value = null
    pagination.value = null
    currentPage.value = 1
    currentTag.value = null
    postsLoaded.value = false
    recentLoaded.value = false
  }

  return {
    // State
    posts,
    currentPost,
    recentPosts,
    loading,
    error,
    pagination,
    currentPage,
    currentTag,

    // Getters
    totalPages,
    totalCount,
    hasPosts,
    hasNextPage,
    hasPreviousPage,
    allTags,

    // Actions
    fetchPosts,
    fetchPost,
    fetchRecentPosts,
    fetchPostsByTag,
    setPage,
    clearCurrentPost,
    clearError,
    $reset,
  }
})
