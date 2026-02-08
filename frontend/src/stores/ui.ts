import { ref, computed } from 'vue'
import { defineStore } from 'pinia'

export interface Toast {
  id: number
  message: string
  type: 'success' | 'error' | 'warning' | 'info'
  duration: number
}

export const useUiStore = defineStore('ui', () => {
  // State
  const isMobileMenuOpen = ref(false)
  const isPageLoading = ref(false)
  const activeSection = ref('')
  const toasts = ref<Toast[]>([])
  const nextToastId = ref(0)

  // Getters
  const hasToasts = computed(() => toasts.value.length > 0)
  const latestToast = computed(() => toasts.value[toasts.value.length - 1] ?? null)

  // Actions
  function toggleMobileMenu() {
    isMobileMenuOpen.value = !isMobileMenuOpen.value
  }

  function closeMobileMenu() {
    isMobileMenuOpen.value = false
  }

  function setPageLoading(value: boolean) {
    isPageLoading.value = value
  }

  function setActiveSection(section: string) {
    activeSection.value = section
  }

  function addToast(message: string, type: Toast['type'] = 'info', duration = 5000) {
    const id = nextToastId.value++
    toasts.value.push({ id, message, type, duration })

    if (duration > 0) {
      setTimeout(() => removeToast(id), duration)
    }
  }

  function removeToast(id: number) {
    toasts.value = toasts.value.filter((t) => t.id !== id)
  }

  function clearToasts() {
    toasts.value = []
  }

  function $reset() {
    isMobileMenuOpen.value = false
    isPageLoading.value = false
    activeSection.value = ''
    toasts.value = []
    nextToastId.value = 0
  }

  return {
    // State
    isMobileMenuOpen,
    isPageLoading,
    activeSection,
    toasts,

    // Getters
    hasToasts,
    latestToast,

    // Actions
    toggleMobileMenu,
    closeMobileMenu,
    setPageLoading,
    setActiveSection,
    addToast,
    removeToast,
    clearToasts,
    $reset,
  }
})
