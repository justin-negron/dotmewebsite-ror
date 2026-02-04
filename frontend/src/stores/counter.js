import { ref, computed } from '../../node_modules_backup/vue'
import { defineStore } from '../../node_modules_backup/pinia'

export const useCounterStore = defineStore('counter', () => {
  const count = ref(0)
  const doubleCount = computed(() => count.value * 2)
  function increment() {
    count.value++
  }

  return { count, doubleCount, increment }
})
