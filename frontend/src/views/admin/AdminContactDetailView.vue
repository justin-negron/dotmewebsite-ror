<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAdminContactsStore } from '@/stores'
import AdminConfirmDialog from '@/components/admin/AdminConfirmDialog.vue'

const route = useRoute()
const router = useRouter()
const store = useAdminContactsStore()

const showDeleteDialog = ref(false)
const deleting = ref(false)

onMounted(async () => {
  await store.fetchOne(route.params.id as string)
  // Auto-mark as read
  if (store.currentContact?.status === 'new') {
    await store.updateStatus(route.params.id as string, 'read')
  }
})

async function markArchived() {
  await store.updateStatus(route.params.id as string, 'archived')
}

async function confirmDelete() {
  deleting.value = true
  const success = await store.remove(route.params.id as string)
  deleting.value = false
  showDeleteDialog.value = false
  if (success) {
    router.push({ name: 'admin-contacts' })
  }
}

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}
</script>

<template>
  <div class="detail-view">
    <div class="detail-header">
      <h2 class="detail-title">
        <span class="prompt">$</span> cat message.txt
      </h2>
      <RouterLink :to="{ name: 'admin-contacts' }" class="back-link">
        &larr; inbox
      </RouterLink>
    </div>

    <!-- Loading -->
    <div v-if="store.loading && !store.currentContact" class="loading-state">
      <span class="loading-text">loading...</span>
    </div>

    <template v-else-if="store.currentContact">
      <div class="message-card">
        <div class="card-header">
          <div class="dots">
            <span class="dot dot-red" />
            <span class="dot dot-yellow" />
            <span class="dot dot-green" />
          </div>
          <span class="header-title">message</span>
          <span :class="['status-badge', `status-${store.currentContact.status}`]">
            {{ store.currentContact.status }}
          </span>
        </div>

        <div class="card-body">
          <div class="meta-row">
            <span class="meta-label">from:</span>
            <span class="meta-value">{{ store.currentContact.name }} &lt;{{ store.currentContact.email }}&gt;</span>
          </div>
          <div v-if="store.currentContact.subject" class="meta-row">
            <span class="meta-label">subject:</span>
            <span class="meta-value">{{ store.currentContact.subject }}</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">date:</span>
            <span class="meta-value">{{ formatDate(store.currentContact.created_at) }}</span>
          </div>

          <div class="message-content">
            {{ store.currentContact.message }}
          </div>
        </div>
      </div>

      <div class="action-bar">
        <button
          v-if="store.currentContact.status !== 'archived'"
          class="action-btn"
          @click="markArchived"
        >
          <span class="btn-prompt">$</span> archive
        </button>
        <button class="action-btn action-delete" @click="showDeleteDialog = true">
          <span class="btn-prompt">$</span> delete
        </button>
      </div>
    </template>

    <AdminConfirmDialog
      :open="showDeleteDialog"
      title="delete message"
      message="This will permanently delete this message. Continue?"
      confirm-label="delete"
      :loading="deleting"
      @confirm="confirmDelete"
      @cancel="showDeleteDialog = false"
    />
  </div>
</template>

<style scoped>
.detail-view {
  max-width: 700px;
}

.detail-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}

.detail-title {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.9rem;
  font-weight: 600;
  color: #1c1917;
}

:is(.dark *).detail-title {
  color: #e7e5e4;
}

.prompt {
  color: var(--skin-600);
}

:is(.dark *).prompt {
  color: var(--skin-400);
}

.back-link {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem;
  color: var(--skin-600);
  text-decoration: none;
}

:is(.dark *).back-link {
  color: var(--skin-400);
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

.message-card {
  border-radius: 14px;
  overflow: hidden;
  background: #ffffff;
  border: 1px solid #e7e5e4;
  transition:
    background 0.3s ease,
    border-color 0.3s ease;
}

:is(.dark *).message-card {
  background: #1c1917;
  border-color: rgba(var(--skin-light-rgb), 0.08);
}

.card-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  background: #f5f5f4;
  border-bottom: 1px solid #e7e5e4;
}

:is(.dark *).card-header {
  background: rgba(var(--skin-light-rgb), 0.03);
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

.header-title {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem;
  color: #78716c;
  font-weight: 500;
  flex: 1;
}

:is(.dark *).header-title {
  color: #a8a29e;
}

.status-badge {
  font-family: 'JetBrains Mono', monospace;
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

.card-body {
  padding: 1.25rem;
}

.meta-row {
  display: flex;
  gap: 0.5rem;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  margin-bottom: 0.35rem;
}

.meta-label {
  color: var(--skin-600);
  font-weight: 600;
  min-width: 4.5rem;
}

:is(.dark *).meta-label {
  color: var(--skin-400);
}

.meta-value {
  color: #44403c;
}

:is(.dark *).meta-value {
  color: #d6d3d1;
}

.message-content {
  margin-top: 1.25rem;
  padding-top: 1rem;
  border-top: 1px solid #e7e5e4;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.82rem;
  color: #1c1917;
  line-height: 1.7;
  white-space: pre-wrap;
}

:is(.dark *).message-content {
  border-color: rgba(var(--skin-light-rgb), 0.06);
  color: #e7e5e4;
}

.action-bar {
  display: flex;
  gap: 0.75rem;
  margin-top: 1rem;
  justify-content: flex-end;
}

.action-btn {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  font-weight: 600;
  padding: 0.5rem 1rem;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s ease;
  color: var(--skin-700);
  background: rgba(var(--skin-rgb), 0.05);
  border: 1.5px dashed rgba(var(--skin-rgb), 0.25);
}

.action-btn:hover {
  background: rgba(var(--skin-rgb), 0.09);
  border-color: rgba(var(--skin-rgb), 0.45);
}

:is(.dark *).action-btn {
  color: var(--skin-400);
  background: rgba(var(--skin-light-rgb), 0.04);
  border-color: rgba(var(--skin-light-rgb), 0.15);
}

.action-delete {
  color: #ef4444;
  border-color: rgba(239, 68, 68, 0.25);
  background: rgba(239, 68, 68, 0.04);
}

.action-delete:hover {
  background: rgba(239, 68, 68, 0.08);
  border-color: rgba(239, 68, 68, 0.45);
}

:is(.dark *).action-delete {
  color: #f87171;
  background: rgba(239, 68, 68, 0.06);
  border-color: rgba(239, 68, 68, 0.2);
}

.btn-prompt {
  opacity: 0.5;
}
</style>
