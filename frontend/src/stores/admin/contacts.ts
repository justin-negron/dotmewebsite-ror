import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import * as api from '@/services/admin/contacts'
import type { Contact, ApiError, PaginationMeta } from '@/types'

export const useAdminContactsStore = defineStore('admin-contacts', () => {
  const contacts = ref<Contact[]>([])
  const currentContact = ref<Contact | null>(null)
  const loading = ref(false)
  const error = ref<ApiError | null>(null)
  const pagination = ref<PaginationMeta | null>(null)

  const contactCount = computed(() => pagination.value?.total_count ?? contacts.value.length)
  const unreadCount = computed(() => contacts.value.filter((c) => c.status === 'new').length)

  async function fetchAll(params: Record<string, unknown> = {}): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const response = await api.getAll(params)
      contacts.value = response.data
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
      currentContact.value = response.data
    } catch (err) {
      error.value = err as ApiError
    } finally {
      loading.value = false
    }
  }

  async function updateStatus(id: number | string, status: string): Promise<boolean> {
    error.value = null
    try {
      const response = await api.updateStatus(id, status)
      const updated = response.data
      const idx = contacts.value.findIndex((c) => c.id === updated.id)
      if (idx !== -1) contacts.value[idx] = updated
      if (currentContact.value?.id === updated.id) currentContact.value = updated
      return true
    } catch (err) {
      error.value = err as ApiError
      return false
    }
  }

  async function remove(id: number | string): Promise<boolean> {
    loading.value = true
    error.value = null
    try {
      await api.remove(id)
      contacts.value = contacts.value.filter((c) => c.id !== Number(id))
      if (currentContact.value?.id === Number(id)) currentContact.value = null
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
    contacts.value = []
    currentContact.value = null
    loading.value = false
    error.value = null
    pagination.value = null
  }

  return {
    contacts,
    currentContact,
    loading,
    error,
    pagination,
    contactCount,
    unreadCount,
    fetchAll,
    fetchOne,
    updateStatus,
    remove,
    clearError,
    $reset,
  }
})
