<script setup lang="ts">
import { ref, computed } from 'vue'
import { RouterView, RouterLink, useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const sidebarOpen = ref(false)

const navItems = [
  { name: 'Dashboard', path: '/admin', icon: '~' },
  { name: 'Projects', path: '/admin/projects', icon: '~/projects' },
  { name: 'Experiences', path: '/admin/experiences', icon: '~/experiences' },
  { name: 'Blog Posts', path: '/admin/blog', icon: '~/blog' },
  { name: 'Inbox', path: '/admin/contacts', icon: '~/inbox' },
]

const currentPageTitle = computed(() => {
  const matched = navItems.find(
    (item) =>
      item.path === route.path || (item.path !== '/admin' && route.path.startsWith(item.path)),
  )
  return matched?.name ?? 'Admin'
})

function isActive(path: string): boolean {
  if (path === '/admin') return route.path === '/admin'
  return route.path.startsWith(path)
}

async function handleLogout() {
  await authStore.logout()
  router.push({ name: 'admin-login' })
}

function closeSidebar() {
  sidebarOpen.value = false
}
</script>

<template>
  <div class="admin-layout">
    <!-- Mobile overlay -->
    <Transition name="fade">
      <div v-if="sidebarOpen" class="sidebar-overlay" @click="closeSidebar" />
    </Transition>

    <!-- Sidebar -->
    <aside :class="['sidebar', sidebarOpen ? 'is-open' : '']">
      <div class="sidebar-header">
        <div class="dots">
          <span class="dot dot-red" />
          <span class="dot dot-yellow" />
          <span class="dot dot-green" />
        </div>
        <span class="sidebar-title">admin panel</span>
      </div>

      <nav class="sidebar-nav">
        <RouterLink
          v-for="item in navItems"
          :key="item.path"
          :to="item.path"
          :class="['nav-item', isActive(item.path) ? 'is-active' : '']"
          @click="closeSidebar"
        >
          <span class="nav-prefix">{{ item.icon }}/</span>
          <span class="nav-label">{{ item.name }}</span>
        </RouterLink>
      </nav>

      <div class="sidebar-footer">
        <p class="admin-email">{{ authStore.admin?.email }}</p>
        <button class="logout-btn" @click="handleLogout">
          <span class="btn-prompt">$</span> logout
        </button>
      </div>
    </aside>

    <!-- Main content -->
    <div class="main-area">
      <header class="topbar">
        <button class="menu-toggle" aria-label="Toggle menu" @click="sidebarOpen = !sidebarOpen">
          <span class="hamburger-line" />
          <span class="hamburger-line" />
          <span class="hamburger-line" />
        </button>
        <h1 class="page-title">
          <span class="title-prompt">$</span> {{ currentPageTitle.toLowerCase() }}
        </h1>
      </header>

      <main class="content">
        <RouterView />
      </main>
    </div>
  </div>
</template>

<style scoped>
.admin-layout {
  display: flex;
  min-height: 100vh;
  background: #fafaf9;
  font-family: 'JetBrains Mono', monospace;
}

:is(.dark *).admin-layout {
  background: #0c0a09;
}

/* ── Sidebar ──────────────────────────────────────────────── */

.sidebar {
  width: 240px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  background: #ffffff;
  border-right: 1px solid #e7e5e4;
  transition:
    background 0.3s ease,
    border-color 0.3s ease;
}

:is(.dark *).sidebar {
  background: #1c1917;
  border-color: rgba(var(--skin-light-rgb), 0.08);
}

.sidebar-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.875rem 1rem;
  border-bottom: 1px solid #e7e5e4;
  transition: border-color 0.3s ease;
}

:is(.dark *).sidebar-header {
  border-color: rgba(var(--skin-light-rgb), 0.06);
}

.dots {
  display: flex;
  gap: 6px;
}

.dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

.dot-red {
  background: #ef4444;
}
.dot-yellow {
  background: #eab308;
}
.dot-green {
  background: #22c55e;
}

.sidebar-title {
  font-size: 0.75rem;
  color: #78716c;
  font-weight: 500;
}

:is(.dark *).sidebar-title {
  color: #a8a29e;
}

.sidebar-nav {
  flex: 1;
  padding: 0.75rem 0.5rem;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.55rem 0.75rem;
  font-size: 0.8rem;
  color: #57534e;
  text-decoration: none;
  border-radius: 8px;
  transition: all 0.15s ease;
}

.nav-item:hover {
  color: #1c1917;
  background: rgba(var(--skin-rgb), 0.04);
}

:is(.dark *).nav-item {
  color: #a8a29e;
}

:is(.dark *).nav-item:hover {
  color: #e7e5e4;
  background: rgba(var(--skin-light-rgb), 0.06);
}

.nav-item.is-active {
  color: var(--skin-700);
  background: rgba(var(--skin-rgb), 0.08);
  font-weight: 600;
}

:is(.dark *).nav-item.is-active {
  color: var(--skin-400);
  background: rgba(var(--skin-light-rgb), 0.1);
}

.nav-prefix {
  font-size: 0.7rem;
  opacity: 0.5;
  min-width: 5.5rem;
}

.nav-label {
  white-space: nowrap;
}

.sidebar-footer {
  padding: 1rem;
  border-top: 1px solid #e7e5e4;
  transition: border-color 0.3s ease;
}

:is(.dark *).sidebar-footer {
  border-color: rgba(var(--skin-light-rgb), 0.06);
}

.admin-email {
  font-size: 0.7rem;
  color: #78716c;
  margin-bottom: 0.5rem;
  overflow: hidden;
  text-overflow: ellipsis;
}

:is(.dark *).admin-email {
  color: #57534e;
}

.logout-btn {
  width: 100%;
  padding: 0.45rem 0.75rem;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--skin-700);
  background: rgba(var(--skin-rgb), 0.05);
  border: 1.5px dashed rgba(var(--skin-rgb), 0.25);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
  text-align: left;
}

.logout-btn:hover {
  background: rgba(var(--skin-rgb), 0.09);
  border-color: rgba(var(--skin-rgb), 0.45);
}

:is(.dark *).logout-btn {
  color: var(--skin-400);
  background: rgba(var(--skin-light-rgb), 0.04);
  border-color: rgba(var(--skin-light-rgb), 0.15);
}

:is(.dark *).logout-btn:hover {
  background: rgba(var(--skin-light-rgb), 0.08);
  border-color: rgba(var(--skin-light-rgb), 0.3);
}

.btn-prompt {
  opacity: 0.5;
}

/* ── Main area ────────────────────────────────────────────── */

.main-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.topbar {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.875rem 1.5rem;
  background: #ffffff;
  border-bottom: 1px solid #e7e5e4;
  transition:
    background 0.3s ease,
    border-color 0.3s ease;
}

:is(.dark *).topbar {
  background: #1c1917;
  border-color: rgba(var(--skin-light-rgb), 0.08);
}

.menu-toggle {
  display: none;
  flex-direction: column;
  gap: 4px;
  padding: 6px;
  background: none;
  border: none;
  cursor: pointer;
}

.hamburger-line {
  width: 18px;
  height: 2px;
  background: #78716c;
  border-radius: 1px;
  transition: background 0.2s ease;
}

:is(.dark *).hamburger-line {
  background: #a8a29e;
}

.page-title {
  font-size: 0.85rem;
  font-weight: 600;
  color: #1c1917;
}

:is(.dark *).page-title {
  color: #e7e5e4;
}

.title-prompt {
  color: var(--skin-600);
  font-weight: 600;
}

:is(.dark *).title-prompt {
  color: var(--skin-400);
}

.content {
  flex: 1;
  padding: 1.5rem;
  overflow-y: auto;
}

/* ── Mobile overlay ───────────────────────────────────────── */

.sidebar-overlay {
  display: none;
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.4);
  z-index: 40;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* ── Responsive ───────────────────────────────────────────── */

@media (max-width: 768px) {
  .sidebar {
    position: fixed;
    top: 0;
    left: 0;
    bottom: 0;
    z-index: 50;
    transform: translateX(-100%);
    transition:
      transform 0.25s cubic-bezier(0.16, 1, 0.3, 1),
      background 0.3s ease;
    box-shadow: 4px 0 24px rgba(0, 0, 0, 0.1);
  }

  .sidebar.is-open {
    transform: translateX(0);
  }

  .sidebar-overlay {
    display: block;
  }

  .menu-toggle {
    display: flex;
  }

  .content {
    padding: 1rem;
  }
}
</style>
