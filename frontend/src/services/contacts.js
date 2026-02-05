/**
 * ============================================================================
 * Contacts API Service
 * ============================================================================
 * Handles contact form submissions
 * ============================================================================
 */

import api, { handleApiError, extractData } from './api'

/**
 * Contacts API endpoints
 */
const ENDPOINTS = {
  base: '/api/v1/contacts',
  detail: (id) => `/api/v1/contacts/${id}`,
}

/**
 * Submit contact form
 * @param {Object} contactData - Contact form data
 * @param {string} contactData.name - Sender's name
 * @param {string} contactData.email - Sender's email
 * @param {string} contactData.subject - Message subject (optional)
 * @param {string} contactData.message - Message content
 * @returns {Promise<Object>} Created contact record
 */
export const submitContactForm = async (contactData) => {
  try {
    const response = await api.post(ENDPOINTS.base, contactData)
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Future: Get all contact submissions (Admin only)
 * @param {Object} params - Query parameters (optional)
 * @returns {Promise<Array>} Array of contact submissions
 */
export const getContacts = async (params = {}) => {
  try {
    const response = await api.get(ENDPOINTS.base, { params })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Future: Get a single contact submission (Admin only)
 * @param {number|string} id - Contact ID
 * @returns {Promise<Object>} Contact object
 */
export const getContact = async (id) => {
  try {
    const response = await api.get(ENDPOINTS.detail(id))
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Future: Mark contact as read (Admin only)
 * @param {number|string} id - Contact ID
 * @returns {Promise<Object>} Updated contact
 */
export const markAsRead = async (id) => {
  try {
    const response = await api.patch(`${ENDPOINTS.detail(id)}/mark_read`)
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Future: Delete a contact submission (Admin only)
 * @param {number|string} id - Contact ID
 * @returns {Promise<void>}
 */
export const deleteContact = async (id) => {
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
  submitContactForm,
  getContacts,
  getContact,
  markAsRead,
  deleteContact,
}
