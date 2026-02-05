import { ref } from 'vue'
import { handleApiError } from '@/services'

/**
 * Composable for API calls with loading and error states
 * @param {Function} apiFunction - API function to call
 * @returns {Object} - { data, loading, error, execute }
 */
export function useApi(apiFunction) {
  const data = ref(null)
  const loading = ref(false)
  const error = ref(null)

  const execute = async (...args) => {
    loading.value = true
    error.value = null
    
    try {
      data.value = await apiFunction(...args)
      return data.value
    } catch (err) {
      error.value = handleApiError(err)
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