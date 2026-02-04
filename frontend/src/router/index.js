/**
 * ============================================================================
 * Vue Router Configuration - Enterprise Grade
 * ============================================================================
 * This file configures Vue Router with:
 * - Route definitions
 * - Navigation guards
 * - Meta information for SEO
 * - Lazy loading for code splitting
 * - Scroll behavior management
 * ============================================================================
 */

import { createRouter, createWebHistory } from '../../node_modules_backup/vue-router'

/**
 * Route Definitions
 * Using lazy loading for optimal code splitting
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
    path: '/projects',
    name: 'projects',
    component: () => import('@/views/ProjectsView.vue'),
    meta: {
      title: 'Projects',
      description: 'View my portfolio projects',
      requiresAuth: false,
    },
  },
  {
    path: '/projects/:id',
    name: 'project-detail',
    component: () => import('@/views/ProjectDetailView.vue'),
    meta: {
      title: 'Project Details',
      description: 'Project details and information',
      requiresAuth: false,
    },
  },
  {
    path: '/experience',
    name: 'experience',
    component: () => import('@/views/ExperienceView.vue'),
    meta: {
      title: 'Experience',
      description: 'My professional experience',
      requiresAuth: false,
    },
  },
  {
    path: '/blog',
    name: 'blog',
    component: () => import('@/views/BlogView.vue'),
    meta: {
      title: 'Blog',
      description: 'Read my latest blog posts',
      requiresAuth: false,
    },
  },
  {
    path: '/blog/:slug',
    name: 'blog-post',
    component: () => import('@/views/BlogPostView.vue'),
    meta: {
      title: 'Blog Post',
      description: 'Read the full blog post',
      requiresAuth: false,
    },
  },
  {
    path: '/contact',
    name: 'contact',
    component: () => import('@/views/ContactView.vue'),
    meta: {
      title: 'Contact',
      description: 'Get in touch with me',
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
    component: () => import('@/views/NotFoundView.vue'),
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
   * Controls scroll position on route navigation
   */
  scrollBehavior(to, from, savedPosition) {
    // If there's a saved position (browser back/forward), use it
    if (savedPosition) {
      return savedPosition
    }
    
    // If navigating to a hash anchor
    if (to.hash) {
      return {
        el: to.hash,
        behavior: 'smooth',
        top: 80, // Offset for fixed header
      }
    }
    
    // Default: scroll to top
    return { top: 0, behavior: 'smooth' }
  },
})

/**
 * Global Before Guard
 * Runs before every route navigation
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
  
  // Authentication check (will be implemented later)
  if (to.meta.requiresAuth) {
    // TODO: Check authentication status
    // For now, allow all routes
    next()
  } else {
    next()
  }
})

/**
 * Global After Hook
 * Runs after every route navigation
 */
router.afterEach((to, from) => {
  // Track page view (will be implemented in Step 21)
  // trackPageView(to.path)
  
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
  
  // In production, you might want to redirect to an error page
  // or send the error to a tracking service
})

export default router
