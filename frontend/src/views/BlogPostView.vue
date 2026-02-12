<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useWindowScroll } from '@vueuse/core'
import { useBlogStore } from '@/stores'

const route = useRoute()
const router = useRouter()
const blogStore = useBlogStore()
const articleRef = ref<HTMLElement | null>(null)
const entered = ref(false)

const { y: scrollY } = useWindowScroll()

const slug = computed(() => route.params.slug as string)

const post = computed(() => blogStore.currentPost)

const formattedDate = computed(() => {
  if (!post.value) return ''
  const raw = post.value.published_at || post.value.created_at
  return new Date(raw).toLocaleDateString('en-US', {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  })
})

const contentParagraphs = computed(() => {
  if (!post.value?.content) return []
  return post.value.content.split(/\n\n+/).filter((p) => p.trim())
})

/* ========================================================================
   Reading progress bar
   ======================================================================== */
const readingProgress = computed(() => {
  if (typeof document === 'undefined') return 0
  const docHeight = document.documentElement.scrollHeight - window.innerHeight
  if (docHeight <= 0) return 0
  return Math.min(100, Math.max(0, (scrollY.value / docHeight) * 100))
})

/* ========================================================================
   Lifecycle
   ======================================================================== */
function updateDocumentTitle() {
  if (post.value) {
    const baseTitle = import.meta.env.VITE_APP_TITLE || 'Portfolio'
    document.title = `${post.value.title} | ${baseTitle}`
  }
}

onMounted(async () => {
  await blogStore.fetchPost(slug.value)
  updateDocumentTitle()
  requestAnimationFrame(() => {
    entered.value = true
  })
})

// Handle route changes (navigating between posts)
watch(slug, async (newSlug) => {
  if (newSlug) {
    entered.value = false
    window.scrollTo({ top: 0 })
    await blogStore.fetchPost(newSlug)
    updateDocumentTitle()
    requestAnimationFrame(() => {
      entered.value = true
    })
  }
})

onUnmounted(() => {
  blogStore.clearCurrentPost()
})

function goBack() {
  router.push({ name: 'blog' })
}

function handleTagClick(tag: string) {
  router.push({ name: 'blog', query: { tag } })
}
</script>

<template>
  <div class="post-page">
    <!-- Reading progress bar -->
    <div class="progress-bar" :style="{ width: `${readingProgress}%` }" />

    <!-- Loading -->
    <div v-if="blogStore.loading" class="post-loading">
      <div class="container">
        <div class="post-content-area">
          <div class="skeleton-line w-1/4 mb-6" />
          <div class="skeleton-line-lg w-3/4" />
          <div class="skeleton-line-lg w-1/2 mt-2" />
          <div class="skeleton-line w-1/3 mt-6" />
          <div class="skeleton-line w-full mt-10" />
          <div class="skeleton-line w-full mt-3" />
          <div class="skeleton-line w-5/6 mt-3" />
          <div class="skeleton-line w-full mt-3" />
          <div class="skeleton-line w-3/4 mt-3" />
        </div>
      </div>
    </div>

    <!-- Error / Not Found -->
    <div v-else-if="blogStore.error" class="post-error">
      <div class="container">
        <div class="post-content-area text-center py-20">
          <div class="error-icon">?</div>
          <h2 class="error-title mt-4">Post not found</h2>
          <p class="error-text mt-2">
            This post may have been removed or the URL might be incorrect.
          </p>
          <button class="back-btn mt-6" @click="goBack">
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
              <polyline points="9,2 4,7 9,12" />
            </svg>
            Back to Blog
          </button>
        </div>
      </div>
    </div>

    <!-- Post content -->
    <template v-else-if="post">
      <article ref="articleRef" class="post-article">
        <div class="container">
          <div class="post-content-area">
            <!-- Back link -->
            <div :class="['reveal reveal-1', entered ? 'is-revealed' : '']">
              <button class="back-link" @click="goBack">
                <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
                  <polyline points="9,2 4,7 9,12" />
                </svg>
                Blog
              </button>
            </div>

            <!-- Title -->
            <h1 :class="['post-title mt-6', 'reveal reveal-2', entered ? 'is-revealed' : '']">
              {{ post.title }}
            </h1>

            <!-- Meta bar -->
            <div :class="['post-meta mt-5', 'reveal reveal-3', entered ? 'is-revealed' : '']">
              <time class="meta-date">{{ formattedDate }}</time>
              <span class="meta-sep" aria-hidden="true">&middot;</span>
              <span class="meta-reading">{{ post.reading_time }} min read</span>
              <template v-if="post.view_count > 0">
                <span class="meta-sep" aria-hidden="true">&middot;</span>
                <span class="meta-views">{{ post.view_count }} views</span>
              </template>
            </div>

            <!-- Divider -->
            <div :class="['post-divider mt-8', 'reveal reveal-4', entered ? 'is-revealed' : '']" />

            <!-- Content -->
            <div :class="['post-body mt-8', 'reveal reveal-5', entered ? 'is-revealed' : '']">
              <p v-for="(paragraph, i) in contentParagraphs" :key="i" class="body-paragraph">
                {{ paragraph }}
              </p>
            </div>

            <!-- Tags -->
            <div
              v-if="post.tags.length"
              :class="['post-tags mt-10', 'reveal reveal-6', entered ? 'is-revealed' : '']"
            >
              <span class="tags-label">Tagged</span>
              <div class="tags-list">
                <button
                  v-for="tag in post.tags"
                  :key="tag"
                  class="post-tag"
                  @click="handleTagClick(tag)"
                >
                  {{ tag }}
                </button>
              </div>
            </div>

            <!-- Bottom divider -->
            <div class="post-divider mt-10" />

            <!-- Back to blog -->
            <div class="post-footer mt-8">
              <button class="back-btn" @click="goBack">
                <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
                  <polyline points="9,2 4,7 9,12" />
                </svg>
                All posts
              </button>
            </div>
          </div>
        </div>
      </article>
    </template>
  </div>
</template>

<style scoped>
/* ===================================================================
   Page base
   =================================================================== */
.post-page {
  min-height: 100vh;
  background: #ffffff;
  color: #1c1917;
  transition:
    background 0.4s ease,
    color 0.4s ease;
}

:is(.dark *).post-page {
  background: #0f0f0f;
  color: #e7e5e4;
}

/* ===================================================================
   Reading progress bar
   =================================================================== */
.progress-bar {
  position: fixed;
  top: 0;
  left: 0;
  height: 3px;
  background: linear-gradient(90deg, var(--skin-500), var(--skin-400));
  z-index: 1080;
  transition: width 0.1s linear;
  border-radius: 0 2px 2px 0;
}

:is(.dark *).progress-bar {
  background: linear-gradient(90deg, var(--skin-400), var(--skin-300, var(--skin-400)));
}

/* ===================================================================
   Content area — narrow for reading
   =================================================================== */
.post-content-area {
  max-width: 680px;
  margin: 0 auto;
}

/* ===================================================================
   Article
   =================================================================== */
.post-article {
  padding-top: 7rem;
  padding-bottom: 5rem;
}

/* ===================================================================
   Back link
   =================================================================== */
.back-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
  font-weight: 500;
  color: var(--skin-600);
  cursor: pointer;
  transition: all 0.2s ease;
  background: none;
  border: none;
  padding: 0;
}

.back-link:hover {
  color: var(--skin-700);
  transform: translateX(-3px);
}

:is(.dark *).back-link {
  color: var(--skin-400);
}

:is(.dark *).back-link:hover {
  color: var(--skin-300, var(--skin-400));
}

/* ===================================================================
   Title
   =================================================================== */
.post-title {
  font-size: clamp(1.8rem, 4.5vw, 2.5rem);
  font-weight: 800;
  line-height: 1.2;
  letter-spacing: -0.025em;
  color: #1c1917;
}

:is(.dark *).post-title {
  color: #fafaf9;
}

/* ===================================================================
   Meta bar
   =================================================================== */
.post-meta {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 0.5rem;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
}

.meta-date {
  color: var(--skin-600);
  font-weight: 500;
}

:is(.dark *).meta-date {
  color: var(--skin-400);
}

.meta-sep {
  color: #d6d3d1;
}

:is(.dark *).meta-sep {
  color: #44403c;
}

.meta-reading,
.meta-views {
  color: #a8a29e;
}

:is(.dark *).meta-reading,
:is(.dark *).meta-views {
  color: #78716c;
}

/* ===================================================================
   Divider
   =================================================================== */
.post-divider {
  height: 1px;
  background: linear-gradient(
    90deg,
    var(--skin-500) 0%,
    rgba(var(--skin-rgb), 0.15) 30%,
    transparent 100%
  );
}

:is(.dark *).post-divider {
  background: linear-gradient(
    90deg,
    var(--skin-400) 0%,
    rgba(var(--skin-light-rgb), 0.12) 30%,
    transparent 100%
  );
}

/* ===================================================================
   Body content
   =================================================================== */
.post-body {
  font-size: 1.05rem;
  line-height: 1.85;
  color: #44403c;
}

:is(.dark *).post-body {
  color: #d6d3d1;
}

.body-paragraph {
  margin-bottom: 1.5em;
}

.body-paragraph:last-child {
  margin-bottom: 0;
}

/* ===================================================================
   Tags section
   =================================================================== */
.post-tags {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-wrap: wrap;
}

.tags-label {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem;
  color: #a8a29e;
  font-weight: 500;
}

:is(.dark *).tags-label {
  color: #78716c;
}

.tags-list {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
}

.post-tag {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.72rem;
  font-weight: 500;
  padding: 3px 12px;
  border-radius: 999px;
  background: rgba(var(--skin-rgb), 0.08);
  color: var(--skin-700);
  cursor: pointer;
  border: none;
  transition: all 0.2s ease;
}

.post-tag:hover {
  background: rgba(var(--skin-rgb), 0.15);
  transform: translateY(-1px);
}

:is(.dark *).post-tag {
  background: rgba(var(--skin-light-rgb), 0.1);
  color: var(--skin-400);
}

:is(.dark *).post-tag:hover {
  background: rgba(var(--skin-light-rgb), 0.18);
}

/* ===================================================================
   Footer
   =================================================================== */
.post-footer {
  padding-bottom: 2rem;
}

.back-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.82rem;
  font-weight: 600;
  padding: 10px 20px;
  border-radius: 12px;
  color: var(--skin-600);
  background: rgba(var(--skin-rgb), 0.06);
  cursor: pointer;
  border: none;
  transition: all 0.2s ease;
}

.back-btn:hover {
  background: rgba(var(--skin-rgb), 0.12);
  transform: translateY(-1px);
}

:is(.dark *).back-btn {
  color: var(--skin-400);
  background: rgba(var(--skin-light-rgb), 0.08);
}

:is(.dark *).back-btn:hover {
  background: rgba(var(--skin-light-rgb), 0.14);
}

/* ===================================================================
   Reveal animation (matches hero pattern)
   =================================================================== */
.reveal {
  opacity: 0;
  will-change: opacity, filter, transform;
}

.reveal.is-revealed {
  animation: sweepReveal 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes sweepReveal {
  0% {
    opacity: 0;
    filter: blur(6px);
    transform: translateY(10px);
  }
  100% {
    opacity: 1;
    filter: blur(0px);
    transform: translateY(0);
  }
}

.reveal-1.is-revealed { animation-delay: 0.1s; }
.reveal-2.is-revealed { animation-delay: 0.25s; animation-duration: 1s; }
.reveal-3.is-revealed { animation-delay: 0.45s; }
.reveal-4.is-revealed { animation-delay: 0.6s; }
.reveal-5.is-revealed { animation-delay: 0.7s; animation-duration: 1s; }
.reveal-6.is-revealed { animation-delay: 0.85s; }

/* ===================================================================
   Loading skeleton
   =================================================================== */
.post-loading {
  padding-top: 7rem;
  padding-bottom: 5rem;
}

.skeleton-line {
  height: 12px;
  border-radius: 6px;
  background: #e7e5e4;
  animation: pulse 1.5s ease-in-out infinite;
}

.skeleton-line-lg {
  height: 24px;
  border-radius: 8px;
  background: #e7e5e4;
  animation: pulse 1.5s ease-in-out infinite;
}

:is(.dark *).skeleton-line,
:is(.dark *).skeleton-line-lg {
  background: #292524;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

/* ===================================================================
   Error state
   =================================================================== */
.error-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 56px;
  height: 56px;
  border-radius: 50%;
  background: rgba(var(--skin-rgb), 0.08);
  color: var(--skin-600);
  font-family: 'JetBrains Mono', monospace;
  font-weight: 800;
  font-size: 1.8rem;
}

:is(.dark *).error-icon {
  background: rgba(var(--skin-light-rgb), 0.1);
  color: var(--skin-400);
}

.error-title {
  font-size: 1.3rem;
  font-weight: 700;
  color: #1c1917;
}

:is(.dark *).error-title {
  color: #fafaf9;
}

.error-text {
  font-size: 0.95rem;
  color: #78716c;
}

:is(.dark *).error-text {
  color: #a8a29e;
}
</style>
