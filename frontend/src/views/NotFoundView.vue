<script setup lang="ts">
import { useRouter } from 'vue-router'

const router = useRouter()

function goHome() {
  router.push('/')
}
</script>

<template>
  <div class="flex min-h-[60vh] items-center justify-center px-4">
    <div class="text-center">
      <p class="text-5xl sm:text-7xl font-bold text-primary-500 mb-4">404</p>
      <h1 class="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-2">Page Not Found</h1>
      <p class="text-gray-600 dark:text-gray-400 mb-8">
        The page you're looking for doesn't exist or has been moved.
      </p>
      <button class="btn btn-primary" @click="goHome">Go Home</button>
    </div>
  </div>
</template>
