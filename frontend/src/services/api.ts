import axios from 'axios'
import type { AxiosError, AxiosResponse, InternalAxiosRequestConfig } from 'axios'
import type { ApiError, ApiErrorResponse } from '@/types'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000',
  timeout: parseInt(import.meta.env.VITE_API_TIMEOUT || '30000', 10),
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
})

// Request interceptor
api.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    if (config.method === 'get') {
      config.params = {
        ...config.params,
        _t: Date.now(),
      }
    }

    if (import.meta.env.DEV) {
      console.log(`API Request: ${config.method?.toUpperCase()} ${config.url}`)
    }

    return config
  },
  (error: AxiosError) => {
    console.error('Request Error:', error)
    return Promise.reject(error)
  }
)

// Response interceptor
api.interceptors.response.use(
  (response: AxiosResponse) => {
    if (import.meta.env.DEV) {
      console.log(`API Response: ${response.config.method?.toUpperCase()} ${response.config.url}`)
    }

    return response
  },
  (error: AxiosError<ApiErrorResponse>) => {
    if (import.meta.env.DEV) {
      console.error('API Error:', error)
    }

    if (error.response) {
      const { status, data } = error.response

      switch (status) {
        case 400:
          console.error('Bad Request:', data.message || 'Invalid request')
          break
        case 401:
          console.error('Unauthorized:', data.message || 'Please log in')
          break
        case 403:
          console.error('Forbidden:', data.message || 'Access denied')
          break
        case 404:
          console.error('Not Found:', data.message || 'Resource not found')
          break
        case 422:
          console.error('Validation Error:', data.errors || data.message)
          break
        case 500:
          console.error('Server Error:', data.message || 'Internal server error')
          break
        default:
          console.error(`Error ${status}:`, data.message || 'An error occurred')
      }
    } else if (error.request) {
      console.error('Network Error: No response from server')
    } else {
      console.error('Error:', error.message)
    }

    return Promise.reject(error)
  }
)

export function handleApiError(error: AxiosError): ApiError {
  if (error.response) {
    const data = error.response.data as ApiErrorResponse | undefined
    return {
      message: data?.message || 'An error occurred',
      errors: data?.errors || null,
      status: error.response.status,
    }
  } else if (error.request) {
    return {
      message: 'Network error. Please check your connection.',
      errors: null,
      status: null,
    }
  } else {
    return {
      message: error.message || 'An unexpected error occurred',
      errors: null,
      status: null,
    }
  }
}

export function extractData<T>(response: AxiosResponse<T>): T {
  return response.data
}

export default api
