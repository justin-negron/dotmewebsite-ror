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
  setTimeout(() => navigateTo(item), 200)
}
</script>

<template>
  <Teleport to="body">
    <Transition name="menu-overlay">
      <div
        v-if="uiStore.isMobileMenuOpen"
        id="mobile-menu"
        class="mobile-overlay"
        role="dialog"
        aria-modal="true"
        aria-label="Navigation menu"
        @keydown.escape="uiStore.closeMobileMenu()"
      >
        <!-- Top bar: brand + close -->
        <div class="overlay-top">
          <span class="overlay-brand" aria-hidden="true">
            <span class="brand-prompt">~$</span>
            <span class="brand-name">justin-negron</span>
            <span class="brand-cursor" aria-hidden="true" />
          </span>
          <button class="overlay-close" aria-label="Close navigation menu" @click="uiStore.closeMobileMenu()">
            exit
          </button>
        </div>

        <!-- Navigation commands -->
        <nav class="overlay-nav" aria-label="Mobile navigation">
          <a
            v-for="(item, i) in NAV_ITEMS"
            :key="item.href"
            :href="item.href"
            :class="['overlay-item', isActive(item) ? 'is-active' : '']"
            :style="{ animationDelay: `${i * 0.055}s` }"
            @click="handleNavClick($event, item)"
          >
            <span class="item-prompt" aria-hidden="true">$</span>
            <span class="item-label">{{ item.label.toLowerCase() }}</span>
            <svg
              class="item-arrow"
              width="18"
              height="18"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              viewBox="0 0 24 24"
              aria-hidden="true"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M5 12h14M12 5l7 7-7 7" />
            </svg>
          </a>
        </nav>

        <!-- Footer -->
        <div class="overlay-footer" aria-hidden="true">
          <span class="footer-text">justinnegron.dev</span>
          <span class="footer-text">v1.0.0</span>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
/* ===================================================================
   Full-screen overlay
   =================================================================== */
.mobile-overlay {
  position: fixed;
  inset: 0;
  z-index: 1040;
  background: rgba(10, 9, 8, 0.97);
  backdrop-filter: blur(20px) saturate(1.2);
  display: flex;
  flex-direction: column;
  overflow-y: auto;
}

/* ===================================================================
   Enter / leave animation
   =================================================================== */
.menu-overlay-enter-active {
  animation: overlayIn 0.35s cubic-bezier(0.16, 1, 0.3, 1);
}

.menu-overlay-leave-active {
  animation: overlayOut 0.22s ease;
}

@keyframes overlayIn {
  from {
    opacity: 0;
    transform: scale(0.97);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

@keyframes overlayOut {
  from {
    opacity: 1;
    transform: scale(1);
  }
  to {
    opacity: 0;
    transform: scale(0.97);
  }
}

/* ===================================================================
   Top bar
   =================================================================== */
.overlay-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1.75rem 1.5rem 0;
  flex-shrink: 0;
}

.overlay-brand {
  display: flex;
  align-items: center;
  gap: 6px;
  font-family: 'JetBrains Mono', monospace;
  font-weight: 600;
  font-size: 0.85rem;
  color: #e7e5e4;
  letter-spacing: -0.01em;
}

.brand-prompt {
  color: var(--skin-400);
  font-weight: 500;
}

.brand-cursor {
  display: inline-block;
  width: 2px;
  height: 14px;
  background: var(--skin-400);
  animation: blink 1s step-end infinite;
  margin-left: 1px;
  vertical-align: text-bottom;
}

@keyframes blink {
  50% {
    opacity: 0;
  }
}

.overlay-close {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
  font-weight: 600;
  letter-spacing: 0.01em;
  color: #44403c;
  background: none;
  border: 1px solid rgba(255, 255, 255, 0.06);
  cursor: pointer;
  padding: 8px 16px;
  border-radius: 8px;
  min-height: 40px;
  display: flex;
  align-items: center;
  transition:
    color 0.2s ease,
    background 0.2s ease,
    border-color 0.2s ease;
}

.overlay-close:hover {
  color: #e7e5e4;
  background: rgba(255, 255, 255, 0.06);
  border-color: rgba(255, 255, 255, 0.1);
}

/* ===================================================================
   Nav items
   =================================================================== */
.overlay-nav {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 2rem 1.25rem;
}

.overlay-item {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 0.875rem 1rem;
  border-radius: 12px;
  text-decoration: none;
  cursor: pointer;
  min-height: 60px;
  border: 1px solid transparent;
  /* staggered reveal */
  opacity: 0;
  animation: itemSlide 0.4s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  transition:
    background 0.15s ease,
    border-color 0.15s ease;
}

.overlay-item:active {
  background: rgba(255, 255, 255, 0.05);
}

.overlay-item.is-active {
  background: rgba(var(--skin-rgb), 0.1);
  border-color: rgba(var(--skin-rgb), 0.15);
}

@keyframes itemSlide {
  from {
    opacity: 0;
    transform: translateX(-18px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

/* Hover only on pointer devices */
@media (hover: hover) {
  .overlay-item:hover {
    background: rgba(255, 255, 255, 0.04);
  }

  .overlay-item:hover .item-prompt {
    color: var(--skin-400);
  }

  .overlay-item:hover .item-label {
    color: #f5f5f4;
  }

  .overlay-item:hover .item-arrow {
    color: var(--skin-400);
    transform: translateX(4px);
  }
}

.item-prompt {
  font-family: 'JetBrains Mono', monospace;
  font-size: 1rem;
  color: #292524;
  width: 18px;
  flex-shrink: 0;
  transition: color 0.2s ease;
}

.overlay-item.is-active .item-prompt {
  color: var(--skin-500);
}

.item-label {
  font-family: 'JetBrains Mono', monospace;
  font-size: clamp(1.35rem, 5vw, 1.7rem);
  font-weight: 600;
  color: #78716c;
  flex: 1;
  letter-spacing: -0.02em;
  transition: color 0.15s ease;
}

.overlay-item.is-active .item-label {
  color: #fafaf9;
}

.item-arrow {
  color: #1c1917;
  flex-shrink: 0;
  transition:
    color 0.2s ease,
    transform 0.2s ease;
}

.overlay-item.is-active .item-arrow {
  color: var(--skin-500);
  transform: translateX(2px);
}

/* ===================================================================
   Footer
   =================================================================== */
.overlay-footer {
  flex-shrink: 0;
  padding: 1.5rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-top: 1px solid rgba(255, 255, 255, 0.04);
}

.footer-text {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.68rem;
  color: #292524;
  letter-spacing: 0.01em;
}
</style>
