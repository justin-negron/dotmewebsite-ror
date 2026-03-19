<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAdminProjectsStore } from '@/stores'
import AdminDataTable from '@/components/admin/AdminDataTable.vue'
import AdminConfirmDialog from '@/components/admin/AdminConfirmDialog.vue'
import type { TableColumn } from '@/components/admin/AdminDataTable.vue'

const router = useRouter()
const store = useAdminProjectsStore()

const columns: TableColumn[] = [
  { key: 'title', label: 'Title' },
  { key: 'tech_stack', label: 'Tech Stack' },
  { key: 'featured', label: 'Featured', width: '90px' },
  { key: 'display_order', label: 'Order', width: '70px' },
]

const deleteTarget = ref<number | null>(null)
const deleting = ref(false)

onMounted(() => {
  store.fetchAll()
})

function editProject(row: Record<string, unknown>) {
  router.push({ name: 'admin-project-edit', params: { id: row.id as number } })
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
      <h2 class="view-title"><span class="prompt">$</span> ls projects/</h2>
      <RouterLink :to="{ name: 'admin-project-new' }" class="new-btn">
        <span class="btn-prompt">$</span> new
      </RouterLink>
    </div>

    <div class="table-card">
      <AdminDataTable
        :columns="columns"
        :rows="(store.projects as unknown as Record<string, unknown>[])"
        :loading="store.loading"
        :pagination="store.pagination"
        empty-message="No projects yet. Create your first one."
        @row-click="editProject"
        @page-change="(page) => store.fetchAll({ page })"
      >
        <template #cell-tech_stack="{ value }">
          <span class="tech-tags">
            <span v-for="tech in (value as string[])" :key="tech" class="tech-tag">{{ tech }}</span>
          </span>
        </template>
        <template #cell-featured="{ value }">
          <span :class="['badge', value ? 'badge-yes' : 'badge-no']">
            {{ value ? 'yes' : 'no' }}
          </span>
        </template>
        <template #actions="{ row }">
          <button class="action-btn" @click.stop="editProject(row)">edit</button>
          <button class="action-btn action-delete" @click.stop="deleteTarget = row.id as number">
            del
          </button>
        </template>
      </AdminDataTable>
    </div>

    <AdminConfirmDialog
      :open="deleteTarget !== null"
      title="delete project"
      message="This will permanently delete this project. Continue?"
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

.tech-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.25rem;
}

.tech-tag {
  font-size: 0.65rem;
  padding: 0.1rem 0.35rem;
  background: rgba(var(--skin-rgb), 0.08);
  color: var(--skin-700);
  border-radius: 3px;
}

:is(.dark *).tech-tag {
  background: rgba(var(--skin-light-rgb), 0.1);
  color: var(--skin-300);
}

.badge {
  font-size: 0.65rem;
  font-weight: 600;
  padding: 0.15rem 0.4rem;
  border-radius: 4px;
}

.badge-yes {
  color: #16a34a;
  background: rgba(22, 163, 74, 0.1);
}

.badge-no {
  color: #78716c;
  background: rgba(120, 113, 108, 0.08);
}

:is(.dark *).badge-yes {
  color: #4ade80;
  background: rgba(74, 222, 128, 0.12);
}

:is(.dark *).badge-no {
  color: #a8a29e;
  background: rgba(168, 162, 158, 0.08);
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
