<script setup lang="ts">
import { ref } from 'vue'

const props = defineProps<{
  modelValue: string[]
  placeholder?: string
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string[]]
}>()

const input = ref('')

function addTag() {
  const tag = input.value.trim()
  if (tag && !props.modelValue.includes(tag)) {
    emit('update:modelValue', [...props.modelValue, tag])
  }
  input.value = ''
}

function removeTag(index: number) {
  const updated = [...props.modelValue]
  updated.splice(index, 1)
  emit('update:modelValue', updated)
}

function handleKeydown(e: KeyboardEvent) {
  if (e.key === 'Enter') {
    e.preventDefault()
    addTag()
  }
  if (e.key === 'Backspace' && !input.value && props.modelValue.length > 0) {
    removeTag(props.modelValue.length - 1)
  }
}
</script>

<template>
  <div class="tag-input-wrapper">
    <div class="tag-list">
      <span v-for="(tag, idx) in modelValue" :key="tag" class="tag">
        {{ tag }}
        <button type="button" class="tag-remove" @click="removeTag(idx)">&times;</button>
      </span>
      <input
        v-model="input"
        type="text"
        class="tag-input"
        :placeholder="modelValue.length === 0 ? (placeholder || 'Type + Enter') : ''"
        @keydown="handleKeydown"
      />
    </div>
  </div>
</template>

<style scoped>
.tag-input-wrapper {
  width: 100%;
}

.tag-list {
  display: flex;
  flex-wrap: wrap;
  gap: 0.35rem;
  padding: 0.45rem 0.6rem;
  background: #fafaf9;
  border: 1.5px solid #e7e5e4;
  border-radius: 8px;
  min-height: 2.4rem;
  align-items: center;
  transition:
    border-color 0.2s ease,
    background 0.2s ease;
}

.tag-list:focus-within {
  border-color: var(--skin-400);
  box-shadow: 0 0 0 3px rgba(var(--skin-rgb), 0.08);
}

:is(.dark *).tag-list {
  background: rgba(var(--skin-light-rgb), 0.03);
  border-color: rgba(var(--skin-light-rgb), 0.1);
}

:is(.dark *).tag-list:focus-within {
  border-color: var(--skin-500);
  box-shadow: 0 0 0 3px rgba(var(--skin-light-rgb), 0.06);
}

.tag {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.15rem 0.5rem;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.7rem;
  font-weight: 500;
  color: var(--skin-700);
  background: rgba(var(--skin-rgb), 0.1);
  border-radius: 4px;
}

:is(.dark *).tag {
  color: var(--skin-300);
  background: rgba(var(--skin-light-rgb), 0.12);
}

.tag-remove {
  font-size: 0.85rem;
  line-height: 1;
  color: inherit;
  opacity: 0.6;
  background: none;
  border: none;
  cursor: pointer;
  padding: 0;
  transition: opacity 0.15s ease;
}

.tag-remove:hover {
  opacity: 1;
}

.tag-input {
  flex: 1;
  min-width: 80px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
  color: #1c1917;
  background: transparent;
  border: none;
  outline: none;
  padding: 0.1rem 0;
}

.tag-input::placeholder {
  color: #a8a29e;
}

:is(.dark *).tag-input {
  color: #e7e5e4;
}

:is(.dark *).tag-input::placeholder {
  color: #57534e;
}
</style>
