import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import * as api from '@/services/admin/blogPosts'
import type { BlogPost, BlogPostInput, ApiError, PaginationMeta } from '@/types'

export const useAdminBlogPostsStore = defineStore('admin-blog-posts', () => {
  const blogPosts = ref<BlogPost[]>([])
  const currentPost = ref<BlogPost | null>(null)
  const loading = ref(false)
  const error = ref<ApiError | null>(null)
  const pagination = ref<PaginationMeta | null>(null)

  const postCount = computed(() => pagination.value?.total_count ?? blogPosts.value.length)
  const publishedCount = computed(() => blogPosts.value.filter((p) => p.published).length)
  const draftCount = computed(() => blogPosts.value.filter((p) => !p.published).length)

  async function fetchAll(params: Record<string, unknown> = {}): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const response = await api.getAll(params)
      blogPosts.value = response.data
      pagination.value = response.meta as PaginationMeta
    } catch (err) {
      error.value = err as ApiError
    } finally {
      loading.value = false
    }
  }

  async function fetchOne(id: number | string): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const response = await api.getOne(id)
      currentPost.value = response.data
    } catch (err) {
      error.value = err as ApiError
    } finally {
      loading.value = false
    }
  }

  async function create(data: BlogPostInput): Promise<BlogPost | null> {
    loading.value = true
    error.value = null
    try {
      const response = await api.create(data)
      const post = response.data
      blogPosts.value.unshift(post)
      return post
    } catch (err) {
      error.value = err as ApiError
      return null
    } finally {
      loading.value = false
    }
  }

  async function update(
    id: number | string,
    data: Partial<BlogPostInput>,
  ): Promise<BlogPost | null> {
    loading.value = true
    error.value = null
    try {
      const response = await api.update(id, data)
      const updated = response.data
      const idx = blogPosts.value.findIndex((p) => p.id === updated.id)
      if (idx !== -1) blogPosts.value[idx] = updated
      currentPost.value = updated
      return updated
    } catch (err) {
      error.value = err as ApiError
      return null
    } finally {
      loading.value = false
    }
  }

  async function remove(id: number | string): Promise<boolean> {
    loading.value = true
    error.value = null
    try {
      await api.remove(id)
      blogPosts.value = blogPosts.value.filter((p) => p.id !== Number(id))
      if (currentPost.value?.id === Number(id)) currentPost.value = null
      return true
    } catch (err) {
      error.value = err as ApiError
      return false
    } finally {
      loading.value = false
    }
  }

  async function publish(id: number | string): Promise<boolean> {
    error.value = null
    try {
      const response = await api.publish(id)
      const updated = response.data
      const idx = blogPosts.value.findIndex((p) => p.id === updated.id)
      if (idx !== -1) blogPosts.value[idx] = updated
      if (currentPost.value?.id === updated.id) currentPost.value = updated
      return true
    } catch (err) {
      error.value = err as ApiError
      return false
    }
  }

  async function unpublish(id: number | string): Promise<boolean> {
    error.value = null
    try {
      const response = await api.unpublish(id)
      const updated = response.data
      const idx = blogPosts.value.findIndex((p) => p.id === updated.id)
      if (idx !== -1) blogPosts.value[idx] = updated
      if (currentPost.value?.id === updated.id) currentPost.value = updated
      return true
    } catch (err) {
      error.value = err as ApiError
      return false
    }
  }

  function clearError() {
    error.value = null
  }

  function $reset() {
    blogPosts.value = []
    currentPost.value = null
    loading.value = false
    error.value = null
    pagination.value = null
  }

  return {
    blogPosts,
    currentPost,
    loading,
    error,
    pagination,
    postCount,
    publishedCount,
    draftCount,
    fetchAll,
    fetchOne,
    create,
    update,
    remove,
    publish,
    unpublish,
    clearError,
    $reset,
  }
})
