import api, { handleApiError, extractData } from './api'
import type { ApiSuccessResponse, Experience, ExperienceInput } from '@/types'

const ENDPOINTS = {
  base: '/api/v1/experiences',
  detail: (id: number | string) => `/api/v1/experiences/${id}`,
}

export async function getExperiences(params: Record<string, unknown> = {}) {
  try {
    const response = await api.get<ApiSuccessResponse<Experience[]>>(ENDPOINTS.base, { params })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function getExperience(id: number | string) {
  try {
    const response = await api.get<ApiSuccessResponse<Experience>>(ENDPOINTS.detail(id))
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function getCurrentExperience() {
  try {
    const response = await api.get<ApiSuccessResponse<Experience[]>>(ENDPOINTS.base, {
      params: { current: true },
    })
    const data = extractData(response)
    return data.data.length > 0 ? data.data[0] : null
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function createExperience(experienceData: ExperienceInput) {
  try {
    const response = await api.post<ApiSuccessResponse<Experience>>(ENDPOINTS.base, experienceData)
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function updateExperience(
  id: number | string,
  experienceData: Partial<ExperienceInput>
) {
  try {
    const response = await api.put<ApiSuccessResponse<Experience>>(
      ENDPOINTS.detail(id),
      experienceData
    )
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function deleteExperience(id: number | string) {
  try {
    await api.delete(ENDPOINTS.detail(id))
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export default {
  getExperiences,
  getExperience,
  getCurrentExperience,
  createExperience,
  updateExperience,
  deleteExperience,
}
