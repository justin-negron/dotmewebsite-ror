import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import * as api from '@/services/admin/projects'
import type { Project, ProjectInput, ApiError, PaginationMeta } from '@/types'

export const useAdminProjectsStore = defineStore('admin-projects', () => {
  const projects = ref<Project[]>([])
  const currentProject = ref<Project | null>(null)
  const loading = ref(false)
  const error = ref<ApiError | null>(null)
  const pagination = ref<PaginationMeta | null>(null)

  const projectCount = computed(() => pagination.value?.total_count ?? projects.value.length)

  async function fetchAll(params: Record<string, unknown> = {}): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const response = await api.getAll(params)
      projects.value = response.data
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
      currentProject.value = response.data
    } catch (err) {
      error.value = err as ApiError
    } finally {
      loading.value = false
    }
  }

  async function create(data: ProjectInput): Promise<Project | null> {
    loading.value = true
    error.value = null
    try {
      const response = await api.create(data)
      const project = response.data
      projects.value.unshift(project)
      return project
    } catch (err) {
      error.value = err as ApiError
      return null
    } finally {
      loading.value = false
    }
  }

  async function update(id: number | string, data: Partial<ProjectInput>): Promise<Project | null> {
    loading.value = true
    error.value = null
    try {
      const response = await api.update(id, data)
      const updated = response.data
      const idx = projects.value.findIndex((p) => p.id === updated.id)
      if (idx !== -1) projects.value[idx] = updated
      currentProject.value = updated
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
      projects.value = projects.value.filter((p) => p.id !== Number(id))
      if (currentProject.value?.id === Number(id)) currentProject.value = null
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
    projects.value = []
    currentProject.value = null
    loading.value = false
    error.value = null
    pagination.value = null
  }

  return {
    projects,
    currentProject,
    loading,
    error,
    pagination,
    projectCount,
    fetchAll,
    fetchOne,
    create,
    update,
    remove,
    clearError,
    $reset,
  }
})
