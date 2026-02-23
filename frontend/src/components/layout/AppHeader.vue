<script setup lang="ts">
import { ref, computed, watch, onMounted, nextTick } from 'vue'
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

// --- Sliding pill indicator ---
const navRefs = ref<HTMLElement[]>([])
const indicatorStyle = ref<Record<string, string>>({})

function setNavRef(el: unknown, index: number) {
  if (el instanceof HTMLElement) {
    navRefs.value[index] = el
  }
}

function updateIndicator() {
  const activeIndex = NAV_ITEMS.findIndex((item) => isActive(item))
  if (activeIndex === -1 || !navRefs.value[activeIndex]) {
    indicatorStyle.value = { opacity: '0' }
    return
  }
  const el = navRefs.value[activeIndex]!
  const parent = el.parentElement
  if (!parent) return
  const parentRect = parent.getBoundingClientRect()
  const elRect = el.getBoundingClientRect()
  indicatorStyle.value = {
    opacity: '1',
    width: `${elRect.width}px`,
    transform: `translateX(${elRect.left - parentRect.left}px)`,
  }
}

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

// Clear active section when scrolled to hero area on home page
watch(scrollY, (y) => {
  if (isHome.value && y < 300 && uiStore.activeSection) {
    uiStore.setActiveSection('')
  }
})

// Update indicator when active section or route changes
watch(
  () => [uiStore.activeSection, route.path],
  () => nextTick(updateIndicator),
  { flush: 'post' }
)

onMounted(() => {
  nextTick(updateIndicator)
})
</script>

<template>
  <header :class="['header-wrap', showGlass ? 'has-glass' : 'is-transparent']">
    <div class="container">
      <nav class="nav-bar" aria-label="Main navigation">
        <!-- Brand -->
        <a href="/" class="brand" @click.prevent="navigateTo(homeItem)">
          <span class="brand-prompt">~$</span>
          <span class="brand-name">justin-negron</span>
          <span class="brand-cursor" />
        </a>

        <!-- Desktop Nav — Floating capsule -->
        <div class="hidden lg:block">
          <div class="nav-capsule">
            <!-- Sliding indicator behind active item -->
            <div class="nav-indicator" :style="indicatorStyle" />
            <a
              v-for="(item, index) in NAV_ITEMS"
              :key="item.href"
              :ref="(el) => setNavRef(el, index)"
              :href="item.href"
              :class="['nav-link', isActive(item) ? 'is-active' : '']"
              @click="handleNavClick($event, item)"
              @mouseenter="handleNavHover(item)"
              @mouseleave="handleNavLeave()"
            >
              {{ item.label }}
            </a>
          </div>
        </div>

        <!-- Right: theme toggle + hamburger -->
        <div class="flex items-center gap-3">
          <ThemeToggle :is-dark="theme === 'dark'" @toggle="toggleTheme($event)" />

          <!-- Mobile Hamburger -->
          <button
            type="button"
            class="hamburger lg:hidden"
            :aria-expanded="uiStore.isMobileMenuOpen"
            aria-controls="mobile-menu"
            aria-label="Toggle navigation menu"
            @click="uiStore.toggleMobileMenu()"
          >
            <span class="hamburger-icon" aria-hidden="true">
              <span v-if="!uiStore.isMobileMenuOpen">&gt;_</span>
              <span v-else>&times;</span>
            </span>
          </button>
        </div>
      </nav>
    </div>
  </header>
</template>

<style scoped>
/* ===================================================================
   Header wrap
   =================================================================== */
.header-wrap {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 1020;
  /* Extend the header background behind the Dynamic Island / notch safe area.
     viewport-fit=cover (set in index.html) makes position:fixed top:0 reach
     the very top of the device screen; this padding pushes nav content below
     the status bar while the header background fills the cutout area. */
  padding-top: env(safe-area-inset-top, 0px);
  transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}

.header-wrap.is-transparent {
  background: transparent;
  border-bottom: 1px solid transparent;
}

.header-wrap.has-glass {
  background: rgba(255, 255, 255, 0.75);
  backdrop-filter: blur(16px) saturate(1.5);
  border-bottom: 1px solid rgba(var(--skin-rgb), 0.08);
  box-shadow: 0 1px 24px rgba(0, 0, 0, 0.04);
}

:is(.dark *).header-wrap.has-glass {
  background: rgba(10, 10, 10, 0.8);
  border-bottom-color: rgba(var(--skin-light-rgb), 0.06);
  box-shadow: 0 1px 24px rgba(0, 0, 0, 0.2);
}

/* ===================================================================
   Nav bar layout
   =================================================================== */
.nav-bar {
  display: flex;
  height: 80px;
  align-items: center;
  justify-content: space-between;
}

/* ===================================================================
   Brand — terminal prompt style
   =================================================================== */
.brand {
  display: flex;
  align-items: center;
  gap: 6px;
  text-decoration: none;
  transition: opacity 0.2s ease;
}

.brand:hover {
  opacity: 0.8;
}

.brand-prompt {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--skin-500);
  transition: color 0.3s ease;
}

:is(.dark *).brand-prompt {
  color: var(--skin-400);
}

.brand-name {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.9rem;
  font-weight: 600;
  color: #1c1917;
  letter-spacing: -0.01em;
  transition: color 0.3s ease;
}

:is(.dark *).brand-name {
  color: #fafaf9;
}

.brand-cursor {
  display: inline-block;
  width: 2px;
  height: 16px;
  background: var(--skin-500);
  animation: cursorBlink 1s step-end infinite;
  margin-left: 1px;
}

:is(.dark *).brand-cursor {
  background: var(--skin-400);
}

@keyframes cursorBlink {
  50% {
    opacity: 0;
  }
}

/* ===================================================================
   Nav capsule — floating pill container
   =================================================================== */
.nav-capsule {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 2px;
  padding: 4px;
  border-radius: 14px;
  background: rgba(var(--skin-rgb), 0.04);
  border: 1px solid rgba(var(--skin-rgb), 0.06);
  transition:
    background 0.3s ease,
    border-color 0.3s ease;
}

:is(.dark *).nav-capsule {
  background: rgba(var(--skin-light-rgb), 0.04);
  border-color: rgba(var(--skin-light-rgb), 0.06);
}

/* Sliding pill indicator */
.nav-indicator {
  position: absolute;
  top: 4px;
  left: 0;
  height: calc(100% - 8px);
  border-radius: 10px;
  background: rgba(var(--skin-rgb), 0.1);
  border: 1px solid rgba(var(--skin-rgb), 0.08);
  transition:
    transform 0.35s cubic-bezier(0.16, 1, 0.3, 1),
    width 0.35s cubic-bezier(0.16, 1, 0.3, 1),
    opacity 0.2s ease;
  pointer-events: none;
  z-index: 0;
}

:is(.dark *).nav-indicator {
  background: rgba(var(--skin-light-rgb), 0.08);
  border-color: rgba(var(--skin-light-rgb), 0.06);
}

/* ===================================================================
   Nav links
   =================================================================== */
.nav-link {
  position: relative;
  z-index: 1;
  padding: 8px 18px;
  font-size: 0.82rem;
  font-weight: 500;
  letter-spacing: 0.01em;
  color: #78716c;
  border-radius: 10px;
  text-decoration: none;
  transition: color 0.25s ease;
  white-space: nowrap;
}

.nav-link:hover {
  color: #57534e;
}

.nav-link.is-active {
  color: var(--skin-700);
}

:is(.dark *).nav-link {
  color: #78716c;
}

:is(.dark *).nav-link:hover {
  color: #d6d3d1;
}

:is(.dark *).nav-link.is-active {
  color: var(--skin-300);
}

/* ===================================================================
   Hamburger button
   =================================================================== */
.hamburger {
  padding: 12px;
  border-radius: 10px;
  color: #78716c;
  transition:
    color 0.2s ease,
    background 0.2s ease;
}

.hamburger:hover {
  color: #57534e;
  background: rgba(var(--skin-rgb), 0.06);
}

:is(.dark *).hamburger {
  color: #a8a29e;
}

:is(.dark *).hamburger:hover {
  color: #d6d3d1;
  background: rgba(var(--skin-light-rgb), 0.06);
}

.hamburger:focus-visible {
  outline: 2px solid var(--skin-500);
  outline-offset: 2px;
}

.hamburger-icon {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.95rem;
  font-weight: 700;
  letter-spacing: -0.04em;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  line-height: 1;
}
</style>
