import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import {
  getProjects,
  getProject,
  getFeaturedProjects,
  getProjectsByTechnology,
} from '@/services/projects'
import type { Project, ApiError } from '@/types'

export const useProjectsStore = defineStore('projects', () => {
  // State
  const projects = ref<Project[]>([])
  const currentProject = ref<Project | null>(null)
  const featuredProjects = ref<Project[]>([])
  const loading = ref(false)
  const error = ref<ApiError | null>(null)

  // Cache flags
  const allLoaded = ref(false)
  const featuredLoaded = ref(false)

  // Getters
  const projectCount = computed(() => projects.value.length)

  const sortedProjects = computed(() =>
    [...projects.value].sort((a, b) => a.display_order - b.display_order)
  )

  const hasProjects = computed(() => projects.value.length > 0)

  // Actions
  async function fetchProjects(force = false): Promise<void> {
    if (allLoaded.value && !force) return

    loading.value = true
    error.value = null

    try {
      const response = await getProjects()
      projects.value = response.data
      allLoaded.value = true
    } catch (err) {
      error.value = err as ApiError
    } finally {
      loading.value = false
    }
  }

  async function fetchProject(id: number | string): Promise<void> {
    const numericId = typeof id === 'string' ? parseInt(id, 10) : id
    const cached = projects.value.find((p) => p.id === numericId)

    if (cached) {
      currentProject.value = cached
      return
    }

    loading.value = true
    error.value = null

    try {
      const response = await getProject(id)
      currentProject.value = response.data
    } catch (err) {
      error.value = err as ApiError
    } finally {
      loading.value = false
    }
  }

  async function fetchFeaturedProjects(force = false): Promise<void> {
    if (featuredLoaded.value && !force) return

    loading.value = true
    error.value = null

    try {
      const response = await getFeaturedProjects()
      featuredProjects.value = response.data
      featuredLoaded.value = true
    } catch (err) {
      error.value = err as ApiError
    } finally {
      loading.value = false
    }
  }

  async function fetchProjectsByTech(technology: string): Promise<Project[]> {
    loading.value = true
    error.value = null

    try {
      const response = await getProjectsByTechnology(technology)
      return response.data
    } catch (err) {
      error.value = err as ApiError
      return []
    } finally {
      loading.value = false
    }
  }

  function clearError() {
    error.value = null
  }

  function $reset() {
    projects.value = []
    currentProject.value = null
    featuredProjects.value = []
    loading.value = false
    error.value = null
    allLoaded.value = false
    featuredLoaded.value = false
  }

  return {
    // State
    projects,
    currentProject,
    featuredProjects,
    loading,
    error,

    // Getters
    projectCount,
    sortedProjects,
    hasProjects,

    // Actions
    fetchProjects,
    fetchProject,
    fetchFeaturedProjects,
    fetchProjectsByTech,
    clearError,
    $reset,
  }
})
