import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { getExperiences, getExperience, getCurrentExperience } from '@/services/experiences'
import type { Experience, ApiError } from '@/types'

export const useExperiencesStore = defineStore('experiences', () => {
  // State
  const experiences = ref<Experience[]>([])
  const currentExperience = ref<Experience | null>(null)
  const selectedExperience = ref<Experience | null>(null)
  const loading = ref(false)
  const error = ref<ApiError | null>(null)
  const loaded = ref(false)

  // Getters
  const sortedExperiences = computed(() =>
    [...experiences.value].sort((a, b) => a.display_order - b.display_order)
  )

  const chronologicalExperiences = computed(() =>
    [...experiences.value].sort(
      (a, b) => new Date(b.start_date).getTime() - new Date(a.start_date).getTime()
    )
  )

  const hasExperiences = computed(() => experiences.value.length > 0)

  // Actions
  async function fetchExperiences(force = false): Promise<void> {
    if (loaded.value && !force) return

    loading.value = true
    error.value = null

    try {
      const response = await getExperiences()
      experiences.value = response.data
      loaded.value = true
    } catch (err) {
      error.value = err as ApiError
    } finally {
      loading.value = false
    }
  }

  async function fetchExperience(id: number | string): Promise<void> {
    const numericId = typeof id === 'string' ? parseInt(id, 10) : id
    const cached = experiences.value.find((e) => e.id === numericId)

    if (cached) {
      selectedExperience.value = cached
      return
    }

    loading.value = true
    error.value = null

    try {
      const response = await getExperience(id)
      selectedExperience.value = response.data
    } catch (err) {
      error.value = err as ApiError
    } finally {
      loading.value = false
    }
  }

  async function fetchCurrentExperience(): Promise<void> {
    loading.value = true
    error.value = null

    try {
      const result = await getCurrentExperience()
      currentExperience.value = result ?? null
    } catch (err) {
      error.value = err as ApiError
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
    selectedExperience.value = null
    loading.value = false
    error.value = null
    loaded.value = false
  }

  return {
    // State
    experiences,
    currentExperience,
    selectedExperience,
    loading,
    error,

    // Getters
    sortedExperiences,
    chronologicalExperiences,
    hasExperiences,

    // Actions
    fetchExperiences,
    fetchExperience,
    fetchCurrentExperience,
    clearError,
    $reset,
  }
})
