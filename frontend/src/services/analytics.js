/**
 * ============================================================================
 * Analytics API Service
 * ============================================================================
 * Handles page view tracking and analytics
 * ============================================================================
 */

import api, { handleApiError, extractData } from './api'

/**
 * Analytics API endpoints
 */
const ENDPOINTS = {
  base: '/api/v1/analytics',
  pageViews: '/api/v1/analytics/page_views',
  stats: '/api/v1/analytics/stats',
}

/**
 * Track a page view
 * @param {Object} data - Page view data
 * @param {string} data.path - Page path (e.g., '/projects/1')
 * @param {string} data.referrer - Referrer URL (optional)
 * @param {string} data.user_agent - User agent string (optional)
 * @returns {Promise<Object>} Created page view record
 */
export const trackPageView = async (data) => {
  try {
    const pageViewData = {
      path: data.path,
      referrer: data.referrer || document.referrer || null,
      user_agent: data.user_agent || navigator.userAgent || null,
    }

    const response = await api.post(ENDPOINTS.pageViews, pageViewData)
    return extractData(response)
  } catch (error) {
    // Silently fail for analytics - don't break user experience
    if (import.meta.env.DEV) {
      console.warn('Analytics tracking failed:', error)
    }
    return null
  }
}

/**
 * Get analytics statistics (Admin only)
 * @param {Object} params - Query parameters
 * @param {string} params.start_date - Start date (optional)
 * @param {string} params.end_date - End date (optional)
 * @returns {Promise<Object>} Analytics statistics
 */
export const getStats = async (params = {}) => {
  try {
    const response = await api.get(ENDPOINTS.stats, { params })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Get page views for a specific path (Admin only)
 * @param {string} path - Page path
 * @param {Object} params - Query parameters (optional)
 * @returns {Promise<Array>} Array of page views
 */
export const getPageViews = async (path, params = {}) => {
  try {
    const response = await api.get(ENDPOINTS.pageViews, {
      params: { ...params, path },
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Get total page views count
 * @returns {Promise<number>} Total page views
 */
export const getTotalPageViews = async () => {
  try {
    const stats = await getStats()
    return stats.total_page_views || 0
  } catch (error) {
    if (import.meta.env.DEV) {
      console.warn('Failed to get total page views:', error)
    }
    return 0
  }
}

/**
 * Get most popular pages (Admin only)
 * @param {number} limit - Number of pages to return (default: 10)
 * @returns {Promise<Array>} Array of popular pages
 */
export const getPopularPages = async (limit = 10) => {
  try {
    const response = await api.get(ENDPOINTS.pageViews, {
      params: { limit, sort: 'views' },
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Export all functions as a single object (alternative usage)
 */
export default {
  trackPageView,
  getStats,
  getPageViews,
  getTotalPageViews,
  getPopularPages,
}
