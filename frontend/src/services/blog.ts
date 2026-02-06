import api, { handleApiError, extractData } from './api'
import type { ApiSuccessResponse, BlogPost, BlogPostInput } from '@/types'

const ENDPOINTS = {
  base: '/api/v1/blog_posts',
  detail: (slug: string) => `/api/v1/blog_posts/${slug}`,
}

export async function getBlogPosts(params: Record<string, unknown> = {}) {
  try {
    const response = await api.get<ApiSuccessResponse<BlogPost[]>>(ENDPOINTS.base, { params })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function getBlogPost(slug: string) {
  try {
    const response = await api.get<ApiSuccessResponse<BlogPost>>(ENDPOINTS.detail(slug))
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function getPublishedPosts(params: Record<string, unknown> = {}) {
  try {
    const response = await api.get<ApiSuccessResponse<BlogPost[]>>(ENDPOINTS.base, {
      params: { ...params, published: true },
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function getPostsByTag(tag: string) {
  try {
    const response = await api.get<ApiSuccessResponse<BlogPost[]>>(ENDPOINTS.base, {
      params: { tag },
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function getRecentPosts(limit: number = 5) {
  try {
    const response = await api.get<ApiSuccessResponse<BlogPost[]>>(ENDPOINTS.base, {
      params: { published: true, limit },
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function incrementViewCount(slug: string) {
  try {
    const response = await api.post<ApiSuccessResponse<BlogPost>>(
      `${ENDPOINTS.detail(slug)}/increment_views`
    )
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function createBlogPost(postData: BlogPostInput) {
  try {
    const response = await api.post<ApiSuccessResponse<BlogPost>>(ENDPOINTS.base, postData)
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function updateBlogPost(slug: string, postData: Partial<BlogPostInput>) {
  try {
    const response = await api.put<ApiSuccessResponse<BlogPost>>(ENDPOINTS.detail(slug), postData)
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function deleteBlogPost(slug: string) {
  try {
    await api.delete(ENDPOINTS.detail(slug))
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export default {
  getBlogPosts,
  getBlogPost,
  getPublishedPosts,
  getPostsByTag,
  getRecentPosts,
  incrementViewCount,
  createBlogPost,
  updateBlogPost,
  deleteBlogPost,
}
