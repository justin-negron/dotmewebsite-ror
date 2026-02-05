/**
 * ============================================================================
 * API Services - Central Export
 * ============================================================================
 * This file exports all API services for easy importing
 * ============================================================================
 */

// Export individual services
export { default as projectsApi } from './projects'
export { default as experiencesApi } from './experiences'
export { default as blogApi } from './blog'
export { default as contactsApi } from './contacts'
export { default as analyticsApi } from './analytics'

// Export base API instance
export { default as api } from './api'

// Export utility functions
export { handleApiError, extractData } from './api'

/**
 * Usage examples:
 *
 * // Import specific service
 * import { projectsApi } from '@/services'
 * const projects = await projectsApi.getProjects()
 *
 * // Import specific function
 * import { getProjects } from '@/services/projects'
 * const projects = await getProjects()
 *
 * // Import base API for custom requests
 * import { api } from '@/services'
 * const response = await api.get('/custom-endpoint')
 */
