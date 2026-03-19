<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAdminBlogPostsStore } from '@/stores'
import AdminTagInput from '@/components/admin/AdminTagInput.vue'
import AdminMarkdownEditor from '@/components/admin/AdminMarkdownEditor.vue'
import { useImageUpload } from '@/composables/useImageUpload'
import { useDraftAutoSave } from '@/composables/useDraftAutoSave'
import type { BlogPostInput } from '@/types'

const route = useRoute()
const router = useRouter()
const store = useAdminBlogPostsStore()

const isEdit = computed(() => !!route.params.id)
const saving = ref(false)
const showDraftBar = ref(false)

const form = ref<BlogPostInput>({
  title: '',
  content: '',
  published: false,
  tags: [],
  slug: '',
  cover_image_url: '',
})

// Image upload
const { uploading: imageUploading, uploadFile } = useImageUpload()
const {
  uploading: coverUploading,
  uploadFile: uploadCoverFile,
  error: coverError,
} = useImageUpload()

// Auto-save
const { hasDraft, draftSavedAt, saveDraft, loadDraft, clearDraft } = useDraftAutoSave(
  isEdit.value ? (route.params.id as string) : 'new',
)

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

// Auto-save watcher
watch(
  form,
  (val) => {
    saveDraft({
      title: val.title,
      content: val.content,
      slug: val.slug || '',
      tags: val.tags,
      cover_image_url: val.cover_image_url,
    })
  },
  { deep: true },
)

function restoreDraft() {
  const draft = loadDraft()
  if (draft) {
    form.value = {
      title: draft.title,
      content: draft.content,
      slug: draft.slug,
      tags: [...draft.tags],
      cover_image_url: draft.cover_image_url,
      published: form.value.published, // keep current published state
    }
  }
  showDraftBar.value = false
}

function dismissDraft() {
  clearDraft()
  showDraftBar.value = false
}

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
        cover_image_url: p.cover_image_url || '',
      }
    }
  }

  // Show draft restoration bar if draft exists and is different
  if (hasDraft.value) {
    const draft = loadDraft()
    if (draft && draft.content !== form.value.content) {
      showDraftBar.value = true
    }
  }
})

async function handleImageUpload(file: File): Promise<string> {
  const url = await uploadFile(file)
  if (!url) throw new Error('Upload failed')
  return url
}

async function handleCoverUpload() {
  const input = document.createElement('input')
  input.type = 'file'
  input.accept = 'image/jpeg,image/png,image/gif,image/webp'
  input.onchange = async () => {
    const file = input.files?.[0]
    if (!file) return
    const url = await uploadCoverFile(file)
    if (url) {
      form.value.cover_image_url = url
    }
  }
  input.click()
}

function removeCoverImage() {
  form.value.cover_image_url = ''
}

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
    clearDraft()
    router.push({ name: 'admin-blog' })
  }
}

const draftTimeAgo = computed(() => {
  if (!draftSavedAt.value) return ''
  const diff = Date.now() - new Date(draftSavedAt.value).getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 1) return 'just now'
  if (mins < 60) return `${mins}m ago`
  const hours = Math.floor(mins / 60)
  if (hours < 24) return `${hours}h ago`
  const days = Math.floor(hours / 24)
  return `${days}d ago`
})
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

    <!-- Draft restoration bar -->
    <div v-if="showDraftBar" class="draft-bar">
      <span class="draft-text">
        Draft found from {{ draftTimeAgo }}.
      </span>
      <div class="draft-actions">
        <button type="button" class="draft-btn restore" @click="restoreDraft">restore</button>
        <button type="button" class="draft-btn dismiss" @click="dismissDraft">dismiss</button>
      </div>
    </div>

    <div v-if="store.error" class="error-block" @click="store.clearError()">
      <span class="error-prefix">error:</span> {{ store.error.message }}
    </div>

    <form class="form-card" @submit.prevent="handleSubmit">
      <!-- Cover image -->
      <div class="field">
        <label class="field-label">cover image:</label>
        <div v-if="form.cover_image_url" class="cover-preview">
          <img :src="form.cover_image_url" alt="Cover image" class="cover-img" />
          <button type="button" class="cover-remove" title="Remove cover image" @click="removeCoverImage">
            &times;
          </button>
        </div>
        <button
          v-else
          type="button"
          class="cover-upload"
          :disabled="coverUploading"
          @click="handleCoverUpload"
        >
          <span v-if="coverUploading">uploading...</span>
          <span v-else>+ add cover image</span>
        </button>
        <p v-if="coverError" class="field-error">{{ coverError }}</p>
      </div>

      <div class="field">
        <label class="field-label">title:</label>
        <input v-model="form.title" type="text" class="field-input" required />
      </div>

      <div class="field">
        <label class="field-label">slug:</label>
        <input v-model="form.slug" type="text" class="field-input" />
      </div>

      <div class="field">
        <label class="field-label">content:</label>
        <AdminMarkdownEditor
          v-model="form.content"
          min-height="450px"
          :on-image-upload="handleImageUpload"
        />
        <p v-if="imageUploading" class="upload-status">uploading image...</p>
      </div>

      <div class="field">
        <label class="field-label">tags:</label>
        <AdminTagInput v-model="form.tags" placeholder="Type + Enter to add" />
      </div>

      <div class="field">
        <label class="toggle-inline">
          <input v-model="form.published" type="checkbox" class="checkbox-input" />
          <span class="toggle-text">Publish immediately</span>
        </label>
      </div>

      <!-- Auto-save indicator -->
      <div v-if="draftSavedAt && !showDraftBar" class="autosave-indicator">
        draft saved {{ draftTimeAgo }}
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
  max-width: 1200px;
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

/* ===================================================================
   Draft bar
   =================================================================== */
.draft-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
  padding: 0.55rem 0.8rem;
  margin-bottom: 1rem;
  border-radius: 8px;
  background: rgba(var(--skin-rgb), 0.06);
  border: 1px solid rgba(var(--skin-rgb), 0.12);
}

:is(.dark *).draft-bar {
  background: rgba(var(--skin-light-rgb), 0.06);
  border-color: rgba(var(--skin-light-rgb), 0.1);
}

.draft-text {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem;
  color: var(--skin-700);
}

:is(.dark *).draft-text {
  color: var(--skin-400);
}

.draft-actions {
  display: flex;
  gap: 0.5rem;
}

.draft-btn {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.7rem;
  font-weight: 600;
  padding: 3px 10px;
  border-radius: 5px;
  border: none;
  cursor: pointer;
  transition: all 0.15s ease;
}

.draft-btn.restore {
  background: var(--skin-600);
  color: white;
}

.draft-btn.restore:hover {
  background: var(--skin-700);
}

:is(.dark *).draft-btn.restore {
  background: var(--skin-500);
}

.draft-btn.dismiss {
  background: transparent;
  color: #78716c;
  border: 1px solid #d6d3d1;
}

.draft-btn.dismiss:hover {
  background: #f5f5f4;
}

:is(.dark *).draft-btn.dismiss {
  color: #a8a29e;
  border-color: rgba(var(--skin-light-rgb), 0.12);
}

:is(.dark *).draft-btn.dismiss:hover {
  background: rgba(var(--skin-light-rgb), 0.06);
}

/* ===================================================================
   Error block
   =================================================================== */
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

/* ===================================================================
   Form card
   =================================================================== */
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

/* ===================================================================
   Fields
   =================================================================== */
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

.field-input {
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

.field-input:focus {
  border-color: var(--skin-400);
  box-shadow: 0 0 0 3px rgba(var(--skin-rgb), 0.08);
}

:is(.dark *).field-input {
  color: #e7e5e4;
  background: rgba(var(--skin-light-rgb), 0.03);
  border-color: rgba(var(--skin-light-rgb), 0.1);
}

.field-error {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.72rem;
  color: #dc2626;
  margin-top: 0.25rem;
}

:is(.dark *).field-error {
  color: #f87171;
}

.upload-status {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.72rem;
  color: var(--skin-600);
  margin-top: 0.25rem;
  animation: pulse 1.5s ease-in-out infinite;
}

:is(.dark *).upload-status {
  color: var(--skin-400);
}

/* ===================================================================
   Cover image
   =================================================================== */
.cover-upload {
  width: 100%;
  padding: 2rem;
  border: 2px dashed #d6d3d1;
  border-radius: 10px;
  background: transparent;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
  color: #78716c;
  cursor: pointer;
  transition: all 0.2s ease;
  text-align: center;
}

.cover-upload:hover:not(:disabled) {
  border-color: var(--skin-400);
  color: var(--skin-600);
  background: rgba(var(--skin-rgb), 0.03);
}

.cover-upload:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

:is(.dark *).cover-upload {
  border-color: rgba(var(--skin-light-rgb), 0.12);
  color: #a8a29e;
}

:is(.dark *).cover-upload:hover:not(:disabled) {
  border-color: var(--skin-500);
  color: var(--skin-400);
  background: rgba(var(--skin-light-rgb), 0.04);
}

.cover-preview {
  position: relative;
  border-radius: 10px;
  overflow: hidden;
  max-height: 240px;
}

.cover-img {
  width: 100%;
  height: auto;
  max-height: 240px;
  object-fit: cover;
  display: block;
}

.cover-remove {
  position: absolute;
  top: 8px;
  right: 8px;
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: rgba(0, 0, 0, 0.6);
  color: white;
  font-size: 1.1rem;
  border: none;
  cursor: pointer;
  transition: background 0.15s ease;
  line-height: 1;
}

.cover-remove:hover {
  background: rgba(239, 68, 68, 0.8);
}

/* ===================================================================
   Toggle / Checkbox
   =================================================================== */
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

/* ===================================================================
   Auto-save indicator
   =================================================================== */
.autosave-indicator {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.68rem;
  color: #a8a29e;
  text-align: right;
  margin-bottom: 0.5rem;
}

:is(.dark *).autosave-indicator {
  color: #57534e;
}

/* ===================================================================
   Form actions
   =================================================================== */
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

@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}
</style>
