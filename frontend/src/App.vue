<script setup lang="ts">
/**
 * ============================================================================
 * App.vue - Root Component
 * ============================================================================
 * This is the root component of the Vue.js application.
 * It provides the main layout structure and manages global application state.
 * ============================================================================
 */

import { RouterView } from 'vue-router'
import { onMounted } from 'vue'

/**
 * Initialize application on mount
 */
onMounted(() => {
  document.documentElement.classList.add('smooth-scroll')
})
</script>

<template>
  <div id="app" class="min-h-screen bg-gray-50 dark:bg-gray-900">
    <!-- Router View - Main Content -->
    <RouterView />
  </div>
</template>

<style scoped>
/**
 * Component-specific styles
 * Using scoped to prevent style leakage
 */

#app {
  /* Ensure app takes full viewport height */
  min-height: 100vh;

  /* Enable smooth font rendering */
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
</style>
