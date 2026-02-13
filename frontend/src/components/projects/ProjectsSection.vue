<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useProjectsStore, useUiStore } from '@/stores'

const projectsStore = useProjectsStore()
const uiStore = useUiStore()
const sectionRef = ref<HTMLElement | null>(null)
const hasRevealed = ref(false)
let observer: IntersectionObserver | null = null

const projects = computed(() => {
  if (projectsStore.featuredProjects.length > 0) {
    return projectsStore.featuredProjects
  }
  return projectsStore.sortedProjects
})

onMounted(() => {
  projectsStore.fetchFeaturedProjects()

  observer = new IntersectionObserver(
    ([entry]) => {
      if (entry?.isIntersecting) {
        uiStore.setActiveSection('projects')
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
  <section id="projects" ref="sectionRef" class="projects-section">
    <div class="container py-20 lg:py-28">
      <!-- Section heading -->
      <div class="mb-14 text-center">
        <span class="section-label">$ ls projects/</span>
        <h2 class="section-title mt-3">Projects</h2>
        <p class="section-subtitle mt-4 mx-auto max-w-xl">
          A selection of things I've built — from full-stack apps to developer tools, each one an
          exercise in clean code and thoughtful design.
        </p>
      </div>

      <!-- Loading skeleton -->
      <div v-if="projectsStore.loading" class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
        <div v-for="i in 3" :key="i" class="skeleton-card">
          <div class="skeleton-image" />
          <div class="skeleton-body">
            <div class="skeleton-line w-3/4" />
            <div class="skeleton-line w-full mt-3" />
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
      <div v-else-if="projectsStore.error" class="text-center py-12">
        <p class="text-red-500 dark:text-red-400 mb-4">Failed to load projects.</p>
        <button class="retry-btn" @click="projectsStore.fetchFeaturedProjects(true)">
          Try Again
        </button>
      </div>

      <!-- Empty state -->
      <div v-else-if="projects.length === 0" class="text-center py-12">
        <p class="text-gray-500 dark:text-gray-400">No projects yet — check back soon.</p>
      </div>

      <!-- Project cards grid -->
      <div v-else class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
        <article
          v-for="(project, i) in projects"
          :key="project.id"
          :class="['project-card', hasRevealed ? 'is-revealed' : '']"
          :style="{ animationDelay: `${0.2 + i * 0.12}s` }"
        >
          <!-- Image / Placeholder -->
          <div class="card-image">
            <img
              v-if="project.image_url"
              :src="project.image_url"
              :alt="project.title"
              class="h-full w-full object-cover"
              loading="lazy"
            />
            <div v-else class="card-placeholder">
              <svg
                class="h-10 w-10"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                stroke-width="1.5"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M17.25 6.75 22.5 12l-5.25 5.25m-10.5 0L1.5 12l5.25-5.25m7.5-3-4.5 16.5"
                />
              </svg>
            </div>
          </div>

          <!-- Body -->
          <div class="card-body">
            <h3 class="card-title">{{ project.title }}</h3>
            <p class="card-desc">{{ project.description }}</p>

            <!-- Tech stack -->
            <div v-if="project.tech_stack.length" class="mt-4 flex flex-wrap gap-2">
              <span v-for="tech in project.tech_stack" :key="tech" class="tech-badge">
                {{ tech }}
              </span>
            </div>

            <!-- Links -->
            <div class="card-links">
              <a
                v-if="project.github_url"
                :href="project.github_url"
                target="_blank"
                rel="noopener noreferrer"
                class="project-link"
                aria-label="View source on GitHub"
              >
                <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24">
                  <path
                    d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"
                  />
                </svg>
                <span>Source</span>
              </a>
              <a
                v-if="project.live_url"
                :href="project.live_url"
                target="_blank"
                rel="noopener noreferrer"
                class="project-link"
                aria-label="View live project"
              >
                <svg
                  class="h-5 w-5"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  stroke-width="2"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M13.5 6H5.25A2.25 2.25 0 0 0 3 8.25v10.5A2.25 2.25 0 0 0 5.25 21h10.5A2.25 2.25 0 0 0 18 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25"
                  />
                </svg>
                <span>Live</span>
              </a>
            </div>
          </div>
        </article>
      </div>
    </div>
  </section>
</template>

<style scoped>
/* ===================================================================
   Section base
   =================================================================== */
.projects-section {
  background: #ffffff;
  color: #1c1917;
  transition:
    background 0.4s ease,
    color 0.4s ease;
}

:is(.dark *).projects-section {
  background: #0f0f0f;
  color: #e7e5e4;
}

/* ===================================================================
   Section heading
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
   Project card
   =================================================================== */
.project-card {
  opacity: 0;
  background: #ffffff;
  border-radius: 16px;
  border-top: 3px solid var(--skin-500);
  overflow: hidden;
  box-shadow:
    0 1px 3px rgba(0, 0, 0, 0.08),
    0 4px 12px rgba(0, 0, 0, 0.04);
  transition:
    transform 0.25s ease,
    box-shadow 0.25s ease,
    background 0.3s ease,
    border-color 0.3s ease;
  will-change: opacity, transform;
}

.project-card.is-revealed {
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

.project-card:hover {
  transform: translateY(-4px);
  box-shadow:
    0 4px 12px rgba(0, 0, 0, 0.1),
    0 12px 28px rgba(0, 0, 0, 0.08);
}

:is(.dark *).project-card {
  background: #1a1918;
  border-top-color: var(--skin-400);
  box-shadow:
    0 1px 3px rgba(0, 0, 0, 0.3),
    0 4px 12px rgba(0, 0, 0, 0.2);
}

:is(.dark *).project-card:hover {
  box-shadow:
    0 4px 12px rgba(0, 0, 0, 0.4),
    0 12px 28px rgba(0, 0, 0, 0.3);
}

/* ===================================================================
   Card image area
   =================================================================== */
.card-image {
  height: 180px;
  overflow: hidden;
  background: #f5f5f4;
}

:is(.dark *).card-image {
  background: #141312;
}

.card-placeholder {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(
    135deg,
    rgba(var(--skin-rgb), 0.06) 0%,
    rgba(var(--skin-rgb), 0.02) 100%
  );
  color: var(--skin-500);
}

:is(.dark *).card-placeholder {
  background: linear-gradient(
    135deg,
    rgba(var(--skin-light-rgb), 0.08) 0%,
    rgba(var(--skin-light-rgb), 0.02) 100%
  );
  color: var(--skin-400);
}

/* ===================================================================
   Card body
   =================================================================== */
.card-body {
  padding: 1.25rem;
  display: flex;
  flex-direction: column;
}

.card-title {
  font-size: 1.1rem;
  font-weight: 700;
  color: #1c1917;
  transition: color 0.2s ease;
}

.project-card:hover .card-title {
  color: var(--skin-600);
}

:is(.dark *).card-title {
  color: #fafaf9;
}

:is(.dark *).project-card:hover .card-title {
  color: var(--skin-400);
}

.card-desc {
  margin-top: 0.5rem;
  font-size: 0.9rem;
  line-height: 1.6;
  color: #78716c;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

:is(.dark *).card-desc {
  color: #a8a29e;
}

/* ===================================================================
   Tech badges
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
   Card links
   =================================================================== */
.card-links {
  margin-top: auto;
  padding-top: 1rem;
  display: flex;
  gap: 0.75rem;
  border-top: 1px solid #f5f5f4;
}

:is(.dark *).card-links {
  border-top-color: #292524;
}

.project-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 0.8rem;
  font-weight: 600;
  color: #78716c;
  transition: color 0.2s ease;
}

.project-link:hover {
  color: var(--skin-600);
}

:is(.dark *).project-link {
  color: #a8a29e;
}

:is(.dark *).project-link:hover {
  color: var(--skin-400);
}

/* ===================================================================
   Loading skeletons
   =================================================================== */
.skeleton-card {
  border-radius: 16px;
  overflow: hidden;
  background: #ffffff;
  border-top: 3px solid #e7e5e4;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.06);
}

:is(.dark *).skeleton-card {
  background: #1a1918;
  border-top-color: #292524;
}

.skeleton-image {
  height: 180px;
  background: #f5f5f4;
  animation: pulse 1.5s ease-in-out infinite;
}

:is(.dark *).skeleton-image {
  background: #141312;
}

.skeleton-body {
  padding: 1.25rem;
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
