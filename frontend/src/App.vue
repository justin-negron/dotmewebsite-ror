<script setup lang="ts">
import { RouterView } from 'vue-router'
import { onMounted } from 'vue'
import AppHeader from '@/components/layout/AppHeader.vue'
import MobileMenu from '@/components/layout/MobileMenu.vue'
import AppFooter from '@/components/layout/AppFooter.vue'
import FloatingTerminal from '@/components/terminal/FloatingTerminal.vue'
import ToastContainer from '@/components/layout/ToastContainer.vue'
import { useTheme } from '@/composables/useTheme'
import { useAppearance } from '@/composables/useAppearance'

// Initialize theme globally (applies .dark class to <html>)
useTheme()

// Initialize appearance (applies skin CSS variables to <html>)
useAppearance()

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
    <FloatingTerminal />
    <ToastContainer />
  </div>
</template>

<style scoped>
#app {
  position: relative;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
</style>
