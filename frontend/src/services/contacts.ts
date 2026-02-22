import api, { handleApiError, extractData } from './api'
import type { ApiSuccessResponse, Contact, ContactFormData } from '@/types'

const ENDPOINTS = {
  base: '/api/v1/contacts',
}

export async function submitContactForm(contactData: ContactFormData) {
  try {
    const response = await api.post<ApiSuccessResponse<Contact>>(ENDPOINTS.base, contactData)
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export default {
  submitContactForm,
}
