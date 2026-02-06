import api, { handleApiError, extractData } from './api'
import type { ApiSuccessResponse, AnalyticsStats, PageView, PageViewData } from '@/types'

const ENDPOINTS = {
  base: '/api/v1/analytics',
  pageViews: '/api/v1/analytics/page_views',
  stats: '/api/v1/analytics/stats',
}

export async function trackPageView(data: PageViewData) {
  try {
    const pageViewData = {
      path: data.path,
      referrer: data.referrer || document.referrer || null,
      user_agent: data.user_agent || navigator.userAgent || null,
    }

    const response = await api.post<ApiSuccessResponse<PageView>>(ENDPOINTS.pageViews, pageViewData)
    return extractData(response)
  } catch (error) {
    // Silently fail for analytics - don't break user experience
    if (import.meta.env.DEV) {
      console.warn('Analytics tracking failed:', error)
    }
    return null
  }
}

export async function getStats(params: Record<string, unknown> = {}) {
  try {
    const response = await api.get<ApiSuccessResponse<AnalyticsStats>>(ENDPOINTS.stats, { params })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function getPageViews(path: string, params: Record<string, unknown> = {}) {
  try {
    const response = await api.get<ApiSuccessResponse<PageView[]>>(ENDPOINTS.pageViews, {
      params: { ...params, path },
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export async function getTotalPageViews() {
  try {
    const stats = await getStats()
    return stats.data.total_page_views || 0
  } catch (error) {
    if (import.meta.env.DEV) {
      console.warn('Failed to get total page views:', error)
    }
    return 0
  }
}

export async function getPopularPages(limit: number = 10) {
  try {
    const response = await api.get<ApiSuccessResponse<PageView[]>>(ENDPOINTS.pageViews, {
      params: { limit, sort: 'views' },
    })
    return extractData(response)
  } catch (error) {
    throw handleApiError(error as import('axios').AxiosError)
  }
}

export default {
  trackPageView,
  getStats,
  getPageViews,
  getTotalPageViews,
  getPopularPages,
}
