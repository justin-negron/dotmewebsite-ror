<script setup lang="ts">
import { RouterView, useRoute } from 'vue-router'
import { onMounted } from 'vue'
import AppHeader from '@/components/layout/AppHeader.vue'
import MobileMenu from '@/components/layout/MobileMenu.vue'
import AppFooter from '@/components/layout/AppFooter.vue'
import FloatingTerminal from '@/components/terminal/FloatingTerminal.vue'
import ToastContainer from '@/components/layout/ToastContainer.vue'
import { useTheme } from '@/composables/useTheme'
import { useAppearance } from '@/composables/useAppearance'

const route = useRoute()

// Initialize theme globally (applies .dark class to <html>)
useTheme()

// Initialize appearance (applies skin CSS variables to <html>)
useAppearance()

onMounted(() => {
  document.documentElement.classList.add('smooth-scroll')
})

// ── Page transition JS hooks (:css="false") ───────────────────────────────
// CSS-based transitions snap back to opacity: 1 for ~1 frame when Vue removes
// the leave-active class before DOM removal. JS hooks set opacity via inline
// style, which persists right up until done() triggers DOM removal — no snap.

function onPageEnter(el: Element, done: () => void) {
  const htmlEl = el as HTMLElement
  htmlEl.style.opacity = '0'
  htmlEl.style.transform = 'translateY(10px)'
  // Two rAFs: first commits the initial state to layout, second triggers the
  // transition by changing to the target values in a subsequent paint frame.
  requestAnimationFrame(() => {
    htmlEl.style.transition =
      'opacity 0.35s cubic-bezier(0.16, 1, 0.3, 1), transform 0.35s cubic-bezier(0.16, 1, 0.3, 1)'
    requestAnimationFrame(() => {
      htmlEl.style.opacity = '1'
      htmlEl.style.transform = 'translateY(0)'
    })
  })
  setTimeout(done, 350)
}

function onPageLeave(el: Element, done: () => void) {
  const htmlEl = el as HTMLElement
  void htmlEl.offsetHeight // force reflow so current state is committed before transitioning
  htmlEl.style.transition = 'opacity 0.2s ease'
  htmlEl.style.opacity = '0'
  // Inline opacity: 0 is maintained until done() is called; Vue then removes
  // the element from DOM. No CSS class removal = no snap-back flash.
  setTimeout(done, 200)
}
</script>

<template>
  <div id="app" class="flex min-h-screen flex-col">
    <a href="#main-content" class="skip-link">Skip to main content</a>

    <AppHeader />
    <MobileMenu />

    <main id="main-content" class="flex-1">
      <RouterView v-slot="{ Component }">
        <Transition :css="false" mode="out-in" @enter="onPageEnter" @leave="onPageLeave">
          <component :is="Component" :key="route.path" />
        </Transition>
      </RouterView>
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
  background-color: var(--skin-hero-1);
}

:is(.dark *) #app {
  background-color: var(--skin-hero-dark-1);
}

/* Skip link — visually hidden until focused (keyboard nav a11y) */
.skip-link {
  position: absolute;
  left: -9999px;
  top: 1rem;
  z-index: 9999;
  padding: 0.5rem 1rem;
  background: var(--skin-600);
  color: white;
  font-weight: 600;
  border-radius: 6px;
  text-decoration: none;
  font-size: 0.875rem;
}

.skip-link:focus {
  left: 1rem;
}
</style>
