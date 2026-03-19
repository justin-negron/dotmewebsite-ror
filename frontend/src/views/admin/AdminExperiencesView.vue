<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAdminExperiencesStore } from '@/stores'
import AdminDataTable from '@/components/admin/AdminDataTable.vue'
import AdminConfirmDialog from '@/components/admin/AdminConfirmDialog.vue'
import type { TableColumn } from '@/components/admin/AdminDataTable.vue'

const router = useRouter()
const store = useAdminExperiencesStore()

const columns: TableColumn[] = [
  { key: 'company', label: 'Company' },
  { key: 'position', label: 'Position' },
  { key: 'experience_type', label: 'Type', width: '100px' },
  { key: 'duration', label: 'Duration' },
]

const activeFilter = ref<string>('')
const deleteTarget = ref<number | null>(null)
const deleting = ref(false)

onMounted(() => {
  store.fetchAll()
})

function filterByType(type: string) {
  activeFilter.value = type
  store.fetchAll(type ? { type } : {})
}

function editExperience(row: Record<string, unknown>) {
  router.push({ name: 'admin-experience-edit', params: { id: row.id as number } })
}

async function confirmDelete() {
  if (!deleteTarget.value) return
  deleting.value = true
  await store.remove(deleteTarget.value)
  deleting.value = false
  deleteTarget.value = null
}
</script>

<template>
  <div class="admin-view">
    <div class="view-header">
      <h2 class="view-title"><span class="prompt">$</span> cat experience.log</h2>
      <RouterLink :to="{ name: 'admin-experience-new' }" class="new-btn">
        <span class="btn-prompt">$</span> new
      </RouterLink>
    </div>

    <div class="filter-tabs">
      <button
        :class="['filter-tab', activeFilter === '' ? 'is-active' : '']"
        @click="filterByType('')"
      >
        All
      </button>
      <button
        :class="['filter-tab', activeFilter === 'work' ? 'is-active' : '']"
        @click="filterByType('work')"
      >
        Work
      </button>
      <button
        :class="['filter-tab', activeFilter === 'education' ? 'is-active' : '']"
        @click="filterByType('education')"
      >
        Education
      </button>
    </div>

    <div class="table-card">
      <AdminDataTable
        :columns="columns"
        :rows="(store.experiences as unknown as Record<string, unknown>[])"
        :loading="store.loading"
        :pagination="store.pagination"
        empty-message="No experiences yet."
        @row-click="editExperience"
        @page-change="(page) => store.fetchAll({ page, type: activeFilter || undefined })"
      >
        <template #cell-experience_type="{ value }">
          <span :class="['type-badge', `type-${value}`]">{{ value }}</span>
        </template>
        <template #actions="{ row }">
          <button class="action-btn" @click.stop="editExperience(row)">edit</button>
          <button class="action-btn action-delete" @click.stop="deleteTarget = row.id as number">
            del
          </button>
        </template>
      </AdminDataTable>
    </div>

    <AdminConfirmDialog
      :open="deleteTarget !== null"
      title="delete experience"
      message="This will permanently delete this experience. Continue?"
      confirm-label="delete"
      :loading="deleting"
      @confirm="confirmDelete"
      @cancel="deleteTarget = null"
    />
  </div>
</template>

<style scoped>
.admin-view {
  max-width: 1000px;
}

.view-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}

.view-title {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.9rem;
  font-weight: 600;
  color: #1c1917;
}

:is(.dark *).view-title {
  color: #e7e5e4;
}

.prompt {
  color: var(--skin-600);
}

:is(.dark *).prompt {
  color: var(--skin-400);
}

.new-btn {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  font-weight: 600;
  color: white;
  background: linear-gradient(135deg, var(--skin-600), var(--skin-700));
  padding: 0.45rem 1rem;
  border-radius: 8px;
  text-decoration: none;
  transition: all 0.2s ease;
}

.new-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(var(--skin-rgb), 0.25);
}

:is(.dark *).new-btn {
  background: linear-gradient(135deg, var(--skin-500), var(--skin-600));
}

.btn-prompt {
  opacity: 0.6;
}

.filter-tabs {
  display: flex;
  gap: 0.35rem;
  margin-bottom: 1rem;
}

.filter-tab {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem;
  font-weight: 500;
  padding: 0.4rem 0.8rem;
  border-radius: 6px;
  border: 1px solid #e7e5e4;
  background: transparent;
  color: #78716c;
  cursor: pointer;
  transition: all 0.15s ease;
}

.filter-tab:hover {
  background: rgba(var(--skin-rgb), 0.04);
}

.filter-tab.is-active {
  color: var(--skin-700);
  background: rgba(var(--skin-rgb), 0.1);
  border-color: rgba(var(--skin-rgb), 0.3);
  font-weight: 600;
}

:is(.dark *).filter-tab {
  border-color: rgba(var(--skin-light-rgb), 0.1);
  color: #a8a29e;
}

:is(.dark *).filter-tab.is-active {
  color: var(--skin-300);
  background: rgba(var(--skin-light-rgb), 0.12);
  border-color: rgba(var(--skin-light-rgb), 0.25);
}

.table-card {
  background: #ffffff;
  border: 1px solid #e7e5e4;
  border-radius: 12px;
  overflow: hidden;
  transition:
    background 0.3s ease,
    border-color 0.3s ease;
}

:is(.dark *).table-card {
  background: #1c1917;
  border-color: rgba(var(--skin-light-rgb), 0.08);
}

.type-badge {
  font-size: 0.65rem;
  font-weight: 600;
  padding: 0.15rem 0.4rem;
  border-radius: 4px;
}

.type-work {
  color: var(--skin-700);
  background: rgba(var(--skin-rgb), 0.1);
}

.type-education {
  color: #7c3aed;
  background: rgba(124, 58, 237, 0.1);
}

:is(.dark *).type-work {
  color: var(--skin-300);
  background: rgba(var(--skin-light-rgb), 0.12);
}

:is(.dark *).type-education {
  color: #a78bfa;
  background: rgba(167, 139, 250, 0.12);
}

.action-btn {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.7rem;
  font-weight: 600;
  color: var(--skin-600);
  background: none;
  border: none;
  cursor: pointer;
  padding: 0.2rem 0.4rem;
  border-radius: 4px;
  transition: all 0.15s ease;
}

.action-btn:hover {
  background: rgba(var(--skin-rgb), 0.08);
}

.action-delete {
  color: #ef4444;
}

.action-delete:hover {
  background: rgba(239, 68, 68, 0.08);
}

:is(.dark *).action-btn {
  color: var(--skin-400);
}

:is(.dark *).action-delete {
  color: #f87171;
}
</style>
