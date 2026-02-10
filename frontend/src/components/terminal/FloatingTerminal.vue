<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useWindowScroll } from '@vueuse/core'
import { useScrollTo, NAV_ITEMS, type NavItem } from '@/composables/useScrollTo'
import { useAppearance, SKINS, BACKGROUNDS, SKIN_IDS, BG_IDS } from '@/composables/useAppearance'
import type { SkinId, BgId } from '@/composables/useAppearance'
import { useTerminalBridge } from '@/composables/useTerminalBridge'

const route = useRoute()
const { navigateTo } = useScrollTo()
const { skin, background, setSkin, setBackground } = useAppearance()
const { register, unregister } = useTerminalBridge()

/* ========================================================================
   Dock state — terminal starts overlaying hero slot, drag undocks it
   ======================================================================== */

const isDocked = ref(true)
const isMinimized = ref(false)
const isDragging = ref(false)

// Page-coordinate position (relative to #app which has position: relative)
const pagePos = ref({ x: 0, y: 0 })
const lockedWidth = ref(0)
const slotFound = ref(false)

const isOnHomePage = computed(() => route.path === '/')
const { y: scrollY } = useWindowScroll()

// Mirror the navbar's glass logic (AppHeader: showGlass = !isHome || scrollY > 100).
// When glass is active the terminal drops behind the navbar so it blurs through;
// when the navbar is fully transparent the terminal renders on top.
const navbarHasGlass = computed(() => !isOnHomePage.value || scrollY.value > 100)

// Terminal is visible when:
// - Docked on home page AND the slot was found, OR
// - Undocked (on any page)
const isVisible = computed(() => {
  if (isMinimized.value) return false
  if (isDocked.value) return slotFound.value && isOnHomePage.value
  return true
})

const terminalZIndex = computed(() => {
  if (isDragging.value) return 1070
  return navbarHasGlass.value ? 1010 : 1060
})

const terminalStyle = computed(() => ({
  position: 'absolute' as const,
  left: `${pagePos.value.x}px`,
  top: `${pagePos.value.y}px`,
  width: lockedWidth.value > 0 ? `${lockedWidth.value}px` : '380px',
  zIndex: terminalZIndex.value,
}))

/* ========================================================================
   Slot measurement — positions terminal over #hero-terminal-slot
   ======================================================================== */

function measureSlot(): boolean {
  const slot = document.getElementById('hero-terminal-slot')
  if (!slot || slot.offsetParent === null) return false
  const rect = slot.getBoundingClientRect()
  pagePos.value = {
    x: rect.left + window.scrollX,
    y: rect.top + window.scrollY,
  }
  if (lockedWidth.value === 0) {
    lockedWidth.value = rect.width
  }
  slotFound.value = true
  return true
}

function onResize() {
  if (isDocked.value && isOnHomePage.value) {
    measureSlot()
  }
}

/* ========================================================================
   Reveal animation — plays once on first load
   ======================================================================== */

const entered = ref(false)

/* ========================================================================
   Terminal state
   ======================================================================== */

interface HistoryEntry {
  command: string
  response: string
  isError?: boolean
}

const history = ref<HistoryEntry[]>([])
const inputValue = ref('')
const terminalReady = ref(false)
const isAutoTyping = ref(false)
const terminalBodyRef = ref<HTMLElement | null>(null)
const inputRef = ref<HTMLInputElement | null>(null)

/* ========================================================================
   Simple commands
   ======================================================================== */

const COMMANDS: Record<string, { response: string; nav?: NavItem }> = {
  help: {
    response: 'commands: home, projects, experience, blog, contact, about, skin, bg, clear',
  },
  home: {
    response: 'navigating home...',
    nav: NAV_ITEMS.find((n) => n.href === '/'),
  },
  projects: {
    response: 'loading projects...',
    nav: NAV_ITEMS.find((n) => n.href === '/#projects'),
  },
  experience: {
    response: 'loading experience...',
    nav: NAV_ITEMS.find((n) => n.href === '/#experience'),
  },
  blog: {
    response: 'opening blog...',
    nav: NAV_ITEMS.find((n) => n.href === '/blog'),
  },
  contact: {
    response: 'opening contact...',
    nav: NAV_ITEMS.find((n) => n.href === '/#contact'),
  },
  about: {
    response: 'scrolling to about...',
    nav: { label: 'About', href: '/#about', isRoute: false },
  },
  github: {
    response: 'opening github...',
  },
  linkedin: {
    response: 'opening linkedin...',
  },
  email: {
    response: 'composing email...',
  },
  clear: {
    response: '',
  },
}

const LINK_ACTIONS: Record<string, string> = {
  github: 'https://github.com/justin-negron',
  linkedin: 'https://www.linkedin.com/in/justin-negron/',
  email: 'mailto:justinnegron174@gmail.com',
}

function scrollTerminal() {
  nextTick(() => {
    if (terminalBodyRef.value) {
      terminalBodyRef.value.scrollTop = terminalBodyRef.value.scrollHeight
    }
  })
}

/* ========================================================================
   Command execution
   ======================================================================== */

function executeCommand(cmd: string) {
  const trimmed = cmd.trim().toLowerCase()
  if (!trimmed) return

  if (trimmed === 'clear') {
    history.value = []
    return
  }

  const parts = trimmed.split(/\s+/)
  const base = parts[0]!
  const arg = parts.slice(1).join(' ')

  if (base === 'skin') {
    handleSkinCommand(trimmed, arg)
    return
  }

  if (base === 'bg') {
    handleBgCommand(trimmed, arg)
    return
  }

  const match = COMMANDS[trimmed]
  if (match) {
    history.value.push({ command: trimmed, response: match.response })
    scrollTerminal()
    if (match.nav) {
      setTimeout(() => navigateTo(match.nav as NavItem), 400)
    }
    if (LINK_ACTIONS[trimmed]) {
      setTimeout(() => {
        window.open(LINK_ACTIONS[trimmed], '_blank', 'noopener,noreferrer')
      }, 400)
    }
    return
  }

  history.value.push({
    command: trimmed,
    response: `command not found: ${trimmed}. type "help" for commands.`,
    isError: true,
  })
  scrollTerminal()
}

function handleSkinCommand(full: string, arg: string) {
  if (!arg) {
    history.value.push({
      command: full,
      response: `current: ${skin.value}. usage: skin <name> | skin list`,
    })
    scrollTerminal()
    return
  }

  if (arg === 'list') {
    history.value.push({
      command: full,
      response: `available: ${SKIN_IDS.join(', ')}`,
    })
    scrollTerminal()
    return
  }

  if (SKINS[arg as SkinId]) {
    setSkin(arg as SkinId)
    history.value.push({ command: full, response: `skin set to ${arg}` })
  } else {
    history.value.push({
      command: full,
      response: `unknown skin: ${arg}. try: ${SKIN_IDS.join(', ')}`,
      isError: true,
    })
  }
  scrollTerminal()
}

function handleBgCommand(full: string, arg: string) {
  if (!arg) {
    history.value.push({
      command: full,
      response: `current: ${background.value}. usage: bg <name> | bg list`,
    })
    scrollTerminal()
    return
  }

  if (arg === 'list') {
    history.value.push({
      command: full,
      response: `available: ${BG_IDS.join(', ')}`,
    })
    scrollTerminal()
    return
  }

  if (BACKGROUNDS[arg as BgId]) {
    setBackground(arg as BgId)
    history.value.push({ command: full, response: `background set to ${arg}` })
  } else {
    history.value.push({
      command: full,
      response: `unknown background: ${arg}. try: ${BG_IDS.join(', ')}`,
      isError: true,
    })
  }
  scrollTerminal()
}

function handleSubmit() {
  if (isAutoTyping.value) return
  executeCommand(inputValue.value)
  inputValue.value = ''
}

function runCommand(cmd: string) {
  executeCommand(cmd)
  inputValue.value = ''
}

function focusTerminal() {
  inputRef.value?.focus()
}

/* ========================================================================
   Auto-type (hover-to-type from navbar/footer/CTAs)
   ======================================================================== */

let autoTypeTimeout: ReturnType<typeof setTimeout>

function autoType(text: string) {
  clearTimeout(autoTypeTimeout)
  isAutoTyping.value = true
  inputValue.value = ''

  let i = 0
  function tick() {
    inputValue.value = text.slice(0, i + 1)
    i++
    scrollTerminal()
    if (i < text.length) {
      autoTypeTimeout = setTimeout(tick, 35)
    } else {
      isAutoTyping.value = false
    }
  }
  autoTypeTimeout = setTimeout(tick, 80)
}

function clearAutoType() {
  clearTimeout(autoTypeTimeout)
  isAutoTyping.value = false
  inputValue.value = ''
}

const terminalHint = computed(() => {
  if (history.value.length === 0 && !inputValue.value) {
    return 'type "help" for commands'
  }
  return ''
})

/* ========================================================================
   Boot sequence
   ======================================================================== */

const bootLines = ref<{ text: string; type: 'cmd' | 'res' }[]>([])
const bootDone = ref(false)
let bootHasRun = false

async function runBoot() {
  if (bootHasRun) return
  bootHasRun = true

  const sequence: { cmd: string; res: string; delay: number }[] = [
    { cmd: 'status', res: 'available for work', delay: 300 },
    { cmd: 'location', res: 'remote / anywhere', delay: 250 },
  ]

  await new Promise((r) => setTimeout(r, 800))

  for (const step of sequence) {
    bootLines.value.push({ text: `$ ${step.cmd}`, type: 'cmd' })
    scrollTerminal()
    await new Promise((r) => setTimeout(r, step.delay))
    bootLines.value.push({ text: step.res, type: 'res' })
    scrollTerminal()
    await new Promise((r) => setTimeout(r, 200))
  }

  bootDone.value = true
  terminalReady.value = true
  await nextTick()
  inputRef.value?.focus()
}

/* ========================================================================
   Dragging — undocks on first drag, uses page coordinates
   ======================================================================== */

const terminalWrapRef = ref<HTMLElement | null>(null)

// Grab offset: distance from mouse pointer to terminal's top-left corner (viewport coords).
// Stored once at drag start, then used to recompute pagePos on every mousemove AND scroll.
let grabOffset = { x: 0, y: 0 }
let lastClient = { x: 0, y: 0 }

function undock() {
  if (!isDocked.value) return
  isDocked.value = false
}

/** Convert current viewport mouse position → page position for the terminal */
function updateDragPos() {
  pagePos.value = {
    x: Math.max(0, lastClient.x - grabOffset.x + window.scrollX),
    y: Math.max(0, lastClient.y - grabOffset.y + window.scrollY),
  }
}

function onDragStart(e: MouseEvent) {
  e.preventDefault()

  // First drag undocks
  if (isDocked.value) {
    measureSlot()
    undock()
  }

  isDragging.value = true
  lastClient = { x: e.clientX, y: e.clientY }
  // How far the mouse is from the terminal's top-left in viewport coords
  grabOffset = {
    x: e.clientX - (pagePos.value.x - window.scrollX),
    y: e.clientY - (pagePos.value.y - window.scrollY),
  }
  document.addEventListener('mousemove', onDragMove)
  document.addEventListener('mouseup', onDragEnd)
  window.addEventListener('scroll', onDragScroll, true)
}

function onDragMove(e: MouseEvent) {
  if (!isDragging.value) return
  lastClient = { x: e.clientX, y: e.clientY }
  updateDragPos()
}

function onDragScroll() {
  if (!isDragging.value) return
  updateDragPos()
}

function onDragEnd() {
  isDragging.value = false
  document.removeEventListener('mousemove', onDragMove)
  document.removeEventListener('mouseup', onDragEnd)
  window.removeEventListener('scroll', onDragScroll, true)
}

function onTouchStart(e: TouchEvent) {
  const touch = e.touches[0]
  if (!touch) return

  if (isDocked.value) {
    measureSlot()
    undock()
  }

  isDragging.value = true
  lastClient = { x: touch.clientX, y: touch.clientY }
  grabOffset = {
    x: touch.clientX - (pagePos.value.x - window.scrollX),
    y: touch.clientY - (pagePos.value.y - window.scrollY),
  }
  document.addEventListener('touchmove', onTouchMove, { passive: false })
  document.addEventListener('touchend', onTouchEnd)
  window.addEventListener('scroll', onDragScroll, true)
}

function onTouchMove(e: TouchEvent) {
  if (!isDragging.value) return
  const touch = e.touches[0]
  if (!touch) return
  e.preventDefault()
  lastClient = { x: touch.clientX, y: touch.clientY }
  updateDragPos()
}

function onTouchEnd() {
  isDragging.value = false
  document.removeEventListener('touchmove', onTouchMove)
  document.removeEventListener('touchend', onTouchEnd)
  window.removeEventListener('scroll', onDragScroll, true)
}

/* ========================================================================
   Minimize / Expand
   ======================================================================== */

function minimize() {
  if (isDocked.value) {
    measureSlot()
    undock()
  }
  isMinimized.value = true
}

function expand() {
  isMinimized.value = false
  nextTick(() => focusTerminal())
}

/* ========================================================================
   Lifecycle
   ======================================================================== */

onMounted(() => {
  register(autoType, clearAutoType, runCommand)

  // HomeView is lazy-loaded, so #hero-terminal-slot may not exist yet.
  // Poll with rAF until the slot appears (typically 1-3 frames).
  let attempts = 0
  function pollForSlot() {
    if (measureSlot()) {
      requestAnimationFrame(() => {
        entered.value = true
      })
      return
    }
    attempts++
    if (attempts < 120) {
      requestAnimationFrame(pollForSlot)
    }
  }
  pollForSlot()

  runBoot()
  window.addEventListener('resize', onResize)
})

onUnmounted(() => {
  clearTimeout(autoTypeTimeout)
  document.removeEventListener('mousemove', onDragMove)
  document.removeEventListener('mouseup', onDragEnd)
  document.removeEventListener('touchmove', onTouchMove)
  document.removeEventListener('touchend', onTouchEnd)
  window.removeEventListener('scroll', onDragScroll, true)
  window.removeEventListener('resize', onResize)
  unregister()
})

// When navigating away from home while docked, auto-undock with a default position
watch(isOnHomePage, async (onHome) => {
  if (!onHome && isDocked.value) {
    // Capture current position before undocking
    measureSlot()
    undock()
  }
  if (onHome && isDocked.value) {
    // Re-measure slot when navigating back to home
    await nextTick()
    measureSlot()
  }
})
</script>

<template>
  <!-- Minimize pill -->
  <button v-if="isMinimized" class="terminal-pill" aria-label="Expand terminal" @click="expand">
    <span class="font-mono text-xs">&gt;_</span>
  </button>

  <!-- Terminal — always in App.vue DOM, absolutely positioned over hero slot when docked -->
  <div
    v-show="isVisible"
    ref="terminalWrapRef"
    :class="['terminal-wrap', isDragging ? 'is-dragging' : '']"
    :style="terminalStyle"
  >
    <div
      :class="['terminal-card', entered ? 'reveal reveal-terminal is-revealed' : 'reveal']"
      @click="focusTerminal"
    >
      <!-- Title bar (drag handle — hidden feature) -->
      <div class="terminal-bar" @mousedown="onDragStart" @touchstart.passive="onTouchStart">
        <div class="flex items-center gap-1.5">
          <span class="dot dot-red" />
          <button class="dot dot-yellow" title="Minimize" @click.stop="minimize()" />
          <span class="dot dot-green" />
        </div>
        <span class="terminal-title">terminal</span>
      </div>

      <!-- Terminal body -->
      <div ref="terminalBodyRef" class="terminal-body font-mono text-xs leading-loose md:text-sm">
        <!-- Boot sequence -->
        <div v-for="(line, i) in bootLines" :key="`boot-${i}`">
          <span v-if="line.type === 'cmd'" class="boot-cmd">{{ line.text }}</span>
          <span v-else class="boot-res">{{ line.text }}</span>
        </div>

        <!-- Divider after boot -->
        <div v-if="bootDone && history.length > 0" class="terminal-divider" />

        <!-- Command history -->
        <div v-for="(entry, i) in history" :key="`hist-${i}`">
          <div class="flex gap-2">
            <span class="select-none prompt-char">$</span>
            <span class="cmd-text">{{ entry.command }}</span>
          </div>
          <div
            v-if="entry.response"
            :class="['ml-4 mb-1', entry.isError ? 'cmd-error' : 'cmd-response']"
          >
            {{ entry.response }}
          </div>
        </div>

        <!-- Input line -->
        <div v-if="terminalReady" class="input-line flex items-center gap-2">
          <span class="select-none prompt-char">$</span>
          <div class="relative flex-1">
            <input
              ref="inputRef"
              v-model="inputValue"
              type="text"
              class="terminal-input"
              autocomplete="off"
              autocorrect="off"
              autocapitalize="off"
              spellcheck="false"
              @keydown.enter="handleSubmit"
            />
            <span v-if="terminalHint && !inputValue" class="terminal-placeholder">
              {{ terminalHint }}
            </span>
          </div>
        </div>

        <!-- Pre-ready cursor -->
        <div v-else class="flex items-center gap-2">
          <span class="select-none prompt-char">$</span>
          <span class="cursor-blink prompt-char">|</span>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* ===================================================================
   Terminal wrap — always absolutely positioned
   =================================================================== */
.terminal-wrap {
  will-change: left, top;
}

.terminal-wrap.is-dragging .terminal-card {
  box-shadow:
    0 0 60px rgba(0, 0, 0, 0.12),
    0 30px 60px rgba(0, 0, 0, 0.1);
  cursor: grabbing;
}

:is(.dark *).terminal-wrap.is-dragging .terminal-card {
  box-shadow:
    0 0 60px rgba(0, 0, 0, 0.3),
    0 30px 60px rgba(0, 0, 0, 0.25);
}

/* ===================================================================
   Terminal card
   =================================================================== */
.terminal-card {
  background: #faf9f7;
  border: 1px solid #e7e5e4;
  border-radius: 16px;
  overflow: hidden;
  box-shadow:
    0 0 40px rgba(0, 0, 0, 0.06),
    0 20px 40px rgba(0, 0, 0, 0.04);
  cursor: text;
  transition:
    background 0.3s ease,
    border-color 0.3s ease,
    box-shadow 0.25s ease;
}

:is(.dark *).terminal-card {
  background: #141211;
  border-color: rgba(var(--skin-light-rgb), 0.15);
  box-shadow:
    0 0 40px rgba(var(--skin-light-rgb), 0.03),
    0 20px 40px rgba(0, 0, 0, 0.3);
}

/* ===================================================================
   Reveal animation (plays once on first load)
   =================================================================== */
.reveal {
  opacity: 0;
  will-change: opacity, filter, transform;
}

.reveal-terminal.is-revealed {
  animation: terminalReveal 1.5s cubic-bezier(0.16, 1, 0.3, 1) 2s forwards;
}

@keyframes terminalReveal {
  0% {
    opacity: 0;
    filter: blur(8px);
    transform: translateY(24px) scale(0.97);
  }
  100% {
    opacity: 1;
    filter: blur(0px);
    transform: translateY(0) scale(1);
  }
}

/* ===================================================================
   Terminal bar (drag handle)
   =================================================================== */
.terminal-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 14px;
  background: rgba(0, 0, 0, 0.02);
  border-bottom: 1px solid #e7e5e4;
  cursor: grab;
  user-select: none;
  transition:
    background 0.3s ease,
    border-color 0.3s ease;
}

:is(.dark *).terminal-bar {
  background: rgba(var(--skin-light-rgb), 0.03);
  border-bottom-color: rgba(var(--skin-light-rgb), 0.06);
}

.terminal-bar:active {
  cursor: grabbing;
}

/* Window dots */
.dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  padding: 0;
  border: none;
  cursor: default;
}

.dot-yellow {
  background: #e2a93b;
  cursor: pointer;
  transition: filter 0.15s ease;
}

.dot-yellow:hover {
  filter: brightness(1.2);
}

.dot-red {
  background: #e85d4a;
}

.dot-green {
  background: #5db85e;
}

.terminal-title {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.65rem;
  color: #a8a29e;
  transition: color 0.3s ease;
}

:is(.dark *).terminal-title {
  color: rgba(var(--skin-light-rgb), 0.3);
}

/* ===================================================================
   Terminal body
   =================================================================== */
.terminal-body {
  padding: 1rem 1.25rem;
  max-height: 280px;
  overflow-y: auto;
  scrollbar-width: thin;
  scrollbar-color: rgba(0, 0, 0, 0.1) transparent;
}

:is(.dark *).terminal-body {
  scrollbar-color: rgba(var(--skin-light-rgb), 0.15) transparent;
}

.terminal-body::-webkit-scrollbar {
  width: 4px;
}
.terminal-body::-webkit-scrollbar-thumb {
  background: rgba(0, 0, 0, 0.1);
  border-radius: 4px;
}

:is(.dark *).terminal-body::-webkit-scrollbar-thumb {
  background: rgba(var(--skin-light-rgb), 0.15);
}

/* ===================================================================
   Terminal text colors — light mode
   =================================================================== */
.boot-cmd {
  color: #78716c;
}
.boot-res {
  margin-left: 1rem;
  color: #059669;
}
.prompt-char {
  color: var(--skin-700);
}
.cmd-text {
  color: #57534e;
}
.cmd-response {
  color: #78716c;
}
.cmd-error {
  color: #dc2626;
}

/* ===================================================================
   Terminal text colors — dark mode
   =================================================================== */
:is(.dark *).boot-cmd {
  color: #78716c;
}

:is(.dark *).boot-res {
  color: #10b981;
}

:is(.dark *).prompt-char {
  color: var(--skin-600);
}

:is(.dark *).cmd-text {
  color: #a8a29e;
}

:is(.dark *).cmd-response {
  color: #78716c;
}

:is(.dark *).cmd-error {
  color: #f87171;
}

.terminal-divider {
  margin: 0.5rem 0;
  border-top: 1px solid #e7e5e4;
}

:is(.dark *).terminal-divider {
  border-top-color: rgba(var(--skin-light-rgb), 0.08);
}

/* ===================================================================
   Input
   =================================================================== */
.terminal-input {
  width: 100%;
  background: transparent;
  border: none;
  outline: none;
  color: #1c1917;
  font-family: 'JetBrains Mono', monospace;
  font-size: inherit;
  line-height: inherit;
  padding: 0;
  caret-color: var(--skin-700);
  transition: color 0.3s ease;
}

:is(.dark *).terminal-input {
  color: #e7e5e4;
  caret-color: var(--skin-600);
}

.terminal-input:focus,
.terminal-input:focus-visible {
  outline: none;
  box-shadow: none;
}

.terminal-card:focus,
.terminal-card:focus-visible,
.terminal-card:focus-within {
  outline: none;
  box-shadow:
    0 0 40px rgba(0, 0, 0, 0.06),
    0 20px 40px rgba(0, 0, 0, 0.04);
}

:is(.dark *).terminal-card:focus,
:is(.dark *).terminal-card:focus-visible,
:is(.dark *).terminal-card:focus-within {
  outline: none;
  box-shadow:
    0 0 40px rgba(var(--skin-light-rgb), 0.03),
    0 20px 40px rgba(0, 0, 0, 0.3);
}

.terminal-placeholder {
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
  color: rgba(168, 162, 158, 0.4);
  font-family: 'JetBrains Mono', monospace;
  font-size: inherit;
  pointer-events: none;
}

:is(.dark *).terminal-placeholder {
  color: rgba(168, 162, 158, 0.35);
}

/* ===================================================================
   Cursor blink
   =================================================================== */
.cursor-blink {
  animation: blink 1s step-end infinite;
}
@keyframes blink {
  50% {
    opacity: 0;
  }
}

/* ===================================================================
   Minimize pill
   =================================================================== */
.terminal-pill {
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 1060;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 32px;
  border-radius: 999px;
  background: var(--skin-600);
  color: white;
  border: none;
  box-shadow: 0 4px 12px rgba(var(--skin-rgb), 0.3);
  cursor: pointer;
  transition:
    transform 0.2s ease,
    box-shadow 0.2s ease;
}

.terminal-pill:hover {
  transform: scale(1.1);
  box-shadow: 0 6px 20px rgba(var(--skin-rgb), 0.4);
}

:is(.dark *).terminal-pill {
  background: var(--skin-500);
  box-shadow: 0 4px 12px rgba(var(--skin-light-rgb), 0.3);
}

:is(.dark *).terminal-pill:hover {
  box-shadow: 0 6px 20px rgba(var(--skin-light-rgb), 0.4);
}
</style>
