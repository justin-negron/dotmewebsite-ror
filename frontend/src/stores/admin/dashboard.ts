import { ref } from 'vue'
import { defineStore } from 'pinia'
import * as api from '@/services/admin/analytics'
import type { AdminDashboardData, ApiError } from '@/types'

export const useAdminDashboardStore = defineStore('admin-dashboard', () => {
  const data = ref<AdminDashboardData | null>(null)
  const loading = ref(false)
  const error = ref<ApiError | null>(null)

  async function fetchDashboard(days?: number): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const response = await api.getDashboard(days)
      data.value = response.data
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
    data.value = null
    loading.value = false
    error.value = null
  }

  return {
    data,
    loading,
    error,
    fetchDashboard,
    clearError,
    $reset,
  }
})
