<script setup>
/**
 * ============================================================================
 * HomeView.vue - Home Page View
 * ============================================================================
 * Temporary home page to verify setup is working.
 * This will be replaced with the actual home page in later steps.
 * ============================================================================
 */

import { ref } from 'vue'

const message = ref('Vue.js 3 + Vite + Tailwind CSS')
const isSetupComplete = ref(true)
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary-50 to-secondary-50 dark:from-gray-900 dark:to-gray-800">
    <div class="max-w-4xl mx-auto px-4 text-center">
      <!-- Success Icon -->
      <div class="mb-8">
        <div class="inline-flex items-center justify-center w-24 h-24 bg-success-100 dark:bg-success-900 rounded-full">
          <svg
            class="w-12 h-12 text-success-600 dark:text-success-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M5 13l4 4L19 7"
            />
          </svg>
        </div>
      </div>

      <!-- Title -->
      <h1 class="text-6xl font-bold mb-4 text-gradient">
        {{ message }}
      </h1>

      <!-- Subtitle -->
      <p class="text-xl text-gray-600 dark:text-gray-300 mb-8">
        Step 11: Frontend Setup Complete! 🎉
      </p>

      <!-- Status Badge -->
      <div v-if="isSetupComplete" class="inline-flex items-center gap-2 px-6 py-3 bg-white dark:bg-gray-800 rounded-full shadow-lg mb-12">
        <span class="w-3 h-3 bg-success-500 rounded-full animate-pulse" />
        <span class="text-gray-700 dark:text-gray-300 font-medium">
          All systems operational
        </span>
      </div>

      <!-- Feature List -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
        <div class="card p-6 hover:shadow-xl transition-shadow">
          <div class="w-12 h-12 bg-primary-100 dark:bg-primary-900 rounded-lg flex items-center justify-center mb-4 mx-auto">
            <svg class="w-6 h-6 text-primary-600 dark:text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
          </div>
          <h3 class="text-lg font-semibold mb-2">Lightning Fast</h3>
          <p class="text-gray-600 dark:text-gray-400">
            Powered by Vite for instant hot module replacement
          </p>
        </div>

        <div class="card p-6 hover:shadow-xl transition-shadow">
          <div class="w-12 h-12 bg-secondary-100 dark:bg-secondary-900 rounded-lg flex items-center justify-center mb-4 mx-auto">
            <svg class="w-6 h-6 text-secondary-600 dark:text-secondary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
            </svg>
          </div>
          <h3 class="text-lg font-semibold mb-2">Beautiful Design</h3>
          <p class="text-gray-600 dark:text-gray-400">
            Styled with Tailwind CSS utility classes
          </p>
        </div>

        <div class="card p-6 hover:shadow-xl transition-shadow">
          <div class="w-12 h-12 bg-success-100 dark:bg-success-900 rounded-lg flex items-center justify-center mb-4 mx-auto">
            <svg class="w-6 h-6 text-success-600 dark:text-success-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h3 class="text-lg font-semibold mb-2">Production Ready</h3>
          <p class="text-gray-600 dark:text-gray-400">
            ESLint, Prettier, and enterprise-grade setup
          </p>
        </div>
      </div>

      <!-- Next Steps -->
      <div class="card p-8 text-left max-w-2xl mx-auto">
        <h2 class="text-2xl font-bold mb-4">Next Steps</h2>
        <ul class="space-y-3">
          <li class="flex items-start gap-3">
            <span class="badge-primary mt-1">1</span>
            <span class="text-gray-700 dark:text-gray-300">
              Set up API service layer to connect with Rails backend
            </span>
          </li>
          <li class="flex items-start gap-3">
            <span class="badge-primary mt-1">2</span>
            <span class="text-gray-700 dark:text-gray-300">
              Configure Pinia stores for state management
            </span>
          </li>
          <li class="flex items-start gap-3">
            <span class="badge-primary mt-1">3</span>
            <span class="text-gray-700 dark:text-gray-300">
              Create layout components (Header, Footer, Navigation)
            </span>
          </li>
          <li class="flex items-start gap-3">
            <span class="badge-primary mt-1">4</span>
            <span class="text-gray-700 dark:text-gray-300">
              Build home page with hero section
            </span>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
