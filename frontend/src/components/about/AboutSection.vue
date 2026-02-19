<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useUiStore } from '@/stores'

const uiStore = useUiStore()
const sectionRef = ref<HTMLElement | null>(null)
const hasRevealed = ref(false)
let observer: IntersectionObserver | null = null

// Photos — swap placeholders for real images later
const photos = [
  { src: '', caption: 'South Beach, Miami' },
  { src: '', caption: 'Times Square, NYC' },
  { src: '', caption: 'Wynwood Walls' },
  { src: '', caption: 'Key West Sunset' },
  { src: '', caption: 'Orlando, FL' },
  { src: '', caption: 'Fort Lauderdale Beach' },
]

const currentPhoto = ref(0)
const isTransitioning = ref(false)

const activePhoto = computed(() => photos[currentPhoto.value])

function nextPhoto() {
  if (isTransitioning.value) return
  isTransitioning.value = true
  currentPhoto.value = (currentPhoto.value + 1) % photos.length
  setTimeout(() => {
    isTransitioning.value = false
  }, 400)
}

function prevPhoto() {
  if (isTransitioning.value) return
  isTransitioning.value = true
  currentPhoto.value = (currentPhoto.value - 1 + photos.length) % photos.length
  setTimeout(() => {
    isTransitioning.value = false
  }, 400)
}

onMounted(() => {
  observer = new IntersectionObserver(
    ([entry]) => {
      if (entry?.isIntersecting) {
        uiStore.setActiveSection('about')
        if (!hasRevealed.value) {
          hasRevealed.value = true
        }
      }
    },
    { threshold: 0.15, rootMargin: '0px 0px -80px 0px' }
  )

  if (sectionRef.value) {
    observer.observe(sectionRef.value)
  }
})

onUnmounted(() => {
  observer?.disconnect()
})
</script>

<template>
  <section id="about" ref="sectionRef" class="about-section">
    <div class="container py-16 lg:py-24">
      <!-- Section heading -->
      <div class="mb-10 text-center">
        <span class="section-label">$ whoami</span>
        <h2 class="section-title mt-3">About Me</h2>
      </div>

      <!-- Compact layout: photo + text side by side -->
      <div :class="['about-content', hasRevealed ? 'is-revealed' : '']">
        <!-- Photo viewer -->
        <div class="photo-viewer">
          <div class="photo-frame">
            <!-- Placeholder — swap for <img> when real photos are added -->
            <div class="photo-display">
              <span class="photo-icon">&#128247;</span>
            </div>

            <!-- Location overlay -->
            <div class="photo-location">
              <svg
                class="location-pin"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"
                />
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1 1 15 0Z"
                />
              </svg>
              <span class="location-text">{{ activePhoto?.caption }}</span>
            </div>
          </div>

          <!-- Controls -->
          <div class="photo-controls">
            <button class="photo-btn" aria-label="Previous photo" @click="prevPhoto">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M15.75 19.5 8.25 12l7.5-7.5"
                />
              </svg>
            </button>
            <div class="photo-dots">
              <span
                v-for="(_, i) in photos"
                :key="i"
                :class="['dot', i === currentPhoto ? 'is-active' : '']"
              />
            </div>
            <button class="photo-btn" aria-label="Next photo" @click="nextPhoto">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="m8.25 4.5 7.5 7.5-7.5 7.5"
                />
              </svg>
            </button>
          </div>
        </div>

        <!-- Bio text -->
        <div class="about-text">
          <p class="bio-line">
            I'm <strong>Justin</strong> — born and raised in South Florida. When I'm not at my desk,
            I'm usually out exploring somewhere new, finding the best local food spots, or just
            driving around with good music and no destination.
          </p>
          <p class="bio-line mt-4">
            I like sunsets over the ocean, spontaneous road trips, and getting lost in cities I've
            never been to. This section will fill up as I collect more moments worth sharing.
          </p>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
/* ===================================================================
   Section
   =================================================================== */
.about-section {
  position: relative;
  background: linear-gradient(180deg, var(--skin-hero-2) 0%, var(--skin-hero-1) 100%);
  color: #1c1917;
  transition:
    background 0.4s ease,
    color 0.4s ease;
}

:is(.dark *).about-section {
  background: linear-gradient(180deg, var(--skin-hero-dark-3) 0%, var(--skin-hero-dark-2) 100%);
  color: #e7e5e4;
}

.section-label {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.85rem;
  color: var(--skin-600);
  letter-spacing: 0.02em;
}

:is(.dark *).section-label {
  color: var(--skin-400);
}

.section-title {
  font-size: clamp(2rem, 5vw, 3rem);
  font-weight: 700;
  letter-spacing: -0.025em;
  color: #1c1917;
}

:is(.dark *).section-title {
  color: #fafaf9;
}

/* ===================================================================
   Content layout
   =================================================================== */
.about-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2.5rem;
  max-width: 720px;
  margin: 0 auto;
  opacity: 0;
  transform: translateY(24px);
  transition:
    opacity 0.8s cubic-bezier(0.16, 1, 0.3, 1),
    transform 0.8s cubic-bezier(0.16, 1, 0.3, 1);
  transition-delay: 0.15s;
}

.about-content.is-revealed {
  opacity: 1;
  transform: translateY(0);
}

@media (min-width: 768px) {
  .about-content {
    flex-direction: row;
    align-items: start;
    gap: 3rem;
  }
}

/* ===================================================================
   Photo viewer
   =================================================================== */
.photo-viewer {
  flex-shrink: 0;
  width: 220px;
}

@media (min-width: 768px) {
  .photo-viewer {
    width: 240px;
  }
}

.photo-frame {
  position: relative;
  border-radius: 14px;
  overflow: hidden;
  background: #ffffff;
  border: 1px solid #e7e5e4;
  box-shadow:
    0 2px 8px rgba(0, 0, 0, 0.04),
    0 8px 24px rgba(0, 0, 0, 0.03);
  transition:
    background 0.3s ease,
    border-color 0.3s ease,
    box-shadow 0.3s ease;
}

:is(.dark *).photo-frame {
  background: rgba(var(--skin-light-rgb), 0.03);
  border-color: rgba(var(--skin-light-rgb), 0.08);
  box-shadow:
    0 2px 8px rgba(0, 0, 0, 0.15),
    0 8px 24px rgba(0, 0, 0, 0.1);
}

/* Placeholder display — remove this block once real images are added */
.photo-display {
  aspect-ratio: 3 / 4;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(
    160deg,
    rgba(var(--skin-rgb), 0.05) 0%,
    rgba(var(--skin-rgb), 0.02) 100%
  );
  transition: background 0.4s ease;
}

:is(.dark *).photo-display {
  background: linear-gradient(
    160deg,
    rgba(var(--skin-light-rgb), 0.05) 0%,
    rgba(var(--skin-light-rgb), 0.02) 100%
  );
}

.photo-icon {
  font-size: 2rem;
  opacity: 0.25;
}

/* Location badge */
.photo-location {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  display: flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.6rem 0.8rem;
  background: linear-gradient(to top, rgba(0, 0, 0, 0.5), transparent);
}

.location-pin {
  width: 14px;
  height: 14px;
  color: white;
  opacity: 0.85;
  flex-shrink: 0;
}

.location-text {
  font-size: 0.75rem;
  font-weight: 500;
  color: white;
  opacity: 0.9;
  letter-spacing: 0.01em;
}

/* ===================================================================
   Photo controls — prev/next + dots
   =================================================================== */
.photo-controls {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  margin-top: 0.75rem;
}

.photo-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: 1px solid #e7e5e4;
  background: #ffffff;
  color: #78716c;
  cursor: pointer;
  transition:
    color 0.2s ease,
    border-color 0.2s ease,
    background 0.2s ease;
}

.photo-btn:hover {
  color: var(--skin-600);
  border-color: rgba(var(--skin-rgb), 0.2);
  background: rgba(var(--skin-rgb), 0.04);
}

:is(.dark *).photo-btn {
  background: rgba(var(--skin-light-rgb), 0.03);
  border-color: rgba(var(--skin-light-rgb), 0.08);
  color: #78716c;
}

:is(.dark *).photo-btn:hover {
  color: var(--skin-400);
  border-color: rgba(var(--skin-light-rgb), 0.15);
  background: rgba(var(--skin-light-rgb), 0.06);
}

.photo-btn svg {
  width: 16px;
  height: 16px;
}

/* Dots */
.photo-dots {
  display: flex;
  align-items: center;
  gap: 6px;
}

.dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #d6d3d1;
  transition:
    background 0.3s ease,
    transform 0.3s ease;
}

.dot.is-active {
  background: var(--skin-500);
  transform: scale(1.3);
}

:is(.dark *).dot {
  background: rgba(var(--skin-light-rgb), 0.15);
}

:is(.dark *).dot.is-active {
  background: var(--skin-400);
}

/* ===================================================================
   Bio text
   =================================================================== */
.about-text {
  flex: 1;
  min-width: 0;
}

.bio-line {
  font-size: 1.05rem;
  line-height: 1.8;
  color: #44403c;
  transition: color 0.3s ease;
}

:is(.dark *).bio-line {
  color: #a8a29e;
}

.bio-line strong {
  color: var(--skin-700);
  font-weight: 600;
  transition: color 0.3s ease;
}

:is(.dark *).bio-line strong {
  color: var(--skin-400);
}
</style>
