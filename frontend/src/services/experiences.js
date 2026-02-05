/**
 * ============================================================================
 * Experiences API Service
 * ============================================================================
 * Handles all API calls related to work experiences
 * ============================================================================
 */

import api, { handleApiError, extractData } from './api'

/**
 * Experiences API endpoints
 */
const ENDPOINTS = {
  base: '/api/v1/experiences',
  detail: (id) => `/api/v1/experiences/${id}`,
}

/**
 * Get all experiences
 * @param {Object} params - Query parameters (optional)
 * @returns {Promise<Array>} Array of experiences
 */
export const getExperiences = async (params = {}) => {
  try {
    const response = await api.get(ENDPOINTS.base, { params })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Get a single experience by ID
 * @param {number|string} id - Experience ID
 * @returns {Promise<Object>} Experience object
 */
export const getExperience = async (id) => {
  try {
    const response = await api.get(ENDPOINTS.detail(id))
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Get current experience
 * @returns {Promise<Object|null>} Current experience or null
 */
export const getCurrentExperience = async () => {
  try {
    const response = await api.get(ENDPOINTS.base, {
      params: { current: true },
    })
    const data = extractData(response)
    return data.length > 0 ? data[0] : null
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Future: Create a new experience (Admin only)
 * @param {Object} experienceData - Experience data
 * @returns {Promise<Object>} Created experience
 */
export const createExperience = async (experienceData) => {
  try {
    const response = await api.post(ENDPOINTS.base, experienceData)
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Future: Update an experience (Admin only)
 * @param {number|string} id - Experience ID
 * @param {Object} experienceData - Updated experience data
 * @returns {Promise<Object>} Updated experience
 */
export const updateExperience = async (id, experienceData) => {
  try {
    const response = await api.put(ENDPOINTS.detail(id), experienceData)
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Future: Delete an experience (Admin only)
 * @param {number|string} id - Experience ID
 * @returns {Promise<void>}
 */
export const deleteExperience = async (id) => {
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
  getExperiences,
  getExperience,
  getCurrentExperience,
  createExperience,
  updateExperience,
  deleteExperience,
}
