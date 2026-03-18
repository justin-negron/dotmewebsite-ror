import api, { handleApiError, extractData } from './api'
import type { AxiosError } from 'axios'
import type { ApiSuccessResponse, AuthResponse } from '@/types'

const ENDPOINTS = {
  login: '/api/v1/admin/auth/login',
  refresh: '/api/v1/admin/auth/refresh',
  logout: '/api/v1/admin/auth/logout',
}

export async function login(email: string, password: string) {
  try {
    const response = await api.post<ApiSuccessResponse<AuthResponse>>(
      ENDPOINTS.login,
      { email, password },
      { withCredentials: true },
    )
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as AxiosError)
  }
}

export async function refreshToken() {
  try {
    const response = await api.post<ApiSuccessResponse<AuthResponse>>(
      ENDPOINTS.refresh,
      {},
      { withCredentials: true },
    )
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as AxiosError)
  }
}

export async function logout(accessToken: string) {
  try {
    await api.delete(ENDPOINTS.logout, {
      headers: { Authorization: `Bearer ${accessToken}` },
      withCredentials: true,
    })
  } catch (error) {
    throw handleApiError(error as AxiosError)
  }
}

export default { login, refreshToken, logout }
