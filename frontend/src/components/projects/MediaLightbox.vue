<script setup lang="ts">
import { ref, computed, watch, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { trapTab } from '@/components/common/focusTrap'

const props = defineProps<{
  urls: string[]
  startIndex: number
  title: string
}>()

const emit = defineEmits<{
  close: []
}>()

const index = ref(props.startIndex)
const count = computed(() => props.urls.length)
const current = computed(() => props.urls[index.value] ?? '')
const hasMany = computed(() => count.value > 1)

// The slide list follows the theme, so it can shrink while the viewer is open.
watch(count, (n) => {
  if (n === 0) emit('close')
  else if (index.value >= n) index.value = n - 1
})

const dialogRef = ref<HTMLElement | null>(null)
const closeBtn = ref<HTMLButtonElement | null>(null)
let previouslyFocused: HTMLElement | null = null
let previousBodyOverflow = ''

function go(delta: number) {
  if (!hasMany.value) return
  index.value = (index.value + delta + count.value) % count.value
}

function altFor(i: number): string {
  return hasMany.value ? `${props.title}, image ${i + 1} of ${count.value}` : props.title
}

function onKeydown(e: KeyboardEvent) {
  switch (e.key) {
    case 'Escape':
      e.preventDefault()
      emit('close')
      break
    case 'ArrowLeft':
      e.preventDefault()
      go(-1)
      break
    case 'ArrowRight':
      e.preventDefault()
      go(1)
      break
    case 'Tab':
      trapTab(dialogRef.value, e)
      break
  }
}

onMounted(async () => {
  previouslyFocused = document.activeElement as HTMLElement | null
  previousBodyOverflow = document.body.style.overflow
  document.body.style.overflow = 'hidden'
  document.addEventListener('keydown', onKeydown)
  await nextTick()
  closeBtn.value?.focus()
})

onBeforeUnmount(() => {
  document.removeEventListener('keydown', onKeydown)
  document.body.style.overflow = previousBodyOverflow
  previouslyFocused?.focus()
})
</script>

<template>
  <Teleport to="body">
    <div
      ref="dialogRef"
      class="lightbox"
      role="dialog"
      aria-modal="true"
      :aria-label="`${title} image viewer`"
      @click.self="emit('close')"
    >
      <button
        ref="closeBtn"
        type="button"
        class="lb-btn lb-close"
        aria-label="Close image viewer"
        @click="emit('close')"
      >
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>

      <button
        v-if="hasMany"
        type="button"
        class="lb-btn lb-prev"
        aria-label="Previous image"
        @click="go(-1)"
      >
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
        </svg>
      </button>

      <figure class="lb-figure" @click.self="emit('close')">
        <Transition name="lb-slide" mode="out-in">
          <img :key="current" :src="current" :alt="altFor(index)" class="lb-img" decoding="async" />
        </Transition>
        <figcaption class="lb-caption">
          <span class="lb-title">{{ title }}</span>
          <span v-if="hasMany" class="lb-counter" aria-hidden="true">
            {{ index + 1 }} / {{ count }}
          </span>
        </figcaption>
        <span v-if="hasMany" class="sr-only" aria-live="polite">
          Image {{ index + 1 }} of {{ count }}
        </span>
      </figure>

      <button
        v-if="hasMany"
        type="button"
        class="lb-btn lb-next"
        aria-label="Next image"
        @click="go(1)"
      >
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
        </svg>
      </button>
    </div>
  </Teleport>
</template>

<style scoped>
/* Above the floating terminal (1010), header (1020) and mobile menu (1040). */
.lightbox {
  position: fixed;
  inset: 0;
  z-index: 1100;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
  background: rgba(12, 10, 9, 0.92);
  backdrop-filter: blur(6px);
  animation: lbFade 0.2s ease;
}

/* The backdrop stays dark in light mode, where the global ring is the darker --skin-700. */
.lightbox :focus-visible {
  outline-color: var(--skin-400);
}

.lb-figure {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  margin: 0;
  max-width: min(1600px, 92vw);
  max-height: 90vh;
}

.lb-img {
  display: block;
  max-width: 100%;
  max-height: calc(90vh - 48px);
  object-fit: contain;
  border-radius: 10px;
  box-shadow: 0 24px 64px rgba(0, 0, 0, 0.5);
  animation: lbZoom 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

.lb-caption {
  display: flex;
  align-items: baseline;
  gap: 12px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  color: #d6d3d1;
}

.lb-counter {
  color: #a8a29e;
}

.lb-slide-enter-active,
.lb-slide-leave-active {
  transition: opacity 0.2s ease;
}

.lb-slide-enter-from,
.lb-slide-leave-to {
  opacity: 0;
}

/* Buttons */
.lb-btn {
  position: fixed;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 44px;
  height: 44px;
  padding: 0;
  border: 0;
  border-radius: 999px;
  color: #fafaf9;
  background: rgba(250, 250, 249, 0.1);
  cursor: pointer;
  transition: background 0.2s ease;
}

.lb-btn svg {
  width: 22px;
  height: 22px;
}

.lb-btn:hover {
  background: rgba(250, 250, 249, 0.22);
}

.lb-close {
  top: 16px;
  right: 16px;
}

.lb-prev,
.lb-next {
  top: 50%;
  transform: translateY(-50%);
}

.lb-prev {
  left: 16px;
}

.lb-next {
  right: 16px;
}

/* Keep the arrows clear of the image on narrow screens. */
@media (max-width: 640px) {
  .lightbox {
    padding: 16px 16px 72px;
  }

  .lb-prev,
  .lb-next {
    top: auto;
    bottom: 16px;
    transform: none;
  }

  .lb-prev {
    left: calc(50% - 52px);
  }

  .lb-next {
    right: calc(50% - 52px);
  }
}

@keyframes lbFade {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes lbZoom {
  from {
    opacity: 0;
    transform: scale(0.92);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

@media (prefers-reduced-motion: reduce) {
  .lightbox,
  .lb-img {
    animation: none;
  }

  .lb-slide-enter-active,
  .lb-slide-leave-active {
    transition: none;
  }
}
</style>
