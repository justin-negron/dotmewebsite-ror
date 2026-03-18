<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAdminContactsStore } from '@/stores'
import AdminDataTable from '@/components/admin/AdminDataTable.vue'
import AdminConfirmDialog from '@/components/admin/AdminConfirmDialog.vue'
import type { TableColumn } from '@/components/admin/AdminDataTable.vue'

const router = useRouter()
const store = useAdminContactsStore()

const columns: TableColumn[] = [
  { key: 'name', label: 'Name' },
  { key: 'email', label: 'Email' },
  { key: 'subject', label: 'Subject' },
  { key: 'status', label: 'Status', width: '90px' },
  { key: 'created_at', label: 'Date', width: '110px' },
]

const activeFilter = ref<string>('')
const deleteTarget = ref<number | null>(null)
const deleting = ref(false)

onMounted(() => {
  store.fetchAll()
})

function filterByStatus(status: string) {
  activeFilter.value = status
  store.fetchAll(status ? { status } : {})
}

function viewContact(row: Record<string, unknown>) {
  router.push({ name: 'admin-contact-detail', params: { id: row.id as number } })
}

async function confirmDelete() {
  if (!deleteTarget.value) return
  deleting.value = true
  await store.remove(deleteTarget.value)
  deleting.value = false
  deleteTarget.value = null
}

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
  })
}
</script>

<template>
  <div class="admin-view">
    <div class="view-header">
      <h2 class="view-title"><span class="prompt">$</span> mail -s "inbox"</h2>
    </div>

    <div class="filter-tabs">
      <button
        :class="['filter-tab', activeFilter === '' ? 'is-active' : '']"
        @click="filterByStatus('')"
      >
        All
      </button>
      <button
        :class="['filter-tab', activeFilter === 'new' ? 'is-active' : '']"
        @click="filterByStatus('new')"
      >
        New
      </button>
      <button
        :class="['filter-tab', activeFilter === 'read' ? 'is-active' : '']"
        @click="filterByStatus('read')"
      >
        Read
      </button>
      <button
        :class="['filter-tab', activeFilter === 'archived' ? 'is-active' : '']"
        @click="filterByStatus('archived')"
      >
        Archived
      </button>
    </div>

    <div class="table-card">
      <AdminDataTable
        :columns="columns"
        :rows="(store.contacts as unknown as Record<string, unknown>[])"
        :loading="store.loading"
        :pagination="store.pagination"
        empty-message="No messages yet."
        @row-click="viewContact"
        @page-change="(page) => store.fetchAll({ page, status: activeFilter || undefined })"
      >
        <template #cell-status="{ value }">
          <span :class="['status-badge', `status-${value}`]">{{ value }}</span>
        </template>
        <template #cell-created_at="{ value }">
          {{ formatDate(value as string) }}
        </template>
        <template #actions="{ row }">
          <button class="action-btn" @click.stop="viewContact(row)">view</button>
          <button class="action-btn action-delete" @click.stop="deleteTarget = row.id as number">
            del
          </button>
        </template>
      </AdminDataTable>
    </div>

    <AdminConfirmDialog
      :open="deleteTarget !== null"
      title="delete contact"
      message="This will permanently delete this message. Continue?"
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

.status-badge {
  font-size: 0.65rem;
  font-weight: 600;
  padding: 0.15rem 0.4rem;
  border-radius: 4px;
}

.status-new {
  color: #2563eb;
  background: rgba(37, 99, 235, 0.1);
}

.status-read {
  color: #16a34a;
  background: rgba(22, 163, 74, 0.1);
}

.status-archived {
  color: #78716c;
  background: rgba(120, 113, 108, 0.08);
}

:is(.dark *).status-new {
  color: #60a5fa;
  background: rgba(96, 165, 250, 0.12);
}

:is(.dark *).status-read {
  color: #4ade80;
  background: rgba(74, 222, 128, 0.12);
}

:is(.dark *).status-archived {
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
