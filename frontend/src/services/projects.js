/**
 * ============================================================================
 * Projects API Service
 * ============================================================================
 * Handles all API calls related to projects
 * ============================================================================
 */

import api, { handleApiError, extractData } from './api'

/**
 * Projects API endpoints
 */
const ENDPOINTS = {
  base: '/api/v1/projects',
  detail: (id) => `/api/v1/projects/${id}`,
}

/**
 * Get all projects
 * @param {Object} params - Query parameters (optional)
 * @returns {Promise<Array>} Array of projects
 */
export const getProjects = async (params = {}) => {
  try {
    const response = await api.get(ENDPOINTS.base, { params })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Get a single project by ID
 * @param {number|string} id - Project ID
 * @returns {Promise<Object>} Project object
 */
export const getProject = async (id) => {
  try {
    const response = await api.get(ENDPOINTS.detail(id))
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Get featured projects
 * @returns {Promise<Array>} Array of featured projects
 */
export const getFeaturedProjects = async () => {
  try {
    const response = await api.get(ENDPOINTS.base, {
      params: { featured: true },
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Get projects by technology
 * @param {string} technology - Technology name
 * @returns {Promise<Array>} Array of projects
 */
export const getProjectsByTechnology = async (technology) => {
  try {
    const response = await api.get(ENDPOINTS.base, {
      params: { technology },
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Future: Create a new project (Admin only)
 * @param {Object} projectData - Project data
 * @returns {Promise<Object>} Created project
 */
export const createProject = async (projectData) => {
  try {
    const response = await api.post(ENDPOINTS.base, projectData)
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Future: Update a project (Admin only)
 * @param {number|string} id - Project ID
 * @param {Object} projectData - Updated project data
 * @returns {Promise<Object>} Updated project
 */
export const updateProject = async (id, projectData) => {
  try {
    const response = await api.put(ENDPOINTS.detail(id), projectData)
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Future: Delete a project (Admin only)
 * @param {number|string} id - Project ID
 * @returns {Promise<void>}
 */
export const deleteProject = async (id) => {
  try {
    await api.delete(ENDPOINTS.detail(id))
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Export all functions as a single object (alternative usage)
 */
export default {
  getProjects,
  getProject,
  getFeaturedProjects,
  getProjectsByTechnology,
  createProject,
  updateProject,
  deleteProject,
}
