import api, { handleApiError, extractData } from '../api'
import type { ApiSuccessResponse, PresignedUrlResponse } from '@/types'

const ENDPOINTS = {
  presign: '/api/v1/admin/uploads/presign',
}

export async function getPresignedUrl(filename: string, contentType: string) {
  try {
    const response = await api.post<ApiSuccessResponse<PresignedUrlResponse>>(ENDPOINTS.presign, {
      filename,
      content_type: contentType,
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}
