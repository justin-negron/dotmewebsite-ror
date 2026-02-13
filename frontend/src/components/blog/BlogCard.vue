<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import type { BlogPost } from '@/types'

const props = withDefaults(
  defineProps<{
    post: BlogPost
    featured?: boolean
  }>(),
  { featured: false }
)

const router = useRouter()

const formattedDate = computed(() => {
  const raw = props.post.published_at || props.post.created_at
  return new Date(raw).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  })
})

function navigateToPost() {
  router.push({ name: 'blog-post', params: { slug: props.post.slug } })
}
</script>

<template>
  <article
    :class="['blog-card', { 'blog-card--featured': featured }]"
    tabindex="0"
    role="link"
    @click="navigateToPost"
    @keydown.enter="navigateToPost"
  >
    <!-- Gradient accent -->
    <div class="card-accent" aria-hidden="true" />

    <!-- Meta gutter -->
    <div class="card-meta">
      <time class="card-date">{{ formattedDate }}</time>
      <span class="card-readtime">{{ post.reading_time }} min read</span>
    </div>

    <!-- Content -->
    <div class="card-body">
      <h3 class="card-title">{{ post.title }}</h3>
      <p class="card-excerpt">{{ post.excerpt }}</p>
    </div>

    <!-- Footer -->
    <div class="card-footer">
      <div v-if="post.tags.length" class="card-tags">
        <span v-for="tag in post.tags.slice(0, 4)" :key="tag" class="tag">
          {{ tag }}
        </span>
      </div>
      <span v-if="post.view_count > 0" class="card-views">
        {{ post.view_count }} {{ post.view_count === 1 ? 'view' : 'views' }}
      </span>
    </div>

    <!-- Hover arrow -->
    <div class="card-arrow" aria-hidden="true">
      <svg
        width="16"
        height="16"
        viewBox="0 0 16 16"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        stroke-linecap="round"
      >
        <line x1="2" y1="8" x2="12" y2="8" />
        <polyline points="8,4 12,8 8,12" />
      </svg>
    </div>
  </article>
</template>

<style scoped>
/* ===================================================================
   Blog card — text-forward with gradient left accent
   =================================================================== */
.blog-card {
  position: relative;
  padding: 1.5rem 1.5rem 1.5rem 1.75rem;
  background: #ffffff;
  border-radius: 14px;
  cursor: pointer;
  overflow: hidden;
  box-shadow:
    0 1px 3px rgba(0, 0, 0, 0.06),
    0 2px 8px rgba(0, 0, 0, 0.03);
  transition:
    transform 0.25s cubic-bezier(0.16, 1, 0.3, 1),
    box-shadow 0.25s ease,
    background 0.3s ease;
}

.blog-card:hover {
  transform: translateY(-3px);
  box-shadow:
    0 4px 14px rgba(0, 0, 0, 0.08),
    0 10px 28px rgba(0, 0, 0, 0.06);
}

:is(.dark *).blog-card {
  background: #1a1918;
  box-shadow:
    0 1px 3px rgba(0, 0, 0, 0.25),
    0 2px 8px rgba(0, 0, 0, 0.15);
}

:is(.dark *).blog-card:hover {
  box-shadow:
    0 4px 14px rgba(0, 0, 0, 0.35),
    0 10px 28px rgba(0, 0, 0, 0.25);
}

/* ===================================================================
   Gradient left accent — fades from skin color to transparent
   =================================================================== */
.card-accent {
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 3px;
  background: linear-gradient(to bottom, var(--skin-500), transparent 85%);
  opacity: 0.35;
  transition:
    opacity 0.3s ease,
    width 0.3s ease;
}

.blog-card:hover .card-accent {
  opacity: 1;
  width: 4px;
}

:is(.dark *).card-accent {
  background: linear-gradient(to bottom, var(--skin-400), transparent 85%);
}

/* ===================================================================
   Meta gutter — date + reading time
   =================================================================== */
.card-meta {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 0.75rem;
}

.card-date {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem;
  font-weight: 500;
  color: var(--skin-600);
  letter-spacing: 0.01em;
}

:is(.dark *).card-date {
  color: var(--skin-400);
}

.card-readtime {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.7rem;
  color: #a8a29e;
  padding: 1px 8px;
  border-radius: 999px;
  background: rgba(0, 0, 0, 0.04);
}

:is(.dark *).card-readtime {
  color: #78716c;
  background: rgba(255, 255, 255, 0.05);
}

/* ===================================================================
   Body — title + excerpt
   =================================================================== */
.card-title {
  font-size: 1.15rem;
  font-weight: 700;
  line-height: 1.35;
  color: #1c1917;
  letter-spacing: -0.01em;
  transition: color 0.2s ease;
}

.blog-card:hover .card-title {
  color: var(--skin-600);
}

:is(.dark *).card-title {
  color: #fafaf9;
}

:is(.dark *).blog-card:hover .card-title {
  color: var(--skin-400);
}

.card-excerpt {
  margin-top: 0.5rem;
  font-size: 0.9rem;
  line-height: 1.65;
  color: #78716c;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

:is(.dark *).card-excerpt {
  color: #a8a29e;
}

/* ===================================================================
   Featured variant
   =================================================================== */
.blog-card--featured .card-title {
  font-size: 1.4rem;
  line-height: 1.3;
}

.blog-card--featured .card-excerpt {
  -webkit-line-clamp: 3;
  font-size: 0.95rem;
}

/* ===================================================================
   Footer — tags + view count
   =================================================================== */
.card-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 1rem;
  gap: 0.75rem;
}

.card-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.35rem;
}

.tag {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.65rem;
  font-weight: 500;
  padding: 2px 9px;
  border-radius: 999px;
  background: rgba(var(--skin-rgb), 0.07);
  color: var(--skin-700);
  white-space: nowrap;
  transition: background 0.2s ease;
}

.blog-card:hover .tag {
  background: rgba(var(--skin-rgb), 0.12);
}

:is(.dark *).tag {
  background: rgba(var(--skin-light-rgb), 0.08);
  color: var(--skin-400);
}

:is(.dark *).blog-card:hover .tag {
  background: rgba(var(--skin-light-rgb), 0.14);
}

.card-views {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.7rem;
  color: #a8a29e;
  white-space: nowrap;
  flex-shrink: 0;
}

:is(.dark *).card-views {
  color: #78716c;
}

/* ===================================================================
   Hover arrow — slides in from the right
   =================================================================== */
.card-arrow {
  position: absolute;
  right: 1.25rem;
  top: 50%;
  transform: translateY(-50%) translateX(8px);
  opacity: 0;
  color: var(--skin-500);
  transition:
    opacity 0.25s ease,
    transform 0.25s ease;
}

.blog-card:hover .card-arrow {
  opacity: 0.6;
  transform: translateY(-50%) translateX(0);
}

:is(.dark *).card-arrow {
  color: var(--skin-400);
}
</style>
