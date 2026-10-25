<script setup lang="ts">
import { ref, computed, watch } from 'vue'

const props = defineProps<{
  urls: string[]
  title: string
}>()

const emit = defineEmits<{
  open: [index: number]
}>()

const index = ref(0)
const count = computed(() => props.urls.length)
const current = computed(() => props.urls[index.value] ?? '')
const hasMany = computed(() => count.value > 1)

// Keep the index in range if the list shrinks (admin edit, hot reload).
watch(count, (n) => {
  if (index.value >= n) index.value = 0
})

function wrap(i: number): number {
  return (i + count.value) % count.value
}

function go(delta: number) {
  if (!hasMany.value) return
  index.value = wrap(index.value + delta)
  preload(index.value + delta)
}

function goTo(i: number) {
  index.value = i
}

// Warm the slide after the one we just moved to, so repeated clicks feel instant.
function preload(i: number) {
  const url = props.urls[wrap(i)]
  if (!url) return
  const img = new Image()
  img.src = url
}

function altFor(i: number): string {
  return hasMany.value ? `${props.title}, image ${i + 1} of ${count.value}` : props.title
}

function onKeydown(e: KeyboardEvent) {
  if (e.key === 'ArrowLeft') {
    e.preventDefault()
    go(-1)
  } else if (e.key === 'ArrowRight') {
    e.preventDefault()
    go(1)
  }
}

// Horizontal swipe on touch devices; vertical scrolling stays native (touch-action: pan-y).
const SWIPE_THRESHOLD = 40
let swipeStartX: number | null = null

function onPointerDown(e: PointerEvent) {
  swipeStartX = e.pointerType === 'touch' ? e.clientX : null
}

function onPointerUp(e: PointerEvent) {
  if (swipeStartX === null) return
  const dx = e.clientX - swipeStartX
  swipeStartX = null
  if (Math.abs(dx) >= SWIPE_THRESHOLD) go(dx < 0 ? 1 : -1)
}

function onPointerCancel() {
  swipeStartX = null
}
</script>

<template>
  <div
    class="media-carousel"
    tabindex="0"
    role="group"
    :aria-label="`${title} images`"
    @keydown="onKeydown"
    @pointerdown="onPointerDown"
    @pointerup="onPointerUp"
    @pointercancel="onPointerCancel"
  >
    <button type="button" class="slide-btn" @click="emit('open', index)">
      <Transition name="slide-fade" mode="out-in">
        <img
          :key="current"
          :src="current"
          :alt="altFor(index)"
          class="slide-img"
          loading="lazy"
          decoding="async"
          draggable="false"
        />
      </Transition>
      <span class="sr-only">, opens full size</span>
    </button>

    <template v-if="hasMany">
      <button
        type="button"
        class="nav-btn nav-prev"
        aria-label="Previous image"
        @click.stop="go(-1)"
      >
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
        </svg>
      </button>
      <button type="button" class="nav-btn nav-next" aria-label="Next image" @click.stop="go(1)">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
        </svg>
      </button>

      <div class="dots">
        <button
          v-for="(_, i) in urls"
          :key="i"
          type="button"
          :class="['dot', i === index ? 'is-active' : '']"
          :aria-label="`Go to image ${i + 1}`"
          :aria-current="i === index ? 'true' : undefined"
          @click.stop="goTo(i)"
        />
      </div>

      <span class="counter" aria-hidden="true">{{ index + 1 }}/{{ count }}</span>
      <span class="sr-only" aria-live="polite">Image {{ index + 1 }} of {{ count }}</span>
    </template>
  </div>
</template>

<style scoped>
.media-carousel {
  position: relative;
  height: 100%;
  outline: none;
  touch-action: pan-y;
}

.media-carousel:focus-visible {
  box-shadow: inset 0 0 0 3px var(--skin-500);
}

.slide-btn {
  display: block;
  width: 100%;
  height: 100%;
  padding: 0;
  border: 0;
  background: transparent;
  cursor: zoom-in;
}

.slide-img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
  user-select: none;
  -webkit-user-drag: none;
}

.slide-fade-enter-active,
.slide-fade-leave-active {
  transition: opacity 0.22s ease;
}

.slide-fade-enter-from,
.slide-fade-leave-to {
  opacity: 0;
}

/* Prev / next */
.nav-btn {
  position: absolute;
  top: 50%;
  width: 30px;
  height: 30px;
  transform: translateY(-50%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  border: 0;
  border-radius: 999px;
  color: #fafaf9;
  background: rgba(28, 25, 23, 0.55);
  backdrop-filter: blur(4px);
  cursor: pointer;
  opacity: 0;
  transition:
    opacity 0.2s ease,
    background 0.2s ease;
}

.nav-btn svg {
  width: 16px;
  height: 16px;
}

.nav-prev {
  left: 8px;
}

.nav-next {
  right: 8px;
}

.nav-btn:hover {
  background: rgba(28, 25, 23, 0.8);
}

.media-carousel:hover .nav-btn,
.media-carousel:focus-within .nav-btn,
.nav-btn:focus-visible {
  opacity: 1;
}

/* No hover on touch screens, so keep the controls visible there. */
@media (hover: none) {
  .nav-btn {
    opacity: 1;
  }
}

/* Dots */
.dots {
  position: absolute;
  left: 0;
  right: 0;
  bottom: 8px;
  display: flex;
  justify-content: center;
  gap: 5px;
  pointer-events: none;
}

.dot {
  width: 6px;
  height: 6px;
  padding: 0;
  border: 0;
  border-radius: 999px;
  background: rgba(250, 250, 249, 0.55);
  box-shadow: 0 0 0 1px rgba(28, 25, 23, 0.25);
  cursor: pointer;
  pointer-events: auto;
  transition:
    background 0.2s ease,
    transform 0.2s ease;
}

.dot.is-active {
  background: #fafaf9;
  transform: scale(1.35);
}

/* Counter */
.counter {
  position: absolute;
  top: 8px;
  right: 8px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.65rem;
  font-weight: 600;
  line-height: 1;
  padding: 3px 7px;
  border-radius: 999px;
  color: #fafaf9;
  background: rgba(28, 25, 23, 0.55);
  backdrop-filter: blur(4px);
}

@media (prefers-reduced-motion: reduce) {
  .slide-fade-enter-active,
  .slide-fade-leave-active,
  .nav-btn,
  .dot {
    transition: none;
  }
}
</style>
