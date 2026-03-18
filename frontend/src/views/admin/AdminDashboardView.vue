<script setup lang="ts">
import { onMounted, computed } from 'vue'
import { useAdminDashboardStore } from '@/stores'
import AdminStatCard from '@/components/admin/AdminStatCard.vue'

const dashboardStore = useAdminDashboardStore()

onMounted(() => {
  dashboardStore.fetchDashboard()
})

const summary = computed(() => dashboardStore.data?.summary)
const viewsByDate = computed(() => dashboardStore.data?.views_by_date ?? {})
const popularPages = computed(() => dashboardStore.data?.popular_pages ?? [])

const maxViewCount = computed(() => {
  const values = Object.values(viewsByDate.value)
  return Math.max(...values, 1)
})

const chartEntries = computed(() => {
  return Object.entries(viewsByDate.value)
    .sort(([a], [b]) => a.localeCompare(b))
    .slice(-14)
    .map(([date, count]) => ({
      date: date.slice(5),
      count,
      height: `${(count / maxViewCount.value) * 100}%`,
    }))
})
</script>

<template>
  <div class="dashboard">
    <!-- Loading -->
    <div v-if="dashboardStore.loading && !dashboardStore.data" class="loading-state">
      <span class="loading-text">$ loading dashboard...</span>
    </div>

    <template v-else-if="dashboardStore.data">
      <!-- Stat cards -->
      <div class="stats-grid">
        <AdminStatCard label="Total Page Views" :value="dashboardStore.data.total_views" accent />
        <AdminStatCard label="Unique Visitors" :value="dashboardStore.data.unique_visitors" />
        <AdminStatCard label="Projects" :value="summary?.total_projects ?? 0" />
        <AdminStatCard
          label="Published Posts"
          :value="summary?.published_blog_posts ?? 0"
        />
        <AdminStatCard label="Draft Posts" :value="summary?.draft_blog_posts ?? 0" />
        <AdminStatCard label="Unread Messages" :value="summary?.unread_contacts ?? 0" accent />
      </div>

      <!-- Views chart -->
      <div class="chart-card">
        <h2 class="card-title"><span class="prompt">$</span> views (last 14 days)</h2>
        <div v-if="chartEntries.length > 0" class="chart-container">
          <div class="chart-bars">
            <div v-for="entry in chartEntries" :key="entry.date" class="chart-bar-col">
              <div class="chart-bar" :style="{ height: entry.height }" />
              <span class="chart-label">{{ entry.date }}</span>
            </div>
          </div>
        </div>
        <p v-else class="empty-chart">No page view data yet.</p>
      </div>

      <!-- Popular pages -->
      <div class="list-card">
        <h2 class="card-title"><span class="prompt">$</span> popular pages</h2>
        <div v-if="popularPages.length > 0" class="popular-list">
          <div v-for="page in popularPages" :key="page.path" class="popular-item">
            <span class="popular-path">{{ page.path }}</span>
            <span class="popular-count">{{ page.count }}</span>
          </div>
        </div>
        <p v-else class="empty-list">No page view data yet.</p>
      </div>
    </template>

    <!-- Error -->
    <div v-if="dashboardStore.error" class="error-block">
      <span class="error-prefix">error:</span> {{ dashboardStore.error.message }}
    </div>
  </div>
</template>

<style scoped>
.dashboard {
  max-width: 1000px;
}

.loading-state {
  padding: 3rem;
  text-align: center;
}

.loading-text {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.85rem;
  color: #78716c;
  animation: blink 1.2s steps(1) infinite;
}

@keyframes blink {
  50% {
    opacity: 0.4;
  }
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 0.75rem;
  margin-bottom: 1.5rem;
}

.chart-card,
.list-card {
  background: #ffffff;
  border: 1px solid #e7e5e4;
  border-radius: 12px;
  padding: 1.25rem;
  margin-bottom: 1.5rem;
  transition:
    background 0.3s ease,
    border-color 0.3s ease;
}

:is(.dark *).chart-card,
:is(.dark *).list-card {
  background: #1c1917;
  border-color: rgba(var(--skin-light-rgb), 0.08);
}

.card-title {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
  font-weight: 600;
  color: #1c1917;
  margin-bottom: 1rem;
}

:is(.dark *).card-title {
  color: #e7e5e4;
}

.prompt {
  color: var(--skin-600);
}

:is(.dark *).prompt {
  color: var(--skin-400);
}

/* ── Chart ──────────────────────────────────────────── */

.chart-container {
  height: 160px;
}

.chart-bars {
  display: flex;
  align-items: flex-end;
  gap: 4px;
  height: 130px;
}

.chart-bar-col {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  height: 100%;
  justify-content: flex-end;
}

.chart-bar {
  width: 100%;
  max-width: 32px;
  background: linear-gradient(to top, var(--skin-500), var(--skin-400));
  border-radius: 3px 3px 0 0;
  min-height: 2px;
  transition: height 0.4s ease;
}

:is(.dark *).chart-bar {
  background: linear-gradient(to top, var(--skin-600), var(--skin-400));
}

.chart-label {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.55rem;
  color: #a8a29e;
  margin-top: 0.35rem;
  writing-mode: vertical-lr;
  text-orientation: mixed;
  transform: rotate(180deg);
  max-height: 3rem;
  overflow: hidden;
}

:is(.dark *).chart-label {
  color: #57534e;
}

.empty-chart,
.empty-list {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
  color: #a8a29e;
  text-align: center;
  padding: 1rem;
}

:is(.dark *).empty-chart,
:is(.dark *).empty-list {
  color: #57534e;
}

/* ── Popular pages ──────────────────────────────────── */

.popular-list {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.popular-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.45rem 0.6rem;
  border-radius: 6px;
  transition: background 0.15s ease;
}

.popular-item:hover {
  background: rgba(var(--skin-rgb), 0.03);
}

:is(.dark *).popular-item:hover {
  background: rgba(var(--skin-light-rgb), 0.03);
}

.popular-path {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  color: #44403c;
}

:is(.dark *).popular-path {
  color: #d6d3d1;
}

.popular-count {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--skin-600);
}

:is(.dark *).popular-count {
  color: var(--skin-400);
}

/* ── Error ──────────────────────────────────────────── */

.error-block {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
  padding: 0.6rem 0.8rem;
  border-radius: 8px;
  background: rgba(239, 68, 68, 0.06);
  border: 1px solid rgba(239, 68, 68, 0.15);
  color: #dc2626;
}

:is(.dark *).error-block {
  background: rgba(239, 68, 68, 0.08);
  border-color: rgba(239, 68, 68, 0.2);
  color: #f87171;
}

.error-prefix {
  font-weight: 700;
}
</style>
