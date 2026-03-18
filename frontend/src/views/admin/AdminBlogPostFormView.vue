<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAdminBlogPostsStore } from '@/stores'
import AdminTagInput from '@/components/admin/AdminTagInput.vue'
import { marked } from 'marked'
import DOMPurify from 'dompurify'
import type { BlogPostInput } from '@/types'

const route = useRoute()
const router = useRouter()
const store = useAdminBlogPostsStore()

const isEdit = computed(() => !!route.params.id)
const saving = ref(false)
const showPreview = ref(false)

const form = ref<BlogPostInput>({
  title: '',
  content: '',
  published: false,
  tags: [],
  slug: '',
})

const renderedContent = computed(() => {
  if (!form.value.content) return ''
  const raw = marked.parse(form.value.content)
  return DOMPurify.sanitize(raw as string)
})

// Auto-generate slug from title (only for new posts)
watch(
  () => form.value.title,
  (title) => {
    if (!isEdit.value && title) {
      form.value.slug = title
        .toLowerCase()
        .replace(/[^a-z0-9\s-]/g, '')
        .replace(/\s+/g, '-')
        .replace(/-+/g, '-')
        .replace(/^-|-$/g, '')
    }
  },
)

onMounted(async () => {
  if (isEdit.value) {
    await store.fetchOne(route.params.id as string)
    if (store.currentPost) {
      const p = store.currentPost
      form.value = {
        title: p.title,
        content: p.content,
        published: p.published,
        tags: [...p.tags],
        slug: p.slug,
      }
    }
  }
})

async function handleSubmit() {
  saving.value = true
  store.clearError()
  let result
  if (isEdit.value) {
    result = await store.update(route.params.id as string, form.value)
  } else {
    result = await store.create(form.value)
  }
  saving.value = false
  if (result) {
    router.push({ name: 'admin-blog' })
  }
}
</script>

<template>
  <div class="form-view">
    <div class="form-header">
      <h2 class="form-title">
        <span class="prompt">$</span> {{ isEdit ? 'edit' : 'new' }} post
      </h2>
      <RouterLink :to="{ name: 'admin-blog' }" class="back-link">
        &larr; back
      </RouterLink>
    </div>

    <div v-if="store.error" class="error-block" @click="store.clearError()">
      <span class="error-prefix">error:</span> {{ store.error.message }}
    </div>

    <form class="form-card" @submit.prevent="handleSubmit">
      <div class="field">
        <label class="field-label">title:</label>
        <input v-model="form.title" type="text" class="field-input" required />
      </div>

      <div class="field">
        <label class="field-label">slug:</label>
        <input v-model="form.slug" type="text" class="field-input" />
      </div>

      <div class="field">
        <label class="field-label">
          content:
          <button type="button" class="preview-toggle" @click="showPreview = !showPreview">
            {{ showPreview ? 'editor' : 'preview' }}
          </button>
        </label>
        <div v-if="showPreview" class="markdown-preview prose" v-html="renderedContent" />
        <textarea v-else v-model="form.content" class="field-textarea content-editor" rows="16" required />
      </div>

      <div class="field">
        <label class="field-label">tags:</label>
        <AdminTagInput v-model="form.tags!" placeholder="Type + Enter to add" />
      </div>

      <div class="field">
        <label class="toggle-inline">
          <input v-model="form.published" type="checkbox" class="checkbox-input" />
          <span class="toggle-text">Publish immediately</span>
        </label>
      </div>

      <div class="form-actions">
        <RouterLink :to="{ name: 'admin-blog' }" class="cancel-btn">
          <span class="btn-prompt">$</span> cancel
        </RouterLink>
        <button type="submit" class="submit-btn" :disabled="saving">
          <span v-if="saving">saving...</span>
          <span v-else><span class="btn-prompt">$</span> {{ isEdit ? 'update' : 'create' }}</span>
        </button>
      </div>
    </form>
  </div>
</template>

<style scoped>
.form-view {
  max-width: 800px;
}

.form-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}

.form-title {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.9rem;
  font-weight: 600;
  color: #1c1917;
}

:is(.dark *).form-title {
  color: #e7e5e4;
}

.prompt {
  color: var(--skin-600);
}

:is(.dark *).prompt {
  color: var(--skin-400);
}

.back-link {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem;
  color: var(--skin-600);
  text-decoration: none;
}

:is(.dark *).back-link {
  color: var(--skin-400);
}

.error-block {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
  padding: 0.6rem 0.8rem;
  margin-bottom: 1rem;
  border-radius: 8px;
  background: rgba(239, 68, 68, 0.06);
  border: 1px solid rgba(239, 68, 68, 0.15);
  color: #dc2626;
  cursor: pointer;
}

:is(.dark *).error-block {
  background: rgba(239, 68, 68, 0.08);
  border-color: rgba(239, 68, 68, 0.2);
  color: #f87171;
}

.error-prefix {
  font-weight: 700;
}

.form-card {
  background: #ffffff;
  border: 1px solid #e7e5e4;
  border-radius: 12px;
  padding: 1.5rem;
  transition:
    background 0.3s ease,
    border-color 0.3s ease;
}

:is(.dark *).form-card {
  background: #1c1917;
  border-color: rgba(var(--skin-light-rgb), 0.08);
}

.field {
  margin-bottom: 1rem;
}

.field-label {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  font-weight: 600;
  color: var(--skin-600);
  margin-bottom: 0.35rem;
}

:is(.dark *).field-label {
  color: var(--skin-400);
}

.preview-toggle {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.68rem;
  font-weight: 600;
  color: var(--skin-500);
  background: none;
  border: none;
  cursor: pointer;
  padding: 0.2rem 0.4rem;
  border-radius: 4px;
  transition: all 0.15s ease;
}

.preview-toggle:hover {
  background: rgba(var(--skin-rgb), 0.06);
}

.field-input,
.field-textarea {
  width: 100%;
  padding: 0.55rem 0.7rem;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.82rem;
  color: #1c1917;
  background: #fafaf9;
  border: 1.5px solid #e7e5e4;
  border-radius: 8px;
  outline: none;
  transition:
    border-color 0.2s ease,
    box-shadow 0.2s ease;
}

.field-input:focus,
.field-textarea:focus {
  border-color: var(--skin-400);
  box-shadow: 0 0 0 3px rgba(var(--skin-rgb), 0.08);
}

:is(.dark *).field-input,
:is(.dark *).field-textarea {
  color: #e7e5e4;
  background: rgba(var(--skin-light-rgb), 0.03);
  border-color: rgba(var(--skin-light-rgb), 0.1);
}

.field-textarea {
  resize: vertical;
  min-height: 80px;
}

.content-editor {
  min-height: 320px;
  line-height: 1.7;
}

.markdown-preview {
  min-height: 320px;
  padding: 1rem;
  background: #fafaf9;
  border: 1.5px solid #e7e5e4;
  border-radius: 8px;
  font-size: 0.85rem;
  line-height: 1.7;
  color: #1c1917;
  overflow-y: auto;
}

:is(.dark *).markdown-preview {
  background: rgba(var(--skin-light-rgb), 0.03);
  border-color: rgba(var(--skin-light-rgb), 0.1);
  color: #e7e5e4;
}

.toggle-inline {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
}

.checkbox-input {
  accent-color: var(--skin-600);
}

.toggle-text {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
  color: #44403c;
}

:is(.dark *).toggle-text {
  color: #d6d3d1;
}

.form-actions {
  display: flex;
  gap: 0.75rem;
  justify-content: flex-end;
  margin-top: 1.5rem;
  padding-top: 1rem;
  border-top: 1px solid #e7e5e4;
}

:is(.dark *).form-actions {
  border-color: rgba(var(--skin-light-rgb), 0.06);
}

.cancel-btn {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  font-weight: 600;
  color: #78716c;
  padding: 0.5rem 1rem;
  border-radius: 8px;
  border: 1.5px solid #e7e5e4;
  text-decoration: none;
}

:is(.dark *).cancel-btn {
  color: #a8a29e;
  border-color: rgba(var(--skin-light-rgb), 0.12);
}

.submit-btn {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  font-weight: 600;
  color: white;
  background: linear-gradient(135deg, var(--skin-600), var(--skin-700));
  padding: 0.5rem 1.25rem;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.submit-btn:hover:not(:disabled) {
  transform: translateY(-1px);
}

.submit-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

:is(.dark *).submit-btn {
  background: linear-gradient(135deg, var(--skin-500), var(--skin-600));
}

.btn-prompt {
  opacity: 0.5;
}
</style>
