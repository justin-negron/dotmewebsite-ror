import api, { handleApiError, extractData } from '../api'
import type { ApiSuccessResponse, BlogPost, BlogPostInput } from '@/types'

const ENDPOINTS = {
  base: '/api/v1/admin/blog_posts',
  detail: (id: number | string) => `/api/v1/admin/blog_posts/${id}`,
  publish: (id: number | string) => `/api/v1/admin/blog_posts/${id}/publish`,
  unpublish: (id: number | string) => `/api/v1/admin/blog_posts/${id}/unpublish`,
}

export async function getAll(params: Record<string, unknown> = {}) {
  try {
    const response = await api.get<ApiSuccessResponse<BlogPost[]>>(ENDPOINTS.base, { params })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function getOne(id: number | string) {
  try {
    const response = await api.get<ApiSuccessResponse<BlogPost>>(ENDPOINTS.detail(id))
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function create(data: BlogPostInput) {
  try {
    const response = await api.post<ApiSuccessResponse<BlogPost>>(ENDPOINTS.base, {
      blog_post: data,
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function update(id: number | string, data: Partial<BlogPostInput>) {
  try {
    const response = await api.patch<ApiSuccessResponse<BlogPost>>(ENDPOINTS.detail(id), {
      blog_post: data,
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function remove(id: number | string) {
  try {
    const response = await api.delete<ApiSuccessResponse<{ message: string }>>(
      ENDPOINTS.detail(id),
    )
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function publish(id: number | string) {
  try {
    const response = await api.patch<ApiSuccessResponse<BlogPost>>(ENDPOINTS.publish(id))
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function unpublish(id: number | string) {
  try {
    const response = await api.patch<ApiSuccessResponse<BlogPost>>(ENDPOINTS.unpublish(id))
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}
