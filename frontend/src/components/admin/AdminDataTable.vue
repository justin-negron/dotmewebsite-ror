<script setup lang="ts">
import type { PaginationMeta } from '@/types'

export interface TableColumn {
  key: string
  label: string
  width?: string
}

defineProps<{
  columns: TableColumn[]
  rows: Record<string, unknown>[]
  loading?: boolean
  pagination?: PaginationMeta | null
  emptyMessage?: string
}>()

const emit = defineEmits<{
  'page-change': [page: number]
  'row-click': [row: Record<string, unknown>]
}>()
</script>

<template>
  <div class="data-table-wrapper">
    <!-- Loading state -->
    <div v-if="loading" class="table-loading">
      <span class="loading-text">loading...</span>
    </div>

    <!-- Empty state -->
    <div v-else-if="rows.length === 0" class="table-empty">
      <p class="empty-text">{{ emptyMessage || 'No records found.' }}</p>
    </div>

    <!-- Table -->
    <div v-else class="table-scroll">
      <table class="data-table">
        <thead>
          <tr>
            <th v-for="col in columns" :key="col.key" :style="col.width ? { width: col.width } : {}">
              {{ col.label }}
            </th>
            <th class="actions-col">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="(row, idx) in rows"
            :key="(row.id as number) ?? idx"
            class="table-row"
            @click="emit('row-click', row)"
          >
            <td v-for="col in columns" :key="col.key">
              <slot :name="`cell-${col.key}`" :row="row" :value="row[col.key]">
                {{ row[col.key] }}
              </slot>
            </td>
            <td class="actions-cell">
              <slot name="actions" :row="row" />
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Pagination -->
    <div v-if="pagination && pagination.total_pages > 1" class="table-pagination">
      <button
        class="page-btn"
        :disabled="pagination.current_page <= 1"
        @click="emit('page-change', pagination.current_page - 1)"
      >
        prev
      </button>
      <span class="page-info">
        {{ pagination.current_page }} / {{ pagination.total_pages }}
      </span>
      <button
        class="page-btn"
        :disabled="pagination.current_page >= pagination.total_pages"
        @click="emit('page-change', pagination.current_page + 1)"
      >
        next
      </button>
    </div>
  </div>
</template>

<style scoped>
.data-table-wrapper {
  width: 100%;
}

.table-loading,
.table-empty {
  padding: 2rem;
  text-align: center;
}

.loading-text {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
  color: #78716c;
  animation: blink 1.2s steps(1) infinite;
}

@keyframes blink {
  50% {
    opacity: 0.4;
  }
}

.empty-text {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
  color: #a8a29e;
}

:is(.dark *).empty-text {
  color: #57534e;
}

.table-scroll {
  overflow-x: auto;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
}

.data-table th {
  text-align: left;
  padding: 0.6rem 0.75rem;
  font-size: 0.7rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: #78716c;
  border-bottom: 1px solid #e7e5e4;
  white-space: nowrap;
}

:is(.dark *).data-table th {
  color: #a8a29e;
  border-color: rgba(var(--skin-light-rgb), 0.08);
}

.actions-col {
  width: 100px;
  text-align: right;
}

.data-table td {
  padding: 0.6rem 0.75rem;
  color: #44403c;
  border-bottom: 1px solid #f5f5f4;
  vertical-align: middle;
}

:is(.dark *).data-table td {
  color: #d6d3d1;
  border-color: rgba(var(--skin-light-rgb), 0.04);
}

.table-row {
  cursor: pointer;
  transition: background 0.15s ease;
}

.table-row:hover {
  background: rgba(var(--skin-rgb), 0.03);
}

:is(.dark *).table-row:hover {
  background: rgba(var(--skin-light-rgb), 0.03);
}

.actions-cell {
  text-align: right;
  white-space: nowrap;
}

.table-pagination {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  padding: 0.75rem;
  border-top: 1px solid #e7e5e4;
}

:is(.dark *).table-pagination {
  border-color: rgba(var(--skin-light-rgb), 0.08);
}

.page-btn {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--skin-600);
  background: none;
  border: none;
  cursor: pointer;
  padding: 0.3rem 0.5rem;
  border-radius: 4px;
  transition: all 0.15s ease;
}

.page-btn:hover:not(:disabled) {
  background: rgba(var(--skin-rgb), 0.06);
}

.page-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

:is(.dark *).page-btn {
  color: var(--skin-400);
}

.page-info {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.7rem;
  color: #78716c;
}

:is(.dark *).page-info {
  color: #57534e;
}
</style>
