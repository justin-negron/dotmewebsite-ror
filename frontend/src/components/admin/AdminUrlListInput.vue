<script setup lang="ts">
import { ref, watch } from 'vue'

const props = defineProps<{
  modelValue: string[]
  placeholder?: string
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string[]]
}>()

// The textarea keeps its own raw text so typing a newline is not immediately
// normalised away; the parent only ever receives the cleaned list.
const raw = ref(props.modelValue.join('\n'))

function parseUrls(text: string): string[] {
  return text
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => line.length > 0)
}

watch(
  () => props.modelValue,
  (urls) => {
    // Resync only when the parent's list differs from what the textarea already
    // holds (e.g. after the project loads), so echoed updates do not move the cursor.
    if (urls.join('\n') !== parseUrls(raw.value).join('\n')) {
      raw.value = urls.join('\n')
    }
  }
)

// Read the value off the event rather than relying on v-model ordering, so
// the emitted list always reflects the keystroke that triggered it.
function onInput(e: Event) {
  raw.value = (e.target as HTMLTextAreaElement).value
  emit('update:modelValue', parseUrls(raw.value))
}
</script>

<template>
  <div class="url-list">
    <textarea
      :value="raw"
      class="url-textarea"
      :rows="Math.max(3, modelValue.length + 1)"
      :placeholder="placeholder || 'One URL per line'"
      spellcheck="false"
      @input="onInput"
    />

    <ol v-if="modelValue.length" class="thumb-list" aria-label="Slide order preview">
      <li v-for="(url, i) in modelValue" :key="`${i}-${url}`" class="thumb">
        <img :src="url" alt="" class="thumb-img" loading="lazy" decoding="async" />
        <span class="thumb-index">{{ i + 1 }}</span>
      </li>
    </ol>
  </div>
</template>

<style scoped>
.url-list {
  width: 100%;
}

.url-textarea {
  width: 100%;
  padding: 0.55rem 0.7rem;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  line-height: 1.5;
  color: #1c1917;
  background: #fafaf9;
  border: 1.5px solid #e7e5e4;
  border-radius: 8px;
  outline: none;
  resize: vertical;
  white-space: pre;
  overflow-wrap: normal;
  overflow-x: auto;
  transition:
    border-color 0.2s ease,
    box-shadow 0.2s ease;
}

.url-textarea:focus {
  border-color: var(--skin-400);
  box-shadow: 0 0 0 3px rgba(var(--skin-rgb), 0.08);
}

:is(.dark *).url-textarea {
  color: #e7e5e4;
  background: rgba(var(--skin-light-rgb), 0.03);
  border-color: rgba(var(--skin-light-rgb), 0.1);
}

:is(.dark *).url-textarea:focus {
  border-color: var(--skin-500);
  box-shadow: 0 0 0 3px rgba(var(--skin-light-rgb), 0.06);
}

.thumb-list {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin: 0.6rem 0 0;
  padding: 0;
  list-style: none;
}

.thumb {
  position: relative;
  width: 96px;
  height: 64px;
  border-radius: 6px;
  overflow: hidden;
  background: #e7e5e4;
}

:is(.dark *).thumb {
  background: #292524;
}

.thumb-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.thumb-index {
  position: absolute;
  top: 4px;
  left: 4px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.65rem;
  font-weight: 600;
  line-height: 1;
  padding: 2px 5px;
  border-radius: 4px;
  color: #fafaf9;
  background: rgba(28, 25, 23, 0.75);
}
</style>
