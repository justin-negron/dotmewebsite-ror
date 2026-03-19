import { ref, watch } from 'vue'

export type Theme = 'light' | 'dark'

const STORAGE_KEY = 'theme-preference'

function getSystemPreference(): Theme {
  if (typeof window === 'undefined') return 'light'
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
}

function getInitialTheme(): Theme {
  if (typeof window === 'undefined') return 'light'
  const stored = localStorage.getItem(STORAGE_KEY) as Theme | null
  return stored ?? getSystemPreference()
}

// Eagerly initialize to prevent flash of wrong theme
const theme = ref<Theme>(getInitialTheme())

function applyTheme(t: Theme) {
  if (typeof document === 'undefined') return
  if (t === 'dark') {
    document.documentElement.classList.add('dark')
  } else {
    document.documentElement.classList.remove('dark')
  }
  // Keep the browser chrome (status bar / Dynamic Island area on iPhone) in sync
  // with the app theme so it doesn't show a jarring white bar in dark mode.
  const metaThemeColor = document.querySelector('meta[name="theme-color"]')
  if (metaThemeColor) {
    metaThemeColor.setAttribute('content', t === 'dark' ? '#0f0f0f' : '#ffffff')
  }
}

// Apply immediately on module load
applyTheme(theme.value)

/**
 * Circular reveal with blurred new-theme content.
 *
 * Uses View Transitions API:
 * - Old theme (::view-transition-old) stays sharp and untouched
 * - New theme (::view-transition-new) expands from the button as a blurred circle
 * - Once the circle covers everything, the blur resolves
 */
function toggleWithTransition(event?: MouseEvent) {
  const doc = document as Document & {
    startViewTransition?: (cb: () => void) => { ready: Promise<void> }
  }

  // Get the click origin (center of the toggle button)
  let x = window.innerWidth / 2
  let y = 0
  if (event) {
    const rect = (event.currentTarget as HTMLElement).getBoundingClientRect()
    x = rect.left + rect.width / 2
    y = rect.top + rect.height / 2
  }

  // Radius needed to cover entire viewport from click point
  const endRadius = Math.hypot(
    Math.max(x, window.innerWidth - x),
    Math.max(y, window.innerHeight - y)
  )

  // Fallback: no View Transitions API
  if (!doc.startViewTransition) {
    theme.value = theme.value === 'light' ? 'dark' : 'light'
    return
  }

  const transition = doc.startViewTransition(() => {
    theme.value = theme.value === 'light' ? 'dark' : 'light'
  })

  transition.ready.then(() => {
    // Circle expands from button — new theme revealed with blur
    // Clip-path: circle grows from 0 to full radius
    // Filter: stays blurred during expansion (0%-80%), then sharpens (80%-100%)
    document.documentElement.animate(
      [
        {
          clipPath: `circle(0px at ${x}px ${y}px)`,
          filter: 'blur(3px)',
          offset: 0,
        },
        {
          clipPath: `circle(${endRadius}px at ${x}px ${y}px)`,
          filter: 'blur(3px)',
          offset: 0.8,
        },
        {
          clipPath: `circle(${endRadius}px at ${x}px ${y}px)`,
          filter: 'blur(0px)',
          offset: 1,
        },
      ],
      {
        duration: 800,
        easing: 'cubic-bezier(0.4, 0, 0.2, 1)',
        pseudoElement: '::view-transition-new(root)',
      }
    )
  })
}

export function useTheme() {
  watch(theme, (t) => {
    applyTheme(t)
    localStorage.setItem(STORAGE_KEY, t)
  })

  return {
    theme,
    toggleTheme: toggleWithTransition,
  }
}
