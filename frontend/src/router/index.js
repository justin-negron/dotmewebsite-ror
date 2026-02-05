/**
 * ============================================================================
 * Vue Router Configuration - Simplified (Step 12)
 * ============================================================================
 * This router only includes views that currently exist.
 * We'll add more routes as we create the views in later steps.
 * ============================================================================
 */

import { createRouter, createWebHistory } from 'vue-router'

/**
 * Route Definitions
 * Only includes existing views for now
 */
const routes = [
  {
    path: '/',
    name: 'home',
    component: () => import('@/views/HomeView.vue'),
    meta: {
      title: 'Home',
      description: 'Welcome to my portfolio',
      requiresAuth: false,
    },
  },
  {
    path: '/about',
    name: 'about',
    component: () => import('@/views/AboutView.vue'),
    meta: {
      title: 'About',
      description: 'Learn more about me',
      requiresAuth: false,
    },
  },
  // 404 Not Found
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    component: () => import('@/views/HomeView.vue'), // Temporary: use HomeView
    meta: {
      title: '404 - Not Found',
      description: 'Page not found',
      requiresAuth: false,
    },
  },
]

/**
 * Create Router Instance
 */
const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
  
  /**
   * Scroll Behavior
   */
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    }
    
    if (to.hash) {
      return {
        el: to.hash,
        behavior: 'smooth',
        top: 80,
      }
    }
    
    return { top: 0, behavior: 'smooth' }
  },
})

/**
 * Global Before Guard
 */
router.beforeEach((to, from, next) => {
  // Update document title
  const baseTitle = import.meta.env.VITE_APP_TITLE || 'Portfolio'
  document.title = to.meta.title ? `${to.meta.title} | ${baseTitle}` : baseTitle
  
  // Update meta description
  const metaDescription = document.querySelector('meta[name="description"]')
  if (metaDescription && to.meta.description) {
    metaDescription.setAttribute('content', to.meta.description)
  }
  
  next()
})

/**
 * Global After Hook
 */
router.afterEach((to, from) => {
  // Log navigation in development
  if (import.meta.env.DEV) {
    console.log(`Navigation: ${from.path} → ${to.path}`)
  }
})

/**
 * Error Handler
 */
router.onError((error) => {
  console.error('Router error:', error)
})

export default router