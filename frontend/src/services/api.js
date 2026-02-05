/**
 * ============================================================================
 * API Service - Base Configuration
 * ============================================================================
 * This file sets up the base Axios instance with:
 * - Base URL configuration
 * - Request/response interceptors
 * - Error handling
 * - Loading state management
 * ============================================================================
 */

import axios from 'axios'

/**
 * Create Axios instance with base configuration
 */
const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000',
  timeout: parseInt(import.meta.env.VITE_API_TIMEOUT || '30000', 10),
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
})

/**
 * Request Interceptor
 * Runs before every request is sent
 */
api.interceptors.request.use(
  (config) => {
    // Add timestamp to prevent caching (optional)
    if (config.method === 'get') {
      config.params = {
        ...config.params,
        _t: Date.now(),
      }
    }

    // Log request in development
    if (import.meta.env.DEV) {
      console.log(`🚀 API Request: ${config.method.toUpperCase()} ${config.url}`)
    }

    // Future: Add auth token here
    // const token = localStorage.getItem('auth_token')
    // if (token) {
    //   config.headers.Authorization = `Bearer ${token}`
    // }

    return config
  },
  (error) => {
    // Handle request errors
    console.error('❌ Request Error:', error)
    return Promise.reject(error)
  }
)

/**
 * Response Interceptor
 * Runs after every response is received
 */
api.interceptors.response.use(
  (response) => {
    // Log response in development
    if (import.meta.env.DEV) {
      console.log(`✅ API Response: ${response.config.method.toUpperCase()} ${response.config.url}`)
    }

    return response
  },
  (error) => {
    // Handle response errors
    if (import.meta.env.DEV) {
      console.error('❌ API Error:', error)
    }

    // Handle specific error cases
    if (error.response) {
      // Server responded with error status
      const { status, data } = error.response

      switch (status) {
        case 400:
          console.error('Bad Request:', data.message || 'Invalid request')
          break
        case 401:
          console.error('Unauthorized:', data.message || 'Please log in')
          // Future: Redirect to login
          // window.location.href = '/login'
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
      // Request made but no response received
      console.error('Network Error: No response from server')
    } else {
      // Something else happened
      console.error('Error:', error.message)
    }

    return Promise.reject(error)
  }
)

/**
 * Helper function to handle API errors consistently
 */
export const handleApiError = (error) => {
  if (error.response) {
    // Server responded with error
    return {
      message: error.response.data.message || 'An error occurred',
      errors: error.response.data.errors || null,
      status: error.response.status,
    }
  } else if (error.request) {
    // No response received
    return {
      message: 'Network error. Please check your connection.',
      errors: null,
      status: null,
    }
  } else {
    // Other errors
    return {
      message: error.message || 'An unexpected error occurred',
      errors: null,
      status: null,
    }
  }
}

/**
 * Helper function to extract data from response
 */
export const extractData = (response) => response.data

export default api
