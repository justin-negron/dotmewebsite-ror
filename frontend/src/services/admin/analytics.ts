import api, { handleApiError, extractData } from '../api'
import type { ApiSuccessResponse, AdminDashboardData } from '@/types'

export async function getDashboard(days?: number) {
  try {
    const params = days ? { days } : {}
    const response = await api.get<ApiSuccessResponse<AdminDashboardData>>(
      '/api/v1/admin/analytics/dashboard',
      { params },
    )
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}
