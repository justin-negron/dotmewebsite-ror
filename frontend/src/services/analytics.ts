import api from './api'
import type { ApiSuccessResponse, PageView, PageViewData } from '@/types'

const ENDPOINTS = {
  track: '/api/v1/analytics/track',
}

// ---------------------------------------------------------------------------
// Public tracking — works now
// ---------------------------------------------------------------------------

export async function trackPageView(data: PageViewData) {
  try {
    const pageViewData = {
      path: data.path,
      referrer: data.referrer || document.referrer || null,
      user_agent: data.user_agent || navigator.userAgent || null,
    }

    const response = await api.post<ApiSuccessResponse<PageView>>(ENDPOINTS.track, pageViewData)
    return response.data
  } catch (error) {
    // Silently fail — analytics should never break the user experience
    if (import.meta.env.DEV) {
      console.warn('Analytics tracking failed:', error)
    }
    return null
  }
}

// ---------------------------------------------------------------------------
// Admin analytics reads — implement in Step 27 (admin dashboard)
//
// These endpoints don't exist yet and will require:
//   - JWT auth headers (admin-only routes)
//   - Backend routes: GET /api/v1/admin/analytics/stats
//                     GET /api/v1/admin/analytics/page_views
//                     GET /api/v1/admin/analytics/popular
//   - Functions: getStats(), getPageViews(path), getPopularPages(limit),
//                getTotalPageViews()
// ---------------------------------------------------------------------------

export default {
  trackPageView,
}
