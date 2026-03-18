import api, { handleApiError, extractData } from '../api'
import type { ApiSuccessResponse, Contact } from '@/types'

const ENDPOINTS = {
  base: '/api/v1/admin/contacts',
  detail: (id: number | string) => `/api/v1/admin/contacts/${id}`,
}

export async function getAll(params: Record<string, unknown> = {}) {
  try {
    const response = await api.get<ApiSuccessResponse<Contact[]>>(ENDPOINTS.base, { params })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function getOne(id: number | string) {
  try {
    const response = await api.get<ApiSuccessResponse<Contact>>(ENDPOINTS.detail(id))
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function updateStatus(id: number | string, status: string) {
  try {
    const response = await api.patch<ApiSuccessResponse<Contact>>(ENDPOINTS.detail(id), {
      contact: { status },
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
