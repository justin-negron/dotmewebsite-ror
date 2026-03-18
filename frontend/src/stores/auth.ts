import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import {
  login as apiLogin,
  refreshToken as apiRefresh,
  logout as apiLogout,
} from '@/services/auth'
import type { AdminUser, ApiError } from '@/types'

export const useAuthStore = defineStore('auth', () => {
  // State
  const accessToken = ref<string | null>(null)
  const admin = ref<AdminUser | null>(null)
  const loading = ref(false)
  const error = ref<ApiError | null>(null)
  const initialized = ref(false)

  // Getters
  const isAuthenticated = computed(() => !!accessToken.value && !!admin.value)

  // Actions
  async function login(email: string, password: string): Promise<void> {
    loading.value = true
    error.value = null

    try {
      const response = await apiLogin(email, password)
      accessToken.value = response.data.access_token
      admin.value = response.data.admin
    } catch (err) {
      error.value = err as ApiError
      throw err
    } finally {
      loading.value = false
    }
  }

  async function refresh(): Promise<boolean> {
    try {
      const response = await apiRefresh()
      accessToken.value = response.data.access_token
      admin.value = response.data.admin
      return true
    } catch {
      accessToken.value = null
      admin.value = null
      return false
    }
  }

  async function logout(): Promise<void> {
    try {
      if (accessToken.value) {
        await apiLogout(accessToken.value)
      }
    } finally {
      accessToken.value = null
      admin.value = null
    }
  }

  async function initialize(): Promise<void> {
    if (initialized.value) return
    initialized.value = true
    await refresh()
  }

  function clearError() {
    error.value = null
  }

  function $reset() {
    accessToken.value = null
    admin.value = null
    loading.value = false
    error.value = null
    initialized.value = false
  }

  return {
    accessToken,
    admin,
    loading,
    error,
    initialized,
    isAuthenticated,
    login,
    refresh,
    logout,
    initialize,
    clearError,
    $reset,
  }
})
