<script setup lang="ts">
import { useUiStore } from '@/stores'
import type { Toast } from '@/stores/ui'

const uiStore = useUiStore()

const typeClasses: Record<Toast['type'], string> = {
  success:
    'bg-success-50 border-success-500 text-success-800 dark:bg-success-900/50 dark:text-success-200',
  error: 'bg-error-50 border-error-500 text-error-800 dark:bg-error-900/50 dark:text-error-200',
  warning:
    'bg-warning-50 border-warning-500 text-warning-800 dark:bg-warning-900/50 dark:text-warning-200',
  info: 'bg-info-50 border-info-500 text-info-800 dark:bg-info-900/50 dark:text-info-200',
}

const iconPaths: Record<Toast['type'], string> = {
  success: 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z',
  error: 'M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z',
  warning:
    'M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16.5c-.77.833.192 2.5 1.732 2.5z',
  info: 'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
}
</script>

<template>
  <div
    class="fixed bottom-4 right-4 z-[1070] flex flex-col gap-3 w-full max-w-sm"
    aria-live="polite"
    aria-atomic="false"
  >
    <TransitionGroup
      enter-active-class="transition-all duration-300 ease-out"
      enter-from-class="translate-x-full opacity-0"
      enter-to-class="translate-x-0 opacity-100"
      leave-active-class="transition-all duration-200 ease-in"
      leave-from-class="translate-x-0 opacity-100"
      leave-to-class="translate-x-full opacity-0"
    >
      <div
        v-for="toast in uiStore.toasts"
        :key="toast.id"
        :class="[typeClasses[toast.type], 'rounded-lg border-l-4 p-4 shadow-lg']"
        role="alert"
      >
        <div class="flex items-start gap-3">
          <svg
            class="h-5 w-5 shrink-0 mt-0.5"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              :d="iconPaths[toast.type]"
            />
          </svg>
          <p class="flex-1 text-sm font-medium">{{ toast.message }}</p>
          <button
            class="shrink-0 rounded p-1 opacity-70 hover:opacity-100 transition-opacity"
            :aria-label="`Dismiss ${toast.type} notification`"
            @click="uiStore.removeToast(toast.id)"
          >
            <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>
      </div>
    </TransitionGroup>
  </div>
</template>
