import { ref } from 'vue'
import type { Ref } from 'vue'
import { handleApiError } from '@/services'
import type { ApiError } from '@/types'

/**
 * Composable for component-local API calls that do NOT need global state.
 *
 * For data shared across components (projects, experiences, blog posts),
 * prefer using the Pinia stores in @/stores instead.
 *
 * Use cases for useApi:
 * - One-off mutations (e.g., a form submission with component-local state)
 * - API calls whose results are only needed in a single component
 * - Prototyping a new feature before creating a dedicated store
 */
export function useApi<T>(apiFunction: (...args: unknown[]) => Promise<T>) {
  const data: Ref<T | null> = ref(null)
  const loading = ref(false)
  const error: Ref<ApiError | null> = ref(null)

  async function execute(...args: unknown[]) {
    loading.value = true
    error.value = null

    try {
      data.value = await apiFunction(...args)
      return data.value
    } catch (err) {
      error.value = handleApiError(err as import('axios').AxiosError)
      throw err
    } finally {
      loading.value = false
    }
  }

  return {
    data,
    loading,
    error,
    execute,
  }
}
