import axios from 'axios'
import type { AxiosError, AxiosResponse, InternalAxiosRequestConfig } from 'axios'
import type { ApiError, ApiErrorResponse } from '@/types'

// Auth token getter — set by the app after Pinia is initialized.
// Avoids circular dependency between api.ts and auth store.
let getAuthToken: (() => string | null) | null = null

export function setAuthTokenGetter(getter: () => string | null) {
  getAuthToken = getter
}

// Flag to prevent refresh loops
let isRefreshing = false
let refreshPromise: Promise<boolean> | null = null

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

    // Inject auth header if token exists
    if (getAuthToken) {
      const token = getAuthToken()
      if (token) {
        config.headers.Authorization = `Bearer ${token}`
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
  async (error: AxiosError<ApiErrorResponse>) => {
    if (import.meta.env.DEV) {
      console.error('API Error:', error)
    }

    const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean }

    // Auto-refresh on 401 — skip for auth endpoints and already-retried requests
    if (
      error.response?.status === 401 &&
      !originalRequest?._retry &&
      !originalRequest?.url?.includes('/admin/auth/')
    ) {
      originalRequest._retry = true

      // Deduplicate concurrent refresh calls
      if (!isRefreshing) {
        isRefreshing = true
        refreshPromise = import('@/stores/auth')
          .then(({ useAuthStore }) => {
            const authStore = useAuthStore()
            return authStore.refresh()
          })
          .finally(() => {
            isRefreshing = false
            // Keep refreshPromise alive until all queued requests read it;
            // clear it on next tick so late arrivals start a fresh cycle.
            setTimeout(() => {
              refreshPromise = null
            }, 0)
          })
      }

      try {
        const success = await refreshPromise
        if (success && originalRequest) {
          // Retry with new token
          const token = getAuthToken?.()
          if (token) {
            originalRequest.headers.Authorization = `Bearer ${token}`
          }
          return api(originalRequest)
        }
      } catch {
        // Refresh failed — fall through to normal error handling
      }
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
