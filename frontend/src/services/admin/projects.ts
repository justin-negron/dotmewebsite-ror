import api, { handleApiError, extractData } from '../api'
import type { ApiSuccessResponse, Project, ProjectInput } from '@/types'

const ENDPOINTS = {
  base: '/api/v1/admin/projects',
  detail: (id: number | string) => `/api/v1/admin/projects/${id}`,
}

export async function getAll(params: Record<string, unknown> = {}) {
  try {
    const response = await api.get<ApiSuccessResponse<Project[]>>(ENDPOINTS.base, { params })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function getOne(id: number | string) {
  try {
    const response = await api.get<ApiSuccessResponse<Project>>(ENDPOINTS.detail(id))
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function create(data: ProjectInput) {
  try {
    const response = await api.post<ApiSuccessResponse<Project>>(ENDPOINTS.base, {
      project: data,
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function update(id: number | string, data: Partial<ProjectInput>) {
  try {
    const response = await api.patch<ApiSuccessResponse<Project>>(ENDPOINTS.detail(id), {
      project: data,
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
