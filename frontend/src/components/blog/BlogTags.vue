<script setup lang="ts">
defineProps<{
  tags: string[]
  activeTag: string | null
}>()

const emit = defineEmits<{
  select: [tag: string | null]
}>()
</script>

<template>
  <div class="tag-bar" role="tablist" aria-label="Filter by tag">
    <button
      :class="['tag-filter', { 'is-active': !activeTag }]"
      role="tab"
      :aria-selected="!activeTag"
      @click="emit('select', null)"
    >
      All
    </button>
    <button
      v-for="tag in tags"
      :key="tag"
      :class="['tag-filter', { 'is-active': activeTag === tag }]"
      role="tab"
      :aria-selected="activeTag === tag"
      @click="emit('select', tag)"
    >
      <span class="tag-flag" aria-hidden="true">--</span>{{ tag }}
    </button>
  </div>
</template>

<style scoped>
/* ===================================================================
   Tag filter bar — terminal-flag inspired
   =================================================================== */
.tag-bar {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  padding-bottom: 0.25rem;
}

.tag-filter {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  font-weight: 500;
  padding: 6px 14px;
  border-radius: 999px;
  background: rgba(0, 0, 0, 0.03);
  color: #78716c;
  border: 1px solid transparent;
  cursor: pointer;
  transition: all 0.2s ease;
  white-space: nowrap;
}

.tag-filter:hover {
  color: var(--skin-600);
  background: rgba(var(--skin-rgb), 0.06);
}

.tag-filter.is-active {
  color: var(--skin-700);
  background: rgba(var(--skin-rgb), 0.1);
  border-color: rgba(var(--skin-rgb), 0.2);
}

:is(.dark *).tag-filter {
  background: rgba(255, 255, 255, 0.04);
  color: #a8a29e;
}

:is(.dark *).tag-filter:hover {
  color: var(--skin-400);
  background: rgba(var(--skin-light-rgb), 0.08);
}

:is(.dark *).tag-filter.is-active {
  color: var(--skin-400);
  background: rgba(var(--skin-light-rgb), 0.12);
  border-color: rgba(var(--skin-light-rgb), 0.2);
}

/* ===================================================================
   Terminal-flag prefix
   =================================================================== */
.tag-flag {
  color: var(--skin-500);
  opacity: 0.5;
  margin-right: 1px;
  font-weight: 400;
}

:is(.dark *).tag-flag {
  color: var(--skin-400);
}

.tag-filter.is-active .tag-flag {
  opacity: 0.8;
}
</style>
