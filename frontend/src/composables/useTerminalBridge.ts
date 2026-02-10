import { ref } from 'vue'

/* ============================================================================
   Terminal Bridge
   ============================================================================
   Allows external components (navbar, footer, hero CTAs) to trigger
   autoType / clearAutoType / runCommand on the floating terminal without
   direct parent-child coupling.

   The FloatingTerminal registers its functions on mount; callers invoke
   them via trigger*. If no terminal is registered, calls are safe no-ops.
   ============================================================================ */

const autoTypeFn = ref<((text: string) => void) | null>(null)
const clearAutoTypeFn = ref<(() => void) | null>(null)
const runCommandFn = ref<((cmd: string) => void) | null>(null)
const isRegistered = ref(false)

export function useTerminalBridge() {
  function register(
    autoType: (text: string) => void,
    clearAutoType: () => void,
    runCommand: (cmd: string) => void
  ) {
    autoTypeFn.value = autoType
    clearAutoTypeFn.value = clearAutoType
    runCommandFn.value = runCommand
    isRegistered.value = true
  }

  function unregister() {
    autoTypeFn.value = null
    clearAutoTypeFn.value = null
    runCommandFn.value = null
    isRegistered.value = false
  }

  function triggerAutoType(text: string) {
    autoTypeFn.value?.(text)
  }

  function triggerClearAutoType() {
    clearAutoTypeFn.value?.()
  }

  function triggerRunCommand(cmd: string) {
    runCommandFn.value?.(cmd)
  }

  return {
    register,
    unregister,
    triggerAutoType,
    triggerClearAutoType,
    triggerRunCommand,
    isRegistered,
  }
}
