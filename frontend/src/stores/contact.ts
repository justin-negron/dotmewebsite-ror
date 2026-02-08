import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { submitContactForm } from '@/services/contacts'
import type { ContactFormData, ApiError } from '@/types'

export const useContactStore = defineStore('contact', () => {
  // State
  const submitting = ref(false)
  const submitted = ref(false)
  const error = ref<ApiError | null>(null)
  const validationErrors = ref<Record<string, string[]> | null>(null)

  // Getters
  const hasValidationErrors = computed(
    () => validationErrors.value !== null && Object.keys(validationErrors.value).length > 0
  )

  // Actions
  async function submitForm(data: ContactFormData): Promise<boolean> {
    submitting.value = true
    error.value = null
    validationErrors.value = null

    try {
      await submitContactForm(data)
      submitted.value = true
      return true
    } catch (err) {
      const apiError = err as ApiError
      error.value = apiError
      validationErrors.value = apiError.errors ?? null
      return false
    } finally {
      submitting.value = false
    }
  }

  function resetForm() {
    submitted.value = false
    error.value = null
    validationErrors.value = null
  }

  function $reset() {
    submitting.value = false
    submitted.value = false
    error.value = null
    validationErrors.value = null
  }

  return {
    // State
    submitting,
    submitted,
    error,
    validationErrors,

    // Getters
    hasValidationErrors,

    // Actions
    submitForm,
    resetForm,
    $reset,
  }
})
