import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import * as api from '@/services/admin/experiences'
import type { Experience, ExperienceInput, ApiError, PaginationMeta } from '@/types'

export const useAdminExperiencesStore = defineStore('admin-experiences', () => {
  const experiences = ref<Experience[]>([])
  const currentExperience = ref<Experience | null>(null)
  const loading = ref(false)
  const error = ref<ApiError | null>(null)
  const pagination = ref<PaginationMeta | null>(null)

  const experienceCount = computed(
    () => pagination.value?.total_count ?? experiences.value.length,
  )

  async function fetchAll(params: Record<string, unknown> = {}): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const response = await api.getAll(params)
      experiences.value = response.data
      pagination.value = response.meta as PaginationMeta
    } catch (err) {
      error.value = err as ApiError
    } finally {
      loading.value = false
    }
  }

  async function fetchOne(id: number | string): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const response = await api.getOne(id)
      currentExperience.value = response.data
    } catch (err) {
      error.value = err as ApiError
    } finally {
      loading.value = false
    }
  }

  async function create(data: ExperienceInput): Promise<Experience | null> {
    loading.value = true
    error.value = null
    try {
      const response = await api.create(data)
      const experience = response.data
      experiences.value.unshift(experience)
      return experience
    } catch (err) {
      error.value = err as ApiError
      return null
    } finally {
      loading.value = false
    }
  }

  async function update(
    id: number | string,
    data: Partial<ExperienceInput>,
  ): Promise<Experience | null> {
    loading.value = true
    error.value = null
    try {
      const response = await api.update(id, data)
      const updated = response.data
      const idx = experiences.value.findIndex((e) => e.id === updated.id)
      if (idx !== -1) experiences.value[idx] = updated
      currentExperience.value = updated
      return updated
    } catch (err) {
      error.value = err as ApiError
      return null
    } finally {
      loading.value = false
    }
  }

  async function remove(id: number | string): Promise<boolean> {
    loading.value = true
    error.value = null
    try {
      await api.remove(id)
      experiences.value = experiences.value.filter((e) => e.id !== Number(id))
      if (currentExperience.value?.id === Number(id)) currentExperience.value = null
      return true
    } catch (err) {
      error.value = err as ApiError
      return false
    } finally {
      loading.value = false
    }
  }

  function clearError() {
    error.value = null
  }

  function $reset() {
    experiences.value = []
    currentExperience.value = null
    loading.value = false
    error.value = null
    pagination.value = null
  }

  return {
    experiences,
    currentExperience,
    loading,
    error,
    pagination,
    experienceCount,
    fetchAll,
    fetchOne,
    create,
    update,
    remove,
    clearError,
    $reset,
  }
})
