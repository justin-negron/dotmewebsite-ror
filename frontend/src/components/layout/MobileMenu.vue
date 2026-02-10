<script setup lang="ts">
import { watch } from 'vue'
import { useRoute } from 'vue-router'
import { useScrollLock } from '@vueuse/core'
import { useUiStore } from '@/stores'
import { useScrollTo, NAV_ITEMS, type NavItem } from '@/composables/useScrollTo'

const route = useRoute()
const uiStore = useUiStore()
const { navigateTo } = useScrollTo()
const scrollLock = useScrollLock(document.body)

watch(
  () => uiStore.isMobileMenuOpen,
  (isOpen) => {
    scrollLock.value = isOpen
  }
)

watch(
  () => route.fullPath,
  () => {
    uiStore.closeMobileMenu()
  }
)

function isActive(item: NavItem): boolean {
  if (item.isRoute) {
    return route.path === item.href || route.path.startsWith(`${item.href}/`)
  }
  if (item.href === '/') {
    return route.path === '/' && !uiStore.activeSection
  }
  const sectionId = item.href.split('#')[1]
  return route.path === '/' && uiStore.activeSection === sectionId
}

function handleNavClick(event: Event, item: NavItem) {
  event.preventDefault()
  uiStore.closeMobileMenu()
  setTimeout(() => navigateTo(item), 150)
}
</script>

<template>
  <Teleport to="body">
    <!-- Backdrop -->
    <Transition name="fade">
      <div
        v-if="uiStore.isMobileMenuOpen"
        class="fixed inset-0 z-[1040] bg-black/50"
        aria-hidden="true"
        @click="uiStore.closeMobileMenu()"
      />
    </Transition>

    <!-- Menu Panel -->
    <Transition name="slide-right">
      <aside
        v-if="uiStore.isMobileMenuOpen"
        id="mobile-menu"
        class="fixed top-0 right-0 bottom-0 z-[1050] w-80 max-w-[85vw] bg-white dark:bg-gray-900 shadow-xl"
        role="dialog"
        aria-modal="true"
        aria-label="Navigation menu"
        @keydown.escape="uiStore.closeMobileMenu()"
      >
        <!-- Header -->
        <div
          class="flex items-center justify-between border-b border-gray-200 dark:border-gray-700 p-6"
        >
          <span class="text-lg font-bold" style="color: var(--skin-600)">JN</span>
          <button
            type="button"
            class="rounded-lg p-2 text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"
            aria-label="Close menu"
            @click="uiStore.closeMobileMenu()"
          >
            <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        <!-- Nav Links -->
        <nav class="p-6" aria-label="Mobile navigation">
          <ul class="space-y-1">
            <li v-for="item in NAV_ITEMS" :key="item.href">
              <a
                :href="item.href"
                class="block rounded-lg px-4 py-3 text-base font-medium transition-colors duration-200"
                :style="
                  isActive(item)
                    ? {
                        color: 'var(--skin-600)',
                        backgroundColor: 'rgba(var(--skin-rgb), 0.08)',
                      }
                    : undefined
                "
                :class="[
                  !isActive(item) &&
                    'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800',
                ]"
                @click="handleNavClick($event, item)"
              >
                {{ item.label }}
              </a>
            </li>
          </ul>
        </nav>
      </aside>
    </Transition>
  </Teleport>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.slide-right-enter-active,
.slide-right-leave-active {
  transition: transform 0.3s ease;
}
.slide-right-enter-from,
.slide-right-leave-to {
  transform: translateX(100%);
}
</style>
