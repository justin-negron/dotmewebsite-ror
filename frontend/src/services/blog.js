/**
 * ============================================================================
 * Blog API Service
 * ============================================================================
 * Handles all API calls related to blog posts
 * ============================================================================
 */

import api, { handleApiError, extractData } from './api'

/**
 * Blog API endpoints
 */
const ENDPOINTS = {
  base: '/api/v1/blog_posts',
  detail: (slug) => `/api/v1/blog_posts/${slug}`,
}

/**
 * Get all blog posts
 * @param {Object} params - Query parameters (optional)
 * @returns {Promise<Array>} Array of blog posts
 */
export const getBlogPosts = async (params = {}) => {
  try {
    const response = await api.get(ENDPOINTS.base, { params })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Get a single blog post by slug
 * @param {string} slug - Blog post slug
 * @returns {Promise<Object>} Blog post object
 */
export const getBlogPost = async (slug) => {
  try {
    const response = await api.get(ENDPOINTS.detail(slug))
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Get published blog posts
 * @param {Object} params - Query parameters (optional)
 * @returns {Promise<Array>} Array of published blog posts
 */
export const getPublishedPosts = async (params = {}) => {
  try {
    const response = await api.get(ENDPOINTS.base, {
      params: { ...params, published: true },
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Get blog posts by tag
 * @param {string} tag - Tag name
 * @returns {Promise<Array>} Array of blog posts
 */
export const getPostsByTag = async (tag) => {
  try {
    const response = await api.get(ENDPOINTS.base, {
      params: { tag },
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Get recent blog posts
 * @param {number} limit - Number of posts to return (default: 5)
 * @returns {Promise<Array>} Array of recent blog posts
 */
export const getRecentPosts = async (limit = 5) => {
  try {
    const response = await api.get(ENDPOINTS.base, {
      params: { published: true, limit },
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Increment view count for a blog post
 * @param {string} slug - Blog post slug
 * @returns {Promise<Object>} Updated blog post
 */
export const incrementViewCount = async (slug) => {
  try {
    const response = await api.post(`${ENDPOINTS.detail(slug)}/increment_views`)
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Future: Create a new blog post (Admin only)
 * @param {Object} postData - Blog post data
 * @returns {Promise<Object>} Created blog post
 */
export const createBlogPost = async (postData) => {
  try {
    const response = await api.post(ENDPOINTS.base, postData)
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Future: Update a blog post (Admin only)
 * @param {string} slug - Blog post slug
 * @param {Object} postData - Updated blog post data
 * @returns {Promise<Object>} Updated blog post
 */
export const updateBlogPost = async (slug, postData) => {
  try {
    const response = await api.put(ENDPOINTS.detail(slug), postData)
    return extractData(response)
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Future: Delete a blog post (Admin only)
 * @param {string} slug - Blog post slug
 * @returns {Promise<void>}
 */
export const deleteBlogPost = async (slug) => {
  try {
    await api.delete(ENDPOINTS.detail(slug))
  } catch (error) {
    throw handleApiError(error)
  }
}

/**
 * Export all functions as a single object (alternative usage)
 */
export default {
  getBlogPosts,
  getBlogPost,
  getPublishedPosts,
  getPostsByTag,
  getRecentPosts,
  incrementViewCount,
  createBlogPost,
  updateBlogPost,
  deleteBlogPost,
}
