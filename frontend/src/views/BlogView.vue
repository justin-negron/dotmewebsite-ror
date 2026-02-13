<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useBlogStore } from '@/stores'
import BlogCard from '@/components/blog/BlogCard.vue'
import BlogTags from '@/components/blog/BlogTags.vue'

const route = useRoute()
const blogStore = useBlogStore()
const hasRevealed = ref(false)

const posts = computed(() => blogStore.posts)
const featuredPost = computed(() => posts.value[0] ?? null)
const remainingPosts = computed(() => posts.value.slice(1))

onMounted(async () => {
  const tagFromQuery = route.query.tag as string | undefined
  if (tagFromQuery) {
    await blogStore.fetchPostsByTag(tagFromQuery)
  } else {
    await blogStore.fetchPosts()
  }
  requestAnimationFrame(() => {
    hasRevealed.value = true
  })
})

function handleTagSelect(tag: string | null) {
  hasRevealed.value = false
  if (tag) {
    blogStore.fetchPostsByTag(tag)
  } else {
    blogStore.fetchPosts({}, true)
  }
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      hasRevealed.value = true
    })
  })
}

function handlePageChange(page: number) {
  hasRevealed.value = false
  blogStore.setPage(page)
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      hasRevealed.value = true
    })
  })
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

watch(
  () => blogStore.loading,
  (loading) => {
    if (!loading && !hasRevealed.value) {
      requestAnimationFrame(() => {
        hasRevealed.value = true
      })
    }
  }
)
</script>

<template>
  <div class="blog-page">
    <!-- Header area -->
    <div class="blog-header">
      <div class="container">
        <div class="header-content">
          <span class="section-label">$ tail -f blog.log</span>
          <h1 class="page-title mt-3">Blog</h1>
          <p class="page-subtitle mt-4">
            Thoughts, deep-dives, and war stories from the trenches of software engineering.
          </p>
        </div>
      </div>
    </div>

    <!-- Main content -->
    <div class="blog-body">
      <div class="container">
        <!-- Tag filter -->
        <div v-if="blogStore.allTags.length > 0" class="mb-10">
          <BlogTags
            :tags="blogStore.allTags"
            :active-tag="blogStore.currentTag"
            @select="handleTagSelect"
          />
        </div>

        <!-- Loading state -->
        <div v-if="blogStore.loading" class="posts-grid">
          <div class="skeleton-card skeleton-featured">
            <div class="skeleton-line w-1/3" />
            <div class="skeleton-line w-3/4 mt-4" />
            <div class="skeleton-line w-full mt-3" />
            <div class="skeleton-line w-5/6 mt-2" />
            <div class="mt-5 flex gap-2">
              <div class="skeleton-badge" />
              <div class="skeleton-badge" />
            </div>
          </div>
          <div v-for="i in 2" :key="i" class="skeleton-card">
            <div class="skeleton-line w-1/4" />
            <div class="skeleton-line w-2/3 mt-3" />
            <div class="skeleton-line w-full mt-2" />
            <div class="mt-4 flex gap-2">
              <div class="skeleton-badge" />
              <div class="skeleton-badge" />
            </div>
          </div>
        </div>

        <!-- Error state -->
        <div v-else-if="blogStore.error" class="text-center py-16">
          <div class="error-icon">!</div>
          <p class="error-text mt-4">Failed to load blog posts.</p>
          <button class="retry-btn mt-4" @click="blogStore.fetchPosts({}, true)">Try Again</button>
        </div>

        <!-- Empty state -->
        <div v-else-if="posts.length === 0" class="text-center py-16">
          <p class="empty-text">
            {{
              blogStore.currentTag
                ? `No posts tagged "${blogStore.currentTag}".`
                : 'No posts yet — check back soon.'
            }}
          </p>
          <button
            v-if="blogStore.currentTag"
            class="clear-filter-btn mt-4"
            @click="handleTagSelect(null)"
          >
            Clear filter
          </button>
        </div>

        <!-- Posts -->
        <template v-else>
          <!-- Featured / latest post -->
          <div v-if="featuredPost" :class="['featured-wrap', hasRevealed ? 'is-revealed' : '']">
            <span class="latest-label">Latest</span>
            <BlogCard :post="featuredPost" featured />
          </div>

          <!-- Remaining posts grid -->
          <div v-if="remainingPosts.length" class="posts-grid mt-8">
            <div
              v-for="(post, i) in remainingPosts"
              :key="post.id"
              :class="['post-wrap', hasRevealed ? 'is-revealed' : '']"
              :style="{ animationDelay: `${(i + 1) * 0.1}s` }"
            >
              <BlogCard :post="post" />
            </div>
          </div>

          <!-- Pagination -->
          <div v-if="blogStore.totalPages > 1" class="pagination">
            <button
              class="page-btn"
              :disabled="!blogStore.hasPreviousPage"
              @click="handlePageChange(blogStore.currentPage - 1)"
            >
              <svg
                width="14"
                height="14"
                viewBox="0 0 14 14"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
              >
                <polyline points="9,2 4,7 9,12" />
              </svg>
              Prev
            </button>
            <span class="page-info">
              Page {{ blogStore.currentPage }} of {{ blogStore.totalPages }}
            </span>
            <button
              class="page-btn"
              :disabled="!blogStore.hasNextPage"
              @click="handlePageChange(blogStore.currentPage + 1)"
            >
              Next
              <svg
                width="14"
                height="14"
                viewBox="0 0 14 14"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
              >
                <polyline points="5,2 10,7 5,12" />
              </svg>
            </button>
          </div>

          <!-- Post count -->
          <p class="post-count">
            {{ blogStore.totalCount }} {{ blogStore.totalCount === 1 ? 'entry' : 'entries' }}
            <template v-if="blogStore.currentTag"> tagged "{{ blogStore.currentTag }}"</template>
          </p>
        </template>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* ===================================================================
   Page base
   =================================================================== */
.blog-page {
  min-height: 100vh;
  background: #ffffff;
  color: #1c1917;
  transition:
    background 0.4s ease,
    color 0.4s ease;
}

:is(.dark *).blog-page {
  background: #0f0f0f;
  color: #e7e5e4;
}

/* ===================================================================
   Header area — subtle gradient tint
   =================================================================== */
.blog-header {
  padding-top: 7.5rem;
  padding-bottom: 3rem;
  background: linear-gradient(180deg, rgba(var(--skin-rgb), 0.03) 0%, transparent 100%);
}

:is(.dark *).blog-header {
  background: linear-gradient(180deg, rgba(var(--skin-light-rgb), 0.03) 0%, transparent 100%);
}

.header-content {
  max-width: 640px;
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

.page-title {
  font-size: clamp(2.2rem, 5vw, 3rem);
  font-weight: 700;
  letter-spacing: -0.03em;
  line-height: 1.1;
  color: #1c1917;
}

:is(.dark *).page-title {
  color: #fafaf9;
}

.page-subtitle {
  font-size: 1.05rem;
  line-height: 1.7;
  color: #57534e;
  max-width: 480px;
}

:is(.dark *).page-subtitle {
  color: #a8a29e;
}

/* ===================================================================
   Body area
   =================================================================== */
.blog-body {
  padding-bottom: 5rem;
}

/* ===================================================================
   Featured post wrapper
   =================================================================== */
.featured-wrap {
  opacity: 0;
  will-change: opacity, transform;
}

.featured-wrap.is-revealed {
  animation: cardReveal 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

.latest-label {
  display: inline-block;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.7rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--skin-600);
  margin-bottom: 0.75rem;
  padding: 2px 10px;
  border-radius: 999px;
  background: rgba(var(--skin-rgb), 0.08);
}

:is(.dark *).latest-label {
  color: var(--skin-400);
  background: rgba(var(--skin-light-rgb), 0.1);
}

/* ===================================================================
   Posts grid
   =================================================================== */
.posts-grid {
  display: grid;
  gap: 1.25rem;
  grid-template-columns: 1fr;
}

@media (min-width: 768px) {
  .posts-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

.post-wrap {
  opacity: 0;
  will-change: opacity, transform;
}

.post-wrap.is-revealed {
  animation: cardReveal 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes cardReveal {
  0% {
    opacity: 0;
    transform: translateY(20px);
  }
  100% {
    opacity: 1;
    transform: translateY(0);
  }
}

/* ===================================================================
   Pagination
   =================================================================== */
.pagination {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1.5rem;
  margin-top: 3rem;
  padding-top: 2rem;
  border-top: 1px solid #f5f5f4;
}

:is(.dark *).pagination {
  border-top-color: #1a1918;
}

.page-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
  font-weight: 600;
  padding: 8px 16px;
  border-radius: 10px;
  color: var(--skin-600);
  background: rgba(var(--skin-rgb), 0.06);
  transition: all 0.2s ease;
  cursor: pointer;
}

.page-btn:hover:not(:disabled) {
  background: rgba(var(--skin-rgb), 0.12);
  transform: translateY(-1px);
}

.page-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

:is(.dark *).page-btn {
  color: var(--skin-400);
  background: rgba(var(--skin-light-rgb), 0.08);
}

:is(.dark *).page-btn:hover:not(:disabled) {
  background: rgba(var(--skin-light-rgb), 0.14);
}

.page-info {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem;
  color: #a8a29e;
}

:is(.dark *).page-info {
  color: #78716c;
}

/* ===================================================================
   Post count
   =================================================================== */
.post-count {
  text-align: center;
  margin-top: 1.5rem;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem;
  color: #a8a29e;
}

:is(.dark *).post-count {
  color: #78716c;
}

/* ===================================================================
   Loading skeletons
   =================================================================== */
.skeleton-card {
  padding: 1.5rem;
  border-radius: 14px;
  background: #ffffff;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

:is(.dark *).skeleton-card {
  background: #1a1918;
}

.skeleton-featured {
  grid-column: 1 / -1;
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
   Error & empty states
   =================================================================== */
.error-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: rgba(239, 68, 68, 0.1);
  color: #ef4444;
  font-weight: 800;
  font-size: 1.5rem;
}

:is(.dark *).error-icon {
  background: rgba(239, 68, 68, 0.15);
  color: #f87171;
}

.error-text {
  color: #ef4444;
  font-size: 0.95rem;
}

:is(.dark *).error-text {
  color: #f87171;
}

.retry-btn {
  font-size: 0.85rem;
  font-weight: 600;
  padding: 8px 20px;
  border-radius: 10px;
  background: var(--skin-600);
  color: white;
  transition:
    background 0.2s ease,
    transform 0.2s ease;
  cursor: pointer;
}

.retry-btn:hover {
  background: var(--skin-700);
  transform: translateY(-1px);
}

.empty-text {
  color: #78716c;
  font-size: 0.95rem;
}

:is(.dark *).empty-text {
  color: #a8a29e;
}

.clear-filter-btn {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
  font-weight: 500;
  padding: 6px 16px;
  border-radius: 999px;
  color: var(--skin-600);
  background: rgba(var(--skin-rgb), 0.08);
  transition: all 0.2s ease;
  cursor: pointer;
}

.clear-filter-btn:hover {
  background: rgba(var(--skin-rgb), 0.14);
}

:is(.dark *).clear-filter-btn {
  color: var(--skin-400);
  background: rgba(var(--skin-light-rgb), 0.1);
}
</style>
