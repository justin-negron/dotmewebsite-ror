import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import { trackPageView } from '@/services/analytics'
import { updateHead } from '@/composables/useHead'

declare module 'vue-router' {
  interface RouteMeta {
    title?: string
    description?: string
    requiresAuth?: boolean
    noAnalytics?: boolean
  }
}

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'home',
    component: () => import('@/views/HomeView.vue'),
    meta: {
      title: 'Portfolio',
      description:
        'Justin Negron is a full-stack software engineer specializing in Ruby on Rails and Vue.js. Explore my projects, work experience, technical blog, and get in touch.',
      requiresAuth: false,
    },
  },
  {
    path: '/about',
    name: 'about',
    component: () => import('@/views/AboutView.vue'),
    meta: {
      title: 'About',
      description: 'Learn more about Justin Negron — background, skills, and what I love building.',
      requiresAuth: false,
    },
  },
  {
    path: '/blog',
    name: 'blog',
    component: () => import('@/views/BlogView.vue'),
    meta: {
      title: 'Blog',
      description: 'Thoughts on software engineering, deep-dives, and lessons from building real systems.',
      requiresAuth: false,
    },
  },
  {
    path: '/blog/:slug',
    name: 'blog-post',
    component: () => import('@/views/BlogPostView.vue'),
    meta: {
      title: 'Blog Post',
      description: 'Read the full article',
      requiresAuth: false,
    },
  },
  {
    path: '/admin/login',
    name: 'admin-login',
    component: () => import('@/views/admin/AdminLoginView.vue'),
    meta: {
      title: 'Admin Login',
      description: 'Admin login',
      requiresAuth: false,
      noAnalytics: true,
    },
  },
  {
    path: '/admin',
    component: () => import('@/layouts/AdminLayout.vue'),
    meta: {
      requiresAuth: true,
      noAnalytics: true,
    },
    children: [
      {
        path: '',
        name: 'admin-dashboard',
        component: () => import('@/views/admin/AdminDashboardView.vue'),
        meta: { title: 'Admin Dashboard' },
      },
      {
        path: 'projects',
        name: 'admin-projects',
        component: () => import('@/views/admin/AdminProjectsView.vue'),
        meta: { title: 'Admin Projects' },
      },
      {
        path: 'projects/new',
        name: 'admin-project-new',
        component: () => import('@/views/admin/AdminProjectFormView.vue'),
        meta: { title: 'New Project' },
      },
      {
        path: 'projects/:id/edit',
        name: 'admin-project-edit',
        component: () => import('@/views/admin/AdminProjectFormView.vue'),
        meta: { title: 'Edit Project' },
      },
      {
        path: 'experiences',
        name: 'admin-experiences',
        component: () => import('@/views/admin/AdminExperiencesView.vue'),
        meta: { title: 'Admin Experiences' },
      },
      {
        path: 'experiences/new',
        name: 'admin-experience-new',
        component: () => import('@/views/admin/AdminExperienceFormView.vue'),
        meta: { title: 'New Experience' },
      },
      {
        path: 'experiences/:id/edit',
        name: 'admin-experience-edit',
        component: () => import('@/views/admin/AdminExperienceFormView.vue'),
        meta: { title: 'Edit Experience' },
      },
      {
        path: 'blog',
        name: 'admin-blog',
        component: () => import('@/views/admin/AdminBlogPostsView.vue'),
        meta: { title: 'Admin Blog Posts' },
      },
      {
        path: 'blog/new',
        name: 'admin-blog-new',
        component: () => import('@/views/admin/AdminBlogPostFormView.vue'),
        meta: { title: 'New Blog Post' },
      },
      {
        path: 'blog/:id/edit',
        name: 'admin-blog-edit',
        component: () => import('@/views/admin/AdminBlogPostFormView.vue'),
        meta: { title: 'Edit Blog Post' },
      },
      {
        path: 'contacts',
        name: 'admin-contacts',
        component: () => import('@/views/admin/AdminContactsView.vue'),
        meta: { title: 'Admin Inbox' },
      },
      {
        path: 'contacts/:id',
        name: 'admin-contact-detail',
        component: () => import('@/views/admin/AdminContactDetailView.vue'),
        meta: { title: 'Contact Detail' },
      },
    ],
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    component: () => import('@/views/NotFoundView.vue'),
    meta: {
      title: '404 - Not Found',
      description: 'Page not found',
      requiresAuth: false,
      noAnalytics: true,
    },
  },
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,

  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    }

    if (to.hash) {
      // Cross-route hash nav: delay scroll until the page transition finishes
      // (mode="out-in": 200ms leave + 350ms enter = 550ms; 650ms gives a safe buffer)
      if (from.path !== to.path) {
        return new Promise((resolve) => {
          setTimeout(() => {
            resolve({ el: to.hash, behavior: 'smooth' as const, top: 80 })
          }, 650)
        })
      }
      return { el: to.hash, behavior: 'smooth' as const, top: 80 }
    }

    return { top: 0, behavior: 'smooth' as const }
  },
})

router.beforeEach(async (to, _from, next) => {
  // Blog posts get generic head here; BlogPostView overrides once the post loads.
  updateHead({
    title: (to.meta.title as string) || '',
    description: (to.meta.description as string) || '',
    path: to.path,
    type: to.name === 'blog-post' ? 'article' : 'website',
  })

  if (to.matched.some((r) => r.meta.requiresAuth)) {
    const { useAuthStore } = await import('@/stores/auth')
    const authStore = useAuthStore()

    // Ensure auth is initialized (silent refresh attempt on first load)
    await authStore.initialize()

    if (!authStore.isAuthenticated) {
      return next({ name: 'admin-login', query: { redirect: to.fullPath } })
    }
  }

  next()
})

router.afterEach((to, from) => {
  if (import.meta.env.DEV) {
    console.log(`Navigation: ${from.path} → ${to.path}`)
  }

  const skipAnalytics = to.matched.some((r) => r.meta.noAnalytics)
  if (import.meta.env.VITE_ENABLE_ANALYTICS === 'true' && !skipAnalytics) {
    trackPageView({
      path: to.path,
      referrer: from.matched.length > 0 && from.path !== to.path ? from.path : null,
    })
  }
})

router.onError((error: Error) => {
  console.error('Router error:', error)
})

export default router
