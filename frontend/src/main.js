/**
 * ============================================================================
 * Main Entry Point - Vue.js Application
 * ============================================================================
 * This is the main entry point for the Vue.js application.
 * It sets up the Vue app, router, state management, and global configurations.
 * ============================================================================
 */

import { createApp } from '../node_modules/vue'
import { createPinia } from '../node_modules/pinia'

import App from './App.vue'
import router from './router'

// Import global styles
import './assets/styles/main.css'

// Create Vue app instance
const app = createApp(App)

// Create Pinia instance (state management)
const pinia = createPinia()

// Use plugins
app.use(pinia)
app.use(router)

// Global error handler
app.config.errorHandler = (err, instance, info) => {
  // Log error to console in development
  if (import.meta.env.DEV) {
    console.error('Global error:', err)
    console.error('Component:', instance)
    console.error('Error info:', info)
  }

  // In production, you might want to send this to an error tracking service
  // Example: Sentry, LogRocket, etc.
  if (import.meta.env.PROD) {
    // TODO: Send to error tracking service
  }
}

// Global warning handler (development only)
if (import.meta.env.DEV) {
  app.config.warnHandler = (msg, instance, trace) => {
    console.warn('Global warning:', msg)
    console.warn('Component:', instance)
    console.warn('Trace:', trace)
  }
}

// Performance monitoring (development only)
if (import.meta.env.DEV) {
  app.config.performance = true
}

// Mount the app
app.mount('#app')

// Log app version in development
if (import.meta.env.DEV) {
  console.log(`🚀 Portfolio App v${import.meta.env.VITE_APP_VERSION || '1.0.0'}`)
  console.log(`📦 Environment: ${import.meta.env.MODE}`)
  console.log(`🔗 API Base URL: ${import.meta.env.VITE_API_BASE_URL}`)
}
