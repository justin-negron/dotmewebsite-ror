import api, { handleApiError, extractData } from './api'
import type { ApiSuccessResponse, Contact, ContactFormData } from '@/types'

const ENDPOINTS = {
  base: '/api/v1/contacts',
  detail: (id: number | string) => `/api/v1/contacts/${id}`,
}

export async function submitContactForm(contactData: ContactFormData) {
  try {
    const response = await api.post<ApiSuccessResponse<Contact>>(ENDPOINTS.base, contactData)
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function getContacts(params: Record<string, unknown> = {}) {
  try {
    const response = await api.get<ApiSuccessResponse<Contact[]>>(ENDPOINTS.base, { params })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function getContact(id: number | string) {
  try {
    const response = await api.get<ApiSuccessResponse<Contact>>(ENDPOINTS.detail(id))
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function markAsRead(id: number | string) {
  try {
    const response = await api.patch<ApiSuccessResponse<Contact>>(
      `${ENDPOINTS.detail(id)}/mark_read`
    )
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function deleteContact(id: number | string) {
  try {
    await api.delete(ENDPOINTS.detail(id))
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export default {
  submitContactForm,
  getContacts,
  getContact,
  markAsRead,
  deleteContact,
}
