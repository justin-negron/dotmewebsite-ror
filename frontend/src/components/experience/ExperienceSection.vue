<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useExperiencesStore, useUiStore } from '@/stores'

const experiencesStore = useExperiencesStore()
const uiStore = useUiStore()
const sectionRef = ref<HTMLElement | null>(null)
const hasRevealed = ref(false)
let observer: IntersectionObserver | null = null

const experiences = computed(() => experiencesStore.chronologicalExperiences)

onMounted(() => {
  experiencesStore.fetchExperiences()

  observer = new IntersectionObserver(
    ([entry]) => {
      if (entry?.isIntersecting) {
        uiStore.setActiveSection('experience')
        if (!hasRevealed.value) {
          hasRevealed.value = true
        }
      }
    },
    { threshold: 0.15 }
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
  <section id="experience" ref="sectionRef" class="experience-section">
    <div class="container py-20 lg:py-28">
      <!-- Section heading -->
      <div class="mb-14 text-center">
        <span class="section-label">$ cat experience.log</span>
        <h2 class="section-title mt-3">Experience</h2>
        <p class="section-subtitle mt-4 mx-auto max-w-xl">
          Where I've been, what I've built, and the technologies I've worked with along the way.
        </p>
      </div>

      <!-- Loading skeleton -->
      <div v-if="experiencesStore.loading" class="timeline">
        <div class="timeline-line" />
        <div v-for="i in 3" :key="i" class="timeline-entry entry-left is-revealed">
          <div class="timeline-dot" />
          <div class="entry-card skeleton-entry">
            <div class="skeleton-line w-1/3" />
            <div class="skeleton-line w-2/3 mt-3" />
            <div class="skeleton-line w-1/2 mt-2" />
            <div class="skeleton-line w-full mt-4" />
            <div class="skeleton-line w-5/6 mt-2" />
            <div class="mt-4 flex gap-2">
              <div class="skeleton-badge" />
              <div class="skeleton-badge" />
              <div class="skeleton-badge" />
            </div>
          </div>
        </div>
      </div>

      <!-- Error state -->
      <div v-else-if="experiencesStore.error" class="text-center py-12">
        <p class="text-red-500 dark:text-red-400 mb-4">Failed to load experience.</p>
        <button class="retry-btn" @click="experiencesStore.fetchExperiences(true)">
          Try Again
        </button>
      </div>

      <!-- Empty state -->
      <div v-else-if="experiences.length === 0" class="text-center py-12">
        <p class="text-gray-500 dark:text-gray-400">No experience yet — check back soon.</p>
      </div>

      <!-- Timeline -->
      <div v-else class="timeline">
        <div class="timeline-line" />

        <div
          v-for="(exp, i) in experiences"
          :key="exp.id"
          :class="[
            'timeline-entry',
            i % 2 === 0 ? 'entry-left' : 'entry-right',
            hasRevealed ? 'is-revealed' : '',
          ]"
          :style="{ animationDelay: `${i * 0.15}s` }"
        >
          <!-- Dot on the timeline -->
          <div class="timeline-dot" :class="{ 'is-current': exp.current }" />

          <!-- Card -->
          <div class="entry-card">
            <div class="entry-header">
              <span class="entry-duration">{{ exp.duration }}</span>
              <span v-if="exp.current" class="current-badge">Current</span>
            </div>

            <h3 class="entry-company">{{ exp.company }}</h3>
            <p class="entry-position">{{ exp.position }}</p>
            <p class="entry-desc">{{ exp.description }}</p>

            <!-- Tech stack -->
            <div v-if="exp.technologies.length" class="mt-4 flex flex-wrap gap-2">
              <span v-for="tech in exp.technologies" :key="tech" class="tech-badge">
                {{ tech }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
/* ===================================================================
   Section base — alternating bg from Projects
   =================================================================== */
.experience-section {
  background: #fafaf9;
  color: #1c1917;
  transition:
    background 0.4s ease,
    color 0.4s ease;
}

:is(.dark *).experience-section {
  background: #0a0a0a;
  color: #e7e5e4;
}

/* ===================================================================
   Section heading (shared pattern with Projects)
   =================================================================== */
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

.section-subtitle {
  font-size: 1.05rem;
  line-height: 1.7;
  color: #57534e;
}

:is(.dark *).section-subtitle {
  color: #a8a29e;
}

/* ===================================================================
   Timeline container
   =================================================================== */
.timeline {
  position: relative;
  max-width: 800px;
  margin: 0 auto;
}

/* Vertical line */
.timeline-line {
  position: absolute;
  left: 20px;
  top: 0;
  bottom: 0;
  width: 2px;
  background: rgba(var(--skin-rgb), 0.15);
}

:is(.dark *).timeline-line {
  background: rgba(var(--skin-light-rgb), 0.12);
}

@media (min-width: 1024px) {
  .timeline-line {
    left: 50%;
    transform: translateX(-50%);
  }
}

/* ===================================================================
   Timeline entry
   =================================================================== */
.timeline-entry {
  position: relative;
  padding-left: 52px;
  padding-bottom: 2.5rem;
  opacity: 0;
  will-change: opacity, transform;
}

.timeline-entry.is-revealed {
  animation: cardReveal 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes cardReveal {
  0% {
    opacity: 0;
    transform: translateY(24px);
  }
  100% {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Desktop: alternating layout */
@media (min-width: 1024px) {
  .timeline-entry {
    width: 50%;
    padding-left: 0;
    padding-bottom: 3rem;
  }

  .entry-left {
    padding-right: 40px;
    text-align: right;
  }

  .entry-left .entry-card {
    border-left: none;
    border-right: 3px solid var(--skin-500);
  }

  :is(.dark *).entry-left .entry-card {
    border-right-color: var(--skin-400);
  }

  .entry-left .entry-header {
    justify-content: flex-end;
  }

  .entry-left .tech-badge-wrap {
    justify-content: flex-end;
  }

  .entry-right {
    margin-left: 50%;
    padding-left: 40px;
  }
}

/* ===================================================================
   Timeline dot
   =================================================================== */
.timeline-dot {
  position: absolute;
  left: 14px;
  top: 8px;
  width: 14px;
  height: 14px;
  border-radius: 50%;
  background: var(--skin-500);
  border: 3px solid #fafaf9;
  z-index: 2;
  transition: background 0.3s ease;
}

:is(.dark *).timeline-dot {
  background: var(--skin-400);
  border-color: #0a0a0a;
}

.timeline-dot.is-current {
  box-shadow: 0 0 0 4px rgba(var(--skin-rgb), 0.25);
  animation: dotPulse 2s ease-in-out infinite;
}

:is(.dark *).timeline-dot.is-current {
  box-shadow: 0 0 0 4px rgba(var(--skin-light-rgb), 0.2);
}

@keyframes dotPulse {
  0%,
  100% {
    box-shadow: 0 0 0 4px rgba(var(--skin-rgb), 0.25);
  }
  50% {
    box-shadow: 0 0 0 8px rgba(var(--skin-rgb), 0.08);
  }
}

@media (min-width: 1024px) {
  .entry-left .timeline-dot {
    left: auto;
    right: -7px;
  }

  .entry-right .timeline-dot {
    left: -7px;
  }
}

/* ===================================================================
   Entry card
   =================================================================== */
.entry-card {
  background: #ffffff;
  border-left: 3px solid var(--skin-500);
  border-radius: 12px;
  padding: 1.25rem;
  box-shadow:
    0 1px 3px rgba(0, 0, 0, 0.06),
    0 4px 12px rgba(0, 0, 0, 0.03);
  transition:
    background 0.3s ease,
    border-color 0.3s ease,
    box-shadow 0.3s ease,
    transform 0.25s ease;
}

.entry-card:hover {
  transform: translateY(-2px);
  box-shadow:
    0 4px 12px rgba(0, 0, 0, 0.08),
    0 8px 24px rgba(0, 0, 0, 0.05);
}

:is(.dark *).entry-card {
  background: #141312;
  border-left-color: var(--skin-400);
  box-shadow:
    0 1px 3px rgba(0, 0, 0, 0.2),
    0 4px 12px rgba(0, 0, 0, 0.15);
}

:is(.dark *).entry-card:hover {
  box-shadow:
    0 4px 12px rgba(0, 0, 0, 0.3),
    0 8px 24px rgba(0, 0, 0, 0.2);
}

/* ===================================================================
   Entry content
   =================================================================== */
.entry-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
}

.entry-duration {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem;
  color: var(--skin-600);
  font-weight: 500;
}

:is(.dark *).entry-duration {
  color: var(--skin-400);
}

.current-badge {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.65rem;
  font-weight: 600;
  padding: 1px 8px;
  border-radius: 999px;
  background: rgba(34, 197, 94, 0.1);
  color: #16a34a;
}

:is(.dark *).current-badge {
  background: rgba(34, 197, 94, 0.15);
  color: #4ade80;
}

.entry-company {
  font-size: 1.15rem;
  font-weight: 700;
  color: #1c1917;
  letter-spacing: -0.01em;
}

:is(.dark *).entry-company {
  color: #fafaf9;
}

.entry-position {
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--skin-700);
  margin-top: 0.15rem;
}

:is(.dark *).entry-position {
  color: var(--skin-400);
}

.entry-desc {
  margin-top: 0.5rem;
  font-size: 0.9rem;
  line-height: 1.65;
  color: #78716c;
}

:is(.dark *).entry-desc {
  color: #a8a29e;
}

/* ===================================================================
   Tech badges (matches ProjectsSection)
   =================================================================== */
.tech-badge {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.7rem;
  padding: 2px 10px;
  border-radius: 999px;
  background: rgba(var(--skin-rgb), 0.08);
  color: var(--skin-700);
  font-weight: 500;
  white-space: nowrap;
}

:is(.dark *).tech-badge {
  background: rgba(var(--skin-light-rgb), 0.1);
  color: var(--skin-400);
}

/* ===================================================================
   Loading skeletons
   =================================================================== */
.skeleton-entry {
  pointer-events: none;
}

.skeleton-line {
  height: 12px;
  border-radius: 6px;
  background: #e7e5e4;
  animation: pulse 1.5s ease-in-out infinite;
}

:is(.dark *).skeleton-line {
  background: #292524;
}

.skeleton-badge {
  width: 56px;
  height: 20px;
  border-radius: 999px;
  background: #e7e5e4;
  animation: pulse 1.5s ease-in-out infinite;
}

:is(.dark *).skeleton-badge {
  background: #292524;
}

@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

/* ===================================================================
   Retry button
   =================================================================== */
.retry-btn {
  font-size: 0.9rem;
  font-weight: 600;
  padding: 10px 24px;
  border-radius: 12px;
  background: var(--skin-600);
  color: white;
  transition:
    background 0.2s ease,
    transform 0.2s ease;
}

.retry-btn:hover {
  background: var(--skin-700);
  transform: translateY(-1px);
}
</style>
