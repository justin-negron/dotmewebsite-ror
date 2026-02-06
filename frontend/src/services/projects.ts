import api, { handleApiError, extractData } from './api'
import type { ApiSuccessResponse, Project, ProjectInput } from '@/types'

const ENDPOINTS = {
  base: '/api/v1/projects',
  detail: (id: number | string) => `/api/v1/projects/${id}`,
}

export async function getProjects(params: Record<string, unknown> = {}) {
  try {
    const response = await api.get<ApiSuccessResponse<Project[]>>(ENDPOINTS.base, { params })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function getProject(id: number | string) {
  try {
    const response = await api.get<ApiSuccessResponse<Project>>(ENDPOINTS.detail(id))
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function getFeaturedProjects() {
  try {
    const response = await api.get<ApiSuccessResponse<Project[]>>(ENDPOINTS.base, {
      params: { featured: true },
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function getProjectsByTechnology(technology: string) {
  try {
    const response = await api.get<ApiSuccessResponse<Project[]>>(ENDPOINTS.base, {
      params: { technology },
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function createProject(projectData: ProjectInput) {
  try {
    const response = await api.post<ApiSuccessResponse<Project>>(ENDPOINTS.base, projectData)
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function updateProject(id: number | string, projectData: Partial<ProjectInput>) {
  try {
    const response = await api.put<ApiSuccessResponse<Project>>(ENDPOINTS.detail(id), projectData)
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function deleteProject(id: number | string) {
  try {
    await api.delete(ENDPOINTS.detail(id))
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export default {
  getProjects,
  getProject,
  getFeaturedProjects,
  getProjectsByTechnology,
  createProject,
  updateProject,
  deleteProject,
}
