<script setup lang="ts">
import { RouterView } from 'vue-router'
import { onMounted } from 'vue'
import AppHeader from '@/components/layout/AppHeader.vue'
import MobileMenu from '@/components/layout/MobileMenu.vue'
import AppFooter from '@/components/layout/AppFooter.vue'
import ToastContainer from '@/components/layout/ToastContainer.vue'

onMounted(() => {
  document.documentElement.classList.add('smooth-scroll')
})
</script>

<template>
  <div id="app" class="flex min-h-screen flex-col bg-gray-50 dark:bg-gray-900">
    <AppHeader />
    <MobileMenu />

    <main class="flex-1">
      <RouterView />
    </main>

    <AppFooter />
    <ToastContainer />
  </div>
</template>

<style scoped>
#app {
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
</style>
