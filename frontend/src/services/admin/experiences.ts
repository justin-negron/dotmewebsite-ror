import api, { handleApiError, extractData } from '../api'
import type { ApiSuccessResponse, Experience, ExperienceInput } from '@/types'

const ENDPOINTS = {
  base: '/api/v1/admin/experiences',
  detail: (id: number | string) => `/api/v1/admin/experiences/${id}`,
}

export async function getAll(params: Record<string, unknown> = {}) {
  try {
    const response = await api.get<ApiSuccessResponse<Experience[]>>(ENDPOINTS.base, { params })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function getOne(id: number | string) {
  try {
    const response = await api.get<ApiSuccessResponse<Experience>>(ENDPOINTS.detail(id))
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function create(data: ExperienceInput) {
  try {
    const response = await api.post<ApiSuccessResponse<Experience>>(ENDPOINTS.base, {
      experience: data,
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function update(id: number | string, data: Partial<ExperienceInput>) {
  try {
    const response = await api.patch<ApiSuccessResponse<Experience>>(ENDPOINTS.detail(id), {
      experience: data,
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
