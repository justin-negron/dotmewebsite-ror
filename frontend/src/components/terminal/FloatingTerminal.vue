<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useWindowScroll, useWindowSize } from '@vueuse/core'
import { useScrollTo, NAV_ITEMS, type NavItem } from '@/composables/useScrollTo'
import { useAppearance, SKINS, BACKGROUNDS, SKIN_IDS, BG_IDS } from '@/composables/useAppearance'
import type { SkinId, BgId } from '@/composables/useAppearance'
import { useTerminalBridge } from '@/composables/useTerminalBridge'

const route = useRoute()
const router = useRouter()
const { navigateTo } = useScrollTo()
const { skin, background, setSkin, setBackground } = useAppearance()
const { register, unregister } = useTerminalBridge()

/* ========================================================================
   Dock state — terminal starts overlaying hero slot, drag undocks it
   ======================================================================== */

const isDocked = ref(true)
const isMinimized = ref(false)
const isDragging = ref(false)
const isTransitioning = ref(false)

// Page-coordinate position (relative to #app which has position: relative)
const pagePos = ref({ x: 0, y: 0 })
const lockedWidth = ref(0)
const slotFound = ref(false)

const isOnHomePage = computed(() => route.path === '/')
const isBlogPage = computed(() => route.path.startsWith('/blog'))
const { y: scrollY } = useWindowScroll()
const { width: viewportWidth, height: viewportHeight } = useWindowSize()

// Mirror the navbar's glass logic (AppHeader: showGlass = !isHome || scrollY > 100).
const navbarHasGlass = computed(() => !isOnHomePage.value || scrollY.value > 100)

// Terminal is visible when docked+slot-found on home, or undocked anywhere.
// During a page transition (navTransitioning) the docked terminal stays visible
// even when leaving the home page, so it can slide to its new position instead
// of disappearing and reappearing.
const isVisible = computed(() => {
  if (isMinimized.value) return false
  if (isDocked.value) {
    if (navTransitioning.value) return slotFound.value
    return slotFound.value && isOnHomePage.value
  }
  return true
})

// Mobile (< 640px): show bottom-right pill when minimized.
const showMobilePill = computed(() => viewportWidth.value < 640 && isMinimized.value)
// Desktop: show bottom-right pill when minimized.
const showDesktopPill = computed(() => viewportWidth.value >= 640 && isMinimized.value)

// Always below the navbar (z-index 1020).
const terminalZIndex = computed(() => (isDragging.value ? 1015 : 1010))

// Mobile open: terminal is a freely draggable fixed panel.
const isMobileOpen = computed(
  () => viewportWidth.value < 640 && !isMinimized.value && !isDocked.value,
)

/* Mobile panel dimensions — shared across style + touch handlers.
   Height is capped at 360px / 42% viewport so the input at the bottom
   stays above the soft keyboard (which consumes ~280-340px on most phones). */
function getMobileDims() {
  const w = Math.min(360, Math.round(viewportWidth.value * 0.9))
  const h = Math.min(360, Math.round(viewportHeight.value * 0.42))
  return { w, h }
}

/* Default opening position: centered horizontally, upper portion of screen
   (top ~10% of viewport, min 80px to clear the navbar).
   Positioning in the top half keeps the terminal visible when the soft
   keyboard opens — the keyboard pushes up from the bottom. */
function getDefaultMobilePos() {
  const { w } = getMobileDims()
  return {
    x: Math.round((viewportWidth.value - w) / 2),
    y: Math.max(80, Math.round(viewportHeight.value * 0.1)),
  }
}

const terminalStyle = computed(() => {
  if (isMobileOpen.value) {
    const { w, h } = getMobileDims()
    return {
      position: 'fixed' as const,
      left: `${mobilePanelPos.value.x}px`,
      top: `${mobilePanelPos.value.y}px`,
      width: `${w}px`,
      height: `${h}px`,
      zIndex: 1011,
    }
  }

  const maxW = Math.max(280, viewportWidth.value - 48) // 24px gap each side
  const w = Math.min(lockedWidth.value > 0 ? lockedWidth.value : 380, maxW)
  return {
    position: 'absolute' as const,
    left: `${pagePos.value.x}px`,
    top: `${pagePos.value.y}px`,
    width: `${w}px`,
    zIndex: terminalZIndex.value,
  }
})

// Mobile minimized pill — draggable up/down along the right edge.
const mobilePillStyle = computed(() => {
  const PILL_H = 48
  const clampedY = Math.max(60, Math.min(viewportHeight.value - PILL_H - 16, mobilePillY.value))
  return {
    top: `${clampedY}px`,
    right: '0px',
    transition: isDraggingMobilePill.value ? 'none' : 'top 0.35s cubic-bezier(0.16, 1, 0.3, 1)',
  }
})

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
// Once the entry animation completes, lock in opacity: 1 so v-show cycling
// (display:none → block) never replays the 2-second delay.
const revealDone = ref(false)
// Briefly true after expand() — drives the expand fade-in animation.
const isExpanding = ref(false)
// Briefly true during minimize() — drives the fade-out animation before hiding.
const isMinimizing = ref(false)
let minimizeTimer: ReturnType<typeof setTimeout> | null = null

// Mobile minimized pill — Y from top of viewport (set in onMounted)
const mobilePillY = ref(0)
const isDraggingMobilePill = ref(false)

// Mobile open panel — viewport-coordinate position (position: fixed)
const mobilePanelPos = ref({ x: 0, y: 0 })

// Track whether terminal was docked before minimizing, so expand() can re-dock
// when appropriate (home page, hero visible) instead of scrolling there.
const wasDocked = ref(false)

// True between router.beforeEach and the next tick after router.afterEach.
// isVisible uses this to keep a docked terminal visible during the one-tick
// gap when isOnHomePage is already false but the watcher hasn't undocked yet.
const navTransitioning = ref(false)

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

// Command history — up/down arrow navigation
const cmdHistory = ref<string[]>([])
const historyIndex = ref(-1)
const savedInput = ref('')

/* ========================================================================
   Simple commands
   ======================================================================== */

const COMMANDS: Record<string, { response: string; nav?: NavItem }> = {
  help: {
    response: 'commands: home, projects, experience, blog, contact, about, skin, bg, clear, exit',
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
    nav: NAV_ITEMS.find((n) => n.href === '/#about'),
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

  if (trimmed === 'exit') {
    history.value.push({ command: 'exit', response: 'session closed. tap >_ to reconnect.' })
    scrollTerminal()
    setTimeout(() => minimize(), 600)
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
      setTimeout(() => {
        navigateTo(match.nav as NavItem)
        followNavigation(match.nav as NavItem)
      }, 400)
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

/* ========================================================================
   Follow navigation — move terminal to the target section
   ======================================================================== */

function followNavigation(nav: NavItem) {
  const termWidth = lockedWidth.value || 380

  // "home" command: re-dock to hero slot
  if (nav.href === '/') {
    // If already on home and docked, slot polling is handled by the route watcher.
    // If on home and undocked, animate back to hero slot.
    if (isOnHomePage.value && !isDocked.value && !isMinimized.value) {
      nextTick(() => {
        let attempts = 0
        function pollAndDock() {
          const slot = document.getElementById('hero-terminal-slot')
          if (slot && slot.offsetParent !== null) {
            const rect = slot.getBoundingClientRect()
            isTransitioning.value = true
            pagePos.value = {
              x: rect.left + window.scrollX,
              y: rect.top + window.scrollY,
            }
            setTimeout(() => {
              isDocked.value = true
              slotFound.value = true
              isTransitioning.value = false
            }, 500)
            return
          }
          attempts++
          if (attempts < 60) requestAnimationFrame(pollAndDock)
        }
        pollAndDock()
      })
    }
    // If navigating from another page, the route watcher handles re-docking
    return
  }

  // Route-based pages (like /blog): undock and animate to top-right
  if (nav.isRoute) {
    if (isDocked.value) {
      measureSlot()
      undock()
    }
    // Wait for route change to settle, then position at top-right of viewport.
    // Pass scrollY=0: destination resets scroll to top but window.scrollY still
    // holds the home page's offset when this fires.
    nextTick(() => {
      setTimeout(() => {
        isTransitioning.value = true
        pagePos.value = getTopRightPos(0)
        setTimeout(() => {
          isTransitioning.value = false
        }, 500)
      }, 300)
    })
    return
  }

  // Hash sections on home page (/#projects, /#experience, /#contact, /#about)
  const hash = nav.href.includes('#') ? nav.href.split('#')[1] : ''
  if (!hash) return

  // Undock if still docked
  if (isDocked.value) {
    measureSlot()
    undock()
  }

  // Wait for scroll to start, then find the section and position next to it
  nextTick(() => {
    // Small delay so smooth scroll has begun and section is in a predictable position
    setTimeout(() => {
      const section = document.getElementById(hash)
      if (!section) return

      const rect = section.getBoundingClientRect()
      isTransitioning.value = true
      pagePos.value = {
        x: Math.max(0, window.innerWidth - termWidth - 24),
        y: rect.top + window.scrollY + 20, // 20px below the section top
      }
      setTimeout(() => {
        isTransitioning.value = false
      }, 500)
    }, 300)
  })
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
  const cmd = inputValue.value.trim()
  if (cmd) {
    // Avoid consecutive duplicates (same as most shells)
    if (cmdHistory.value[cmdHistory.value.length - 1] !== cmd) {
      cmdHistory.value.push(cmd)
    }
  }
  historyIndex.value = -1
  savedInput.value = ''
  executeCommand(inputValue.value)
  inputValue.value = ''
}

function runCommand(cmd: string) {
  executeCommand(cmd)
  inputValue.value = ''
}

/* ========================================================================
   Tab autocomplete
   ======================================================================== */

const ALL_COMMANDS = [...Object.keys(COMMANDS), 'skin', 'bg', 'exit']

function handleTabComplete() {
  if (isAutoTyping.value) return
  const raw = inputValue.value
  const trimmed = raw.trimStart()
  const parts = trimmed.split(/\s+/)
  const base = parts[0]?.toLowerCase() ?? ''

  // Sub-argument completion: "skin am" → "skin amber", "bg geo" → "bg geometric-drift"
  if (parts.length >= 2 || (parts.length === 1 && raw.endsWith(' '))) {
    const sub = parts.length >= 2 ? parts.slice(1).join(' ').toLowerCase() : ''
    let subOptions: string[] = []
    if (base === 'skin') subOptions = [...SKIN_IDS, 'list']
    else if (base === 'bg') subOptions = [...BG_IDS, 'list']
    if (subOptions.length > 0) {
      const matches = subOptions.filter((o) => o.startsWith(sub))
      if (matches.length === 1) inputValue.value = `${base} ${matches[0]}`
    }
    return
  }

  // Base command completion: "bl" → "blog", ambiguous "b" → no-op
  if (!base) return
  const matches = ALL_COMMANDS.filter((cmd) => cmd.startsWith(base))
  if (matches.length === 1) inputValue.value = matches[0]!
}

/* ========================================================================
   Keyboard handler — Enter / ArrowUp / ArrowDown / Tab
   ======================================================================== */

function handleKeyDown(e: KeyboardEvent) {
  if (e.key === 'Enter') {
    handleSubmit()
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    if (cmdHistory.value.length === 0) return
    if (historyIndex.value === -1) savedInput.value = inputValue.value
    const next = Math.min(historyIndex.value + 1, cmdHistory.value.length - 1)
    historyIndex.value = next
    inputValue.value = cmdHistory.value[cmdHistory.value.length - 1 - next] ?? ''
  } else if (e.key === 'ArrowDown') {
    e.preventDefault()
    if (historyIndex.value === -1) return
    const next = historyIndex.value - 1
    historyIndex.value = next
    inputValue.value = next === -1 ? savedInput.value : (cmdHistory.value[cmdHistory.value.length - 1 - next] ?? '')
  } else if (e.key === 'Tab') {
    e.preventDefault()
    handleTabComplete()
  }
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

/** Top-right position with equal gap on both sides (right edge and navbar bottom).
 *  Pass scrollY=0 when navigating to a page that resets scroll (e.g. /blog),
 *  so the position isn't stale from the previous page's scroll offset. */
function getTopRightPos(scrollY = window.scrollY) {
  const GAP = 24
  const termWidth = Math.min(lockedWidth.value || 380, window.innerWidth - 2 * GAP)
  const navBottom = document.querySelector('header')?.getBoundingClientRect().bottom ?? 64
  return {
    x: Math.max(0, window.innerWidth - termWidth - GAP),
    y: scrollY + navBottom + GAP / 2,
  }
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

  // Mobile: terminal is a static panel — no drag to avoid buggy interactions.
  // Users close it by tapping the backdrop.
  if (viewportWidth.value < 640) return

  // Desktop: panel is position:absolute — track page coords
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
  const touch = e.touches[0]
  if (!touch) return
  e.preventDefault()
  if (!isDragging.value) return
  lastClient = { x: touch.clientX, y: touch.clientY }
  updateDragPos()
}

function onTouchEnd() {
  document.removeEventListener('touchmove', onTouchMove)
  document.removeEventListener('touchend', onTouchEnd)
  isDragging.value = false
  window.removeEventListener('scroll', onDragScroll, true)
}

/* ========================================================================
   Minimize / Expand
   ======================================================================== */

function minimize() {
  if (isMinimizing.value) return
  // Ensure re-expand is instant — no replay of the 2s entry animation delay.
  revealDone.value = true
  if (isDocked.value) {
    measureSlot()
    wasDocked.value = true
    undock()
  } else {
    wasDocked.value = false
  }
  isMinimizing.value = true
  minimizeTimer = setTimeout(() => {
    isMinimized.value = true
    isMinimizing.value = false
    minimizeTimer = null
  }, 150)
}

/** Called only when the terminal-card's own animation ends (not bubbled from children). */
function onTerminalCardAnimEnd(e: AnimationEvent) {
  if (e.animationName === 'terminalReveal') {
    revealDone.value = true
  }
}

function expand() {
  if (minimizeTimer !== null) {
    clearTimeout(minimizeTimer)
    minimizeTimer = null
    isMinimizing.value = false
  }
  isExpanding.value = true
  setTimeout(() => { isExpanding.value = false }, 200)
  isMinimized.value = false

  if (viewportWidth.value < 640) {
    // Mobile: always open as a fixed floating panel at the bottom of screen.
    isDocked.value = false
    wasDocked.value = false
    mobilePanelPos.value = getDefaultMobilePos()
    nextTick(() => focusTerminal())
    return
  }

  // Desktop: decide where to show based on context.
  if (wasDocked.value && isOnHomePage.value && scrollY.value < window.innerHeight * 0.5) {
    // Hero is visible on home page — re-dock to the slot.
    isDocked.value = true
    wasDocked.value = false
    nextTick(() => {
      measureSlot()
      focusTerminal()
    })
  } else {
    // Anywhere else (or scrolled past hero on home) — show at top-right, no scroll.
    pagePos.value = getTopRightPos()
    isDocked.value = false
    wasDocked.value = false
    nextTick(() => focusTerminal())
  }
}

/* ========================================================================
   Mobile minimized pill — draggable up/down along the right edge
   ======================================================================== */

let pillDragStartCY = 0
let pillDragStartPillY = 0
let pillTapHandled = false

function onMobilePillTouchStart(e: TouchEvent) {
  const touch = e.touches[0]
  if (!touch) return
  pillDragStartCY = touch.clientY
  pillDragStartPillY = mobilePillY.value
  pillTapHandled = false
  isDraggingMobilePill.value = true
  document.addEventListener('touchmove', onMobilePillTouchMove, { passive: false })
  document.addEventListener('touchend', onMobilePillTouchEnd)
}

function onMobilePillTouchMove(e: TouchEvent) {
  if (!isDraggingMobilePill.value) return
  const touch = e.touches[0]
  if (!touch) return
  const dy = touch.clientY - pillDragStartCY
  if (Math.abs(dy) > 6) {
    e.preventDefault()
    pillTapHandled = true // suppress click after drag
  }
  const PILL_H = 48
  mobilePillY.value = Math.max(
    60,
    Math.min(viewportHeight.value - PILL_H - 16, pillDragStartPillY + dy),
  )
}

function onMobilePillTouchEnd() {
  isDraggingMobilePill.value = false
  document.removeEventListener('touchmove', onMobilePillTouchMove)
  document.removeEventListener('touchend', onMobilePillTouchEnd)
}

function onMobilePillClick() {
  if (pillTapHandled) {
    pillTapHandled = false
    return
  }
  expand()
}

/* ========================================================================
   Lifecycle
   ======================================================================== */

onMounted(() => {
  register(autoType, clearAutoType, runCommand)
  // Default mobile pill position: 70% down the right edge
  mobilePillY.value = Math.round(window.innerHeight * 0.7)

  if (window.innerWidth >= 640) {
    // Desktop: poll for hero slot and play the entry animation on first load.
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
  } else {
    // Mobile: start minimized and skip entry animation entirely.
    // The hero shows centered content; the pill lets the user open the terminal.
    isMinimized.value = true
    revealDone.value = true
  }

  runBoot()
  window.addEventListener('resize', onResize)
})

onUnmounted(() => {
  clearTimeout(autoTypeTimeout)
  if (minimizeTimer !== null) clearTimeout(minimizeTimer)
  document.removeEventListener('mousemove', onDragMove)
  document.removeEventListener('mouseup', onDragEnd)
  document.removeEventListener('touchmove', onTouchMove)
  document.removeEventListener('touchend', onTouchEnd)
  document.removeEventListener('touchmove', onMobilePillTouchMove)
  document.removeEventListener('touchend', onMobilePillTouchEnd)
  window.removeEventListener('scroll', onDragScroll, true)
  window.removeEventListener('resize', onResize)
  unregister()
})

/* ========================================================================
   Route watchers — terminal follows navigation
   Position changes are DEFERRED when a page transition is active, so the
   terminal stays stationary during the animation and repositions after.
   ======================================================================== */

function applyHomePageChange(onHome: boolean) {
  if (!onHome && !isMinimized.value) {
    if (isDocked.value) {
      pagePos.value = getTopRightPos(0)
      undock()
    } else {
      isTransitioning.value = true
      pagePos.value = getTopRightPos(0)
      setTimeout(() => { isTransitioning.value = false }, 500)
    }
  }
  if (onHome && isDocked.value) {
    let attempts = 0
    function pollSlot() {
      if (measureSlot()) return
      if (++attempts < 60) requestAnimationFrame(pollSlot)
    }
    nextTick(pollSlot)
  }
  if (onHome && !isDocked.value && !isMinimized.value) {
    if (route.hash) {
      // Has a section hash (e.g. /#projects): slide terminal to sit beside that
      // section using the same page-coordinate formula as followNavigation().
      // Poll in case the section element isn't in the DOM yet (lazy-loaded home).
      const sectionId = route.hash.slice(1)
      nextTick(() => {
        let attempts = 0
        function pollAndPosition() {
          const section = document.getElementById(sectionId)
          if (section && section.offsetParent !== null) {
            const rect = section.getBoundingClientRect()
            const termW = lockedWidth.value > 0 ? lockedWidth.value : 380
            isTransitioning.value = true
            pagePos.value = {
              x: Math.max(0, window.innerWidth - termW - 24),
              y: rect.top + window.scrollY + 20,
            }
            setTimeout(() => { isTransitioning.value = false }, 500)
            return
          }
          if (++attempts < 60) requestAnimationFrame(pollAndPosition)
        }
        pollAndPosition()
      })
    } else {
      // No hash: animate terminal back to hero slot (original load position).
      nextTick(() => {
        let attempts = 0
        function pollAndDock() {
          const slot = document.getElementById('hero-terminal-slot')
          if (slot && slot.offsetParent !== null) {
            const rect = slot.getBoundingClientRect()
            isTransitioning.value = true
            pagePos.value = { x: rect.left + window.scrollX, y: rect.top + window.scrollY }
            setTimeout(() => {
              isDocked.value = true
              slotFound.value = true
              isTransitioning.value = false
            }, 500)
            return
          }
          if (++attempts < 60) requestAnimationFrame(pollAndDock)
        }
        pollAndDock()
      })
    }
  }
}

watch(isOnHomePage, (onHome) => {
  applyHomePageChange(onHome)
})

function applyBlogPageChange(onBlog: boolean) {
  if (!onBlog || isMinimized.value) return
  // Mobile: minimize — fixed panel doesn't fit the reading experience
  if (viewportWidth.value < 640) { minimize(); return }
  // Animate to top-right regardless of docked/undocked state so the transition
  // mirrors the blog→home re-dock animation (smooth slide, not an instant jump).
  measureSlot()
  isTransitioning.value = true
  undock()
  pagePos.value = getTopRightPos(0)
  setTimeout(() => { isTransitioning.value = false }, 500)
}

watch(isBlogPage, (onBlog) => {
  applyBlogPageChange(onBlog)
})

// Mobile: close the terminal panel when the user scrolls.
// A fixed overlay blocking content while the user tries to read is poor UX.
watch(scrollY, () => {
  if (viewportWidth.value >= 640) return
  if (isMobileOpen.value) minimize()
})

// navTransitioning bridges the one-tick gap between a route change and the
// watcher that calls undock() — prevents a brief isVisible=false flash.
router.beforeEach(() => {
  navTransitioning.value = true
})

router.afterEach(() => {
  nextTick(() => { navTransitioning.value = false })
})
</script>

<template>
  <!-- Desktop + mobile: bottom-right expand pill (shown when minimized on desktop) -->
  <Transition name="pill-fade">
    <button
      v-if="showDesktopPill"
      class="terminal-pill"
      aria-label="Expand terminal"
      @click="expand"
    >
      <span class="font-mono text-xs">&gt;_</span>
    </button>
  </Transition>

  <!-- Mobile: minimized pill — bottom-right edge, draggable up/down -->
  <Transition name="pill-fade">
    <button
      v-if="showMobilePill"
      class="mobile-pill"
      :style="mobilePillStyle"
      aria-label="Open terminal"
      @touchstart="onMobilePillTouchStart"
      @click="onMobilePillClick"
    >
      <span class="mobile-pill-icon">&gt;_</span>
    </button>
  </Transition>

  <!-- Mobile backdrop — dims page when terminal panel is open; tap to close -->
  <Transition name="panel-fade">
    <div
      v-if="isMobileOpen"
      class="mobile-panel-backdrop"
      aria-hidden="true"
      @click="minimize()"
    />
  </Transition>

  <!-- Terminal — absolute on desktop, fixed panel on mobile -->
  <div
    v-show="isVisible"
    ref="terminalWrapRef"
    :class="[
      'terminal-wrap',
      isDragging ? 'is-dragging' : '',
      isTransitioning ? 'is-transitioning' : '',
      isMobileOpen ? 'is-mobile-open' : '',
    ]"
    :style="terminalStyle"
  >
    <div
      :class="[
        'terminal-card',
        revealDone ? 'reveal-done' : entered ? 'reveal reveal-terminal is-revealed' : 'reveal',
        isExpanding ? 'is-expanding' : '',
        isMinimizing ? 'is-minimizing' : '',
      ]"
      @animationend.self="onTerminalCardAnimEnd"
      @click="focusTerminal"
    >
      <!-- Title bar: mouse drag on desktop, touch drag (+ swipe-down/right to dismiss) on mobile -->
      <div class="terminal-bar" @mousedown="onDragStart" @touchstart.prevent="onTouchStart">
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
              @keydown="handleKeyDown"
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

.terminal-wrap.is-transitioning {
  transition:
    left 0.5s cubic-bezier(0.16, 1, 0.3, 1),
    top 0.5s cubic-bezier(0.16, 1, 0.3, 1);
}

/* Mobile open: no left/top transitions — position is set directly from drag */
.terminal-wrap.is-mobile-open.is-transitioning {
  transition: none;
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

/* Stable state after entry animation — v-show cycles won't replay the delay */
.reveal-done {
  opacity: 1;
  filter: none;
  transform: none;
}

/* Expand fade-in — plays when opening from minimized state */
.terminal-card.is-expanding {
  animation: expandFadeIn 0.15s ease forwards;
}

/* Minimize fade-out — plays before the terminal is hidden */
.terminal-card.is-minimizing {
  animation: expandFadeIn 0.15s ease reverse forwards;
  pointer-events: none;
}

@keyframes expandFadeIn {
  from {
    opacity: 0;
    transform: scale(0.97);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

/* Pill fade — enter and leave */
.pill-fade-enter-active {
  animation: expandFadeIn 0.15s ease forwards;
}

.pill-fade-leave-active {
  animation: expandFadeIn 0.15s ease reverse forwards;
  pointer-events: none;
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
   Desktop + Mobile: minimize pill
   =================================================================== */
.terminal-pill {
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 1010;
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

/* ===================================================================
   Mobile: minimized pill — right edge, draggable up/down
   'top' and transition are set via mobilePillStyle computed.
   =================================================================== */
.mobile-pill {
  position: fixed;
  z-index: 1010;
  width: 36px;
  height: 48px;
  border-radius: 8px 0 0 8px;
  background: var(--skin-600);
  color: white;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  touch-action: none;
  box-shadow: -2px 4px 16px rgba(var(--skin-rgb), 0.35);
  transition: width 0.15s ease, box-shadow 0.2s ease;
}

.mobile-pill:active {
  width: 44px;
}

.mobile-pill-icon {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.6rem;
  font-weight: 700;
  letter-spacing: -0.03em;
  line-height: 1;
  writing-mode: vertical-rl;
  text-orientation: mixed;
  transform: rotate(180deg);
}

:is(.dark *) .mobile-pill {
  background: var(--skin-500);
  box-shadow: -2px 4px 16px rgba(var(--skin-light-rgb), 0.3);
}

/* ===================================================================
   Mobile: floating panel backdrop — dims page, tap to close
   =================================================================== */
.mobile-panel-backdrop {
  position: fixed;
  inset: 0;
  z-index: 1010;
  background: rgba(0, 0, 0, 0.45);
  backdrop-filter: blur(2px);
}

.panel-fade-enter-active,
.panel-fade-leave-active {
  transition: opacity 0.2s ease;
}

.panel-fade-enter-from,
.panel-fade-leave-to {
  opacity: 0;
}

/* ===================================================================
   Mobile: open floating panel
   =================================================================== */
.terminal-wrap.is-mobile-open {
  /* Fade-in on open — kept very short so it feels instant */
  animation: mobilePanel 0.15s cubic-bezier(0.16, 1, 0.3, 1) backwards;
}

@keyframes mobilePanel {
  from {
    opacity: 0;
    transform: translateY(16px) scale(0.97);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

/* Card fills the full panel height so the body scrolls within it */
.terminal-wrap.is-mobile-open .terminal-card {
  height: 100%;
  display: flex;
  flex-direction: column;
}

.terminal-wrap.is-mobile-open .terminal-body {
  max-height: none;
  flex: 1;
  overflow-y: auto;
}
</style>
