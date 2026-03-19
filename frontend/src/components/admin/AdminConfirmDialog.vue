<script setup lang="ts">
import { ref, watch, nextTick, onUnmounted } from 'vue'

const props = defineProps<{
  open: boolean
  title?: string
  message?: string
  confirmLabel?: string
  loading?: boolean
}>()

const emit = defineEmits<{
  confirm: []
  cancel: []
}>()

const cancelBtnRef = ref<HTMLButtonElement | null>(null)
const dialogRef = ref<HTMLDivElement | null>(null)

// Focus the cancel button when dialog opens
watch(
  () => props.open,
  async (isOpen) => {
    if (isOpen) {
      await nextTick()
      cancelBtnRef.value?.focus()
      document.addEventListener('keydown', handleKeydown)
    } else {
      document.removeEventListener('keydown', handleKeydown)
    }
  },
)

onUnmounted(() => {
  document.removeEventListener('keydown', handleKeydown)
})

function handleKeydown(e: KeyboardEvent) {
  if (e.key === 'Escape') {
    emit('cancel')
    return
  }

  // Focus trap — keep Tab within the dialog
  if (e.key === 'Tab' && dialogRef.value) {
    const focusable = dialogRef.value.querySelectorAll<HTMLElement>(
      'button:not([disabled]), [tabindex]:not([tabindex="-1"])',
    )
    if (focusable.length === 0) return

    const first = focusable[0] as HTMLElement | undefined
    const last = focusable[focusable.length - 1] as HTMLElement | undefined
    if (!first || !last) return

    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault()
      last.focus()
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault()
      first.focus()
    }
  }
}
</script>

<template>
  <Teleport to="body">
    <Transition name="fade">
      <div
        v-if="open"
        class="dialog-overlay"
        role="dialog"
        aria-modal="true"
        :aria-label="title || 'confirm'"
        @click.self="emit('cancel')"
      >
        <div ref="dialogRef" class="dialog-card">
          <div class="card-header">
            <div class="dots">
              <span class="dot dot-red" />
              <span class="dot dot-yellow" />
              <span class="dot dot-green" />
            </div>
            <span class="header-title">{{ title || 'confirm' }}</span>
          </div>
          <div class="card-body">
            <p class="dialog-message">{{ message || 'Are you sure?' }}</p>
            <div class="dialog-actions">
              <button ref="cancelBtnRef" class="btn-cancel" @click="emit('cancel')">
                <span class="btn-prompt">$</span> cancel
              </button>
              <button class="btn-confirm" :disabled="loading" @click="emit('confirm')">
                <span v-if="loading">processing...</span>
                <span v-else><span class="btn-prompt">$</span> {{ confirmLabel || 'confirm' }}</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.dialog-overlay {
  position: fixed;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0, 0, 0, 0.45);
  z-index: 100;
  padding: 1rem;
}

.dialog-card {
  width: 100%;
  max-width: 380px;
  border-radius: 14px;
  overflow: hidden;
  background: #ffffff;
  border: 1px solid #e7e5e4;
  box-shadow:
    0 4px 24px rgba(0, 0, 0, 0.1),
    0 12px 48px rgba(0, 0, 0, 0.06);
}

:is(.dark *).dialog-card {
  background: #1c1917;
  border-color: rgba(var(--skin-light-rgb), 0.1);
  box-shadow:
    0 4px 24px rgba(0, 0, 0, 0.25),
    0 12px 48px rgba(0, 0, 0, 0.2);
}

.card-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  background: #f5f5f4;
  border-bottom: 1px solid #e7e5e4;
}

:is(.dark *).card-header {
  background: rgba(var(--skin-light-rgb), 0.03);
  border-color: rgba(var(--skin-light-rgb), 0.06);
}

.dots {
  display: flex;
  gap: 6px;
}

.dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

.dot-red {
  background: #ef4444;
}
.dot-yellow {
  background: #eab308;
}
.dot-green {
  background: #22c55e;
}

.header-title {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem;
  color: #78716c;
  font-weight: 500;
}

:is(.dark *).header-title {
  color: #a8a29e;
}

.card-body {
  padding: 1.25rem;
}

.dialog-message {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.82rem;
  color: #44403c;
  line-height: 1.6;
  margin-bottom: 1.25rem;
}

:is(.dark *).dialog-message {
  color: #d6d3d1;
}

.dialog-actions {
  display: flex;
  gap: 0.75rem;
  justify-content: flex-end;
}

.btn-cancel,
.btn-confirm {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  font-weight: 600;
  padding: 0.5rem 1rem;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-cancel {
  color: #78716c;
  background: none;
  border: 1.5px solid #e7e5e4;
}

.btn-cancel:hover {
  background: #f5f5f4;
}

:is(.dark *).btn-cancel {
  color: #a8a29e;
  border-color: rgba(var(--skin-light-rgb), 0.12);
}

:is(.dark *).btn-cancel:hover {
  background: rgba(var(--skin-light-rgb), 0.06);
}

.btn-confirm {
  color: white;
  background: #ef4444;
  border: none;
}

.btn-confirm:hover:not(:disabled) {
  background: #dc2626;
}

.btn-confirm:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-prompt {
  opacity: 0.5;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
