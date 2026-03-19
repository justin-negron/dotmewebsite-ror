<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAdminProjectsStore } from '@/stores'
import AdminTagInput from '@/components/admin/AdminTagInput.vue'
import type { ProjectInput } from '@/types'

const route = useRoute()
const router = useRouter()
const store = useAdminProjectsStore()

const isEdit = computed(() => !!route.params.id)
const saving = ref(false)

const form = ref<ProjectInput>({
  title: '',
  description: '',
  tech_stack: [],
  featured: false,
  display_order: undefined,
  github_url: '',
  live_url: '',
  image_url: '',
})

onMounted(async () => {
  if (isEdit.value) {
    await store.fetchOne(route.params.id as string)
    if (store.currentProject) {
      const p = store.currentProject
      form.value = {
        title: p.title,
        description: p.description,
        tech_stack: [...p.tech_stack],
        featured: p.featured,
        display_order: p.display_order,
        github_url: p.github_url || '',
        live_url: p.live_url || '',
        image_url: p.image_url || '',
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
    router.push({ name: 'admin-projects' })
  }
}
</script>

<template>
  <div class="form-view">
    <div class="form-header">
      <h2 class="form-title">
        <span class="prompt">$</span> {{ isEdit ? 'edit' : 'new' }} project
      </h2>
      <RouterLink :to="{ name: 'admin-projects' }" class="back-link">
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
        <label class="field-label">description:</label>
        <textarea v-model="form.description" class="field-textarea" rows="4" required />
      </div>

      <div class="field">
        <label class="field-label">tech_stack:</label>
        <AdminTagInput v-model="form.tech_stack" placeholder="Type + Enter to add" />
      </div>

      <div class="field-row">
        <div class="field">
          <label class="field-label">github_url:</label>
          <input v-model="form.github_url" type="url" class="field-input" />
        </div>
        <div class="field">
          <label class="field-label">live_url:</label>
          <input v-model="form.live_url" type="url" class="field-input" />
        </div>
      </div>

      <div class="field">
        <label class="field-label">image_url:</label>
        <input v-model="form.image_url" type="url" class="field-input" />
      </div>

      <div class="field-row">
        <div class="field">
          <label class="field-label">display_order:</label>
          <input v-model.number="form.display_order" type="number" class="field-input" min="0" />
        </div>
        <div class="field toggle-field">
          <label class="field-label">featured:</label>
          <button
            type="button"
            :class="['toggle-btn', form.featured ? 'is-on' : '']"
            @click="form.featured = !form.featured"
          >
            {{ form.featured ? 'yes' : 'no' }}
          </button>
        </div>
      </div>

      <div class="form-actions">
        <RouterLink :to="{ name: 'admin-projects' }" class="cancel-btn">
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
  max-width: 680px;
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
  transition: color 0.15s ease;
}

.back-link:hover {
  color: var(--skin-800);
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

.field-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.field-label {
  display: block;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  font-weight: 600;
  color: var(--skin-600);
  margin-bottom: 0.35rem;
}

:is(.dark *).field-label {
  color: var(--skin-400);
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

:is(.dark *).field-input:focus,
:is(.dark *).field-textarea:focus {
  border-color: var(--skin-500);
  box-shadow: 0 0 0 3px rgba(var(--skin-light-rgb), 0.06);
}

.field-textarea {
  resize: vertical;
  min-height: 80px;
}

.toggle-field {
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
}

.toggle-btn {
  width: fit-content;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem;
  font-weight: 600;
  padding: 0.45rem 0.8rem;
  border-radius: 6px;
  border: 1.5px solid #e7e5e4;
  background: transparent;
  color: #78716c;
  cursor: pointer;
  transition: all 0.15s ease;
}

.toggle-btn.is-on {
  color: #16a34a;
  border-color: rgba(22, 163, 74, 0.3);
  background: rgba(22, 163, 74, 0.06);
}

:is(.dark *).toggle-btn {
  border-color: rgba(var(--skin-light-rgb), 0.1);
  color: #a8a29e;
}

:is(.dark *).toggle-btn.is-on {
  color: #4ade80;
  border-color: rgba(74, 222, 128, 0.3);
  background: rgba(74, 222, 128, 0.08);
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
  transition: all 0.15s ease;
}

.cancel-btn:hover {
  background: #f5f5f4;
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
  box-shadow: 0 2px 8px rgba(var(--skin-rgb), 0.25);
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

@media (max-width: 640px) {
  .field-row {
    grid-template-columns: 1fr;
  }
}
</style>
