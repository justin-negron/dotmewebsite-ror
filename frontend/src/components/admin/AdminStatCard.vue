<script setup lang="ts">
defineProps<{
  label: string
  value: number | string
  accent?: boolean
}>()
</script>

<template>
  <div :class="['stat-card', accent ? 'is-accent' : '']">
    <p class="stat-value">{{ value }}</p>
    <p class="stat-label">{{ label }}</p>
  </div>
</template>

<style scoped>
.stat-card {
  padding: 1rem 1.25rem;
  background: #ffffff;
  border: 1px solid #e7e5e4;
  border-radius: 12px;
  transition:
    background 0.3s ease,
    border-color 0.3s ease;
}

:is(.dark *).stat-card {
  background: #1c1917;
  border-color: rgba(var(--skin-light-rgb), 0.08);
}

.stat-card.is-accent {
  border-color: rgba(var(--skin-rgb), 0.25);
  background: rgba(var(--skin-rgb), 0.02);
}

:is(.dark *).stat-card.is-accent {
  border-color: rgba(var(--skin-light-rgb), 0.15);
  background: rgba(var(--skin-light-rgb), 0.04);
}

.stat-value {
  font-family: 'JetBrains Mono', monospace;
  font-size: 1.5rem;
  font-weight: 700;
  color: #1c1917;
  line-height: 1.2;
}

:is(.dark *).stat-value {
  color: #e7e5e4;
}

.stat-label {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.7rem;
  color: #78716c;
  margin-top: 0.25rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

:is(.dark *).stat-label {
  color: #57534e;
}
</style>
