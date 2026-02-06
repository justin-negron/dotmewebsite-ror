import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'

import './assets/styles/main.css'

const app = createApp(App)

const pinia = createPinia()

app.use(pinia)
app.use(router)

app.config.errorHandler = (err, instance, info) => {
  if (import.meta.env.DEV) {
    console.error('Global error:', err)
    console.error('Component:', instance)
    console.error('Error info:', info)
  }
}

if (import.meta.env.DEV) {
  app.config.warnHandler = (msg, instance, trace) => {
    console.warn('Global warning:', msg)
    console.warn('Component:', instance)
    console.warn('Trace:', trace)
  }
}

if (import.meta.env.DEV) {
  app.config.performance = true
}

app.mount('#app')

if (import.meta.env.DEV) {
  console.log(`Portfolio App v${import.meta.env.VITE_APP_VERSION || '1.0.0'}`)
  console.log(`Environment: ${import.meta.env.MODE}`)
  console.log(`API Base URL: ${import.meta.env.VITE_API_BASE_URL}`)
}
