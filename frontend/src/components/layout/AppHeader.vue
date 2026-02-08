<script setup lang="ts">
import { useRoute } from 'vue-router'
import { useUiStore } from '@/stores'
import { useScrollTo, NAV_ITEMS, type NavItem } from '@/composables/useScrollTo'

const route = useRoute()
const uiStore = useUiStore()
const { navigateTo } = useScrollTo()
const homeItem: NavItem = { label: 'Home', href: '/', isRoute: false }

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
  navigateTo(item)
}
</script>

<template>
  <header class="sticky top-0 z-[1020] glass border-b border-gray-200/50 dark:border-gray-700/50">
    <div class="container">
      <nav class="flex h-20 items-center justify-between" aria-label="Main navigation">
        <!-- Brand -->
        <a
          href="/"
          class="text-xl font-bold text-gray-900 dark:text-white transition-colors hover:text-primary-600 dark:hover:text-primary-400"
          @click.prevent="navigateTo(homeItem)"
        >
          <span class="sm:hidden">JN</span>
          <span class="hidden sm:inline">Justin Negron</span>
        </a>

        <!-- Desktop Nav -->
        <div class="hidden lg:flex lg:items-center lg:gap-1">
          <a
            v-for="item in NAV_ITEMS"
            :key="item.href"
            :href="item.href"
            :class="[
              'px-4 py-2 text-sm font-medium transition-colors duration-200 rounded-lg',
              isActive(item)
                ? 'text-primary-600 dark:text-primary-400 bg-primary-50 dark:bg-primary-900/20'
                : 'text-gray-600 dark:text-gray-300 hover:text-primary-600 dark:hover:text-primary-400 hover:bg-gray-100 dark:hover:bg-gray-800',
            ]"
            @click="handleNavClick($event, item)"
          >
            {{ item.label }}
          </a>
        </div>

        <!-- Mobile Hamburger -->
        <button
          type="button"
          class="lg:hidden rounded-lg p-2 text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-primary-500"
          :aria-expanded="uiStore.isMobileMenuOpen"
          aria-controls="mobile-menu"
          aria-label="Toggle navigation menu"
          @click="uiStore.toggleMobileMenu()"
        >
          <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              v-if="!uiStore.isMobileMenuOpen"
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M4 6h16M4 12h16M4 18h16"
            />
            <path
              v-else
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M6 18L18 6M6 6l12 12"
            />
          </svg>
        </button>
      </nav>
    </div>
  </header>
</template>
