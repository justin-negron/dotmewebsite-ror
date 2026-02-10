<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useWindowScroll } from '@vueuse/core'
import { useUiStore } from '@/stores'
import { useScrollTo, NAV_ITEMS, type NavItem } from '@/composables/useScrollTo'
import { useTheme } from '@/composables/useTheme'
import { useTerminalBridge } from '@/composables/useTerminalBridge'
import ThemeToggle from '@/components/common/ThemeToggle.vue'

const route = useRoute()
const uiStore = useUiStore()
const { navigateTo } = useScrollTo()
const { theme, toggleTheme } = useTheme()
const { triggerAutoType, triggerClearAutoType } = useTerminalBridge()
const { y: scrollY } = useWindowScroll()
const homeItem: NavItem = { label: 'Home', href: '/', isRoute: false }

const isHome = computed(() => route.path === '/')
const isScrolled = computed(() => scrollY.value > 100)
const showGlass = computed(() => !isHome.value || isScrolled.value)

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

function handleNavHover(item: NavItem) {
  triggerAutoType(item.label.toLowerCase())
}

function handleNavLeave() {
  triggerClearAutoType()
}
</script>

<template>
  <header
    :class="[
      'fixed top-0 left-0 right-0 z-[1020] transition-all duration-300',
      showGlass
        ? 'bg-white/70 dark:bg-gray-900/70 backdrop-blur-md border-b border-gray-200/50 dark:border-gray-700/50'
        : 'bg-transparent border-b border-transparent',
    ]"
  >
    <div class="container">
      <nav class="flex h-20 items-center justify-between" aria-label="Main navigation">
        <!-- Brand -->
        <a
          href="/"
          class="text-xl font-bold transition-colors"
          :class="[
            showGlass
              ? 'text-gray-900 dark:text-white hover:text-[var(--skin-600)] dark:hover:text-[var(--skin-400)]'
              : 'text-gray-900 dark:text-white hover:text-[var(--skin-600)] dark:hover:text-[var(--skin-400)]',
          ]"
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
            class="px-4 py-2 text-sm font-medium transition-colors duration-200 rounded-lg"
            :style="
              isActive(item)
                ? {
                    color: `var(--skin-600)`,
                    backgroundColor: `rgba(var(--skin-rgb), 0.08)`,
                  }
                : undefined
            "
            :class="[
              !isActive(item) &&
                (showGlass
                  ? 'text-gray-600 dark:text-gray-300 hover:text-[var(--skin-600)] dark:hover:text-[var(--skin-400)] hover:bg-gray-100 dark:hover:bg-gray-800'
                  : 'text-gray-700 dark:text-gray-200 hover:text-[var(--skin-600)] dark:hover:text-[var(--skin-400)]'),
            ]"
            @click="handleNavClick($event, item)"
            @mouseenter="handleNavHover(item)"
            @mouseleave="handleNavLeave()"
          >
            {{ item.label }}
          </a>
        </div>

        <!-- Right: theme toggle + hamburger -->
        <div class="flex items-center gap-3">
          <ThemeToggle :is-dark="theme === 'dark'" @toggle="toggleTheme($event)" />

          <!-- Mobile Hamburger -->
          <button
            type="button"
            class="lg:hidden rounded-lg p-2 text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-[var(--skin-500)]"
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
        </div>
      </nav>
    </div>
  </header>
</template>
