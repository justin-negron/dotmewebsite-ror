import { ref, computed, watch } from 'vue'

/* ============================================================================
   Types
   ============================================================================ */

export type SkinId = 'amber' | 'ocean' | 'rose' | 'sage'
export type BgId = 'flow-field' | 'geometric-drift' | 'constellations'

export interface SkinConfig {
  id: SkinId
  label: string
  vars: Record<string, string>
  particleRgb: string
  fadeLightRgb: string
  fadeDarkRgb: string
}

export interface BgConfig {
  id: BgId
  label: string
}

/* ============================================================================
   Skin definitions
   ============================================================================ */

export const SKINS: Record<SkinId, SkinConfig> = {
  amber: {
    id: 'amber',
    label: 'Amber',
    particleRgb: '217, 119, 6',
    fadeLightRgb: '254, 252, 248',
    fadeDarkRgb: '10, 10, 10',
    vars: {
      '--skin-800': '#92400e',
      '--skin-700': '#b45309',
      '--skin-600': '#d97706',
      '--skin-500': '#f59e0b',
      '--skin-400': '#fbbf24',
      '--skin-200': '#fde68a',
      '--skin-rgb': '217, 119, 6',
      '--skin-light-rgb': '245, 158, 11',
      '--skin-lighter-rgb': '251, 191, 36',
      '--skin-hero-1': '#fefcf8',
      '--skin-hero-2': '#fdf6ec',
      '--skin-hero-3': '#fef1e1',
      '--skin-hero-dark-1': '#0a0a0a',
      '--skin-hero-dark-2': '#0f0f0f',
      '--skin-hero-dark-3': '#111111',
    },
  },
  ocean: {
    id: 'ocean',
    label: 'Ocean',
    particleRgb: '8, 145, 178',
    fadeLightRgb: '240, 253, 250',
    fadeDarkRgb: '10, 10, 12',
    vars: {
      '--skin-800': '#155e75',
      '--skin-700': '#0e7490',
      '--skin-600': '#0891b2',
      '--skin-500': '#06b6d4',
      '--skin-400': '#22d3ee',
      '--skin-200': '#a5f3fc',
      '--skin-rgb': '8, 145, 178',
      '--skin-light-rgb': '6, 182, 212',
      '--skin-lighter-rgb': '34, 211, 238',
      '--skin-hero-1': '#f0fdfa',
      '--skin-hero-2': '#e0f7fa',
      '--skin-hero-3': '#ccfbf1',
      '--skin-hero-dark-1': '#0a0a0c',
      '--skin-hero-dark-2': '#0a0f11',
      '--skin-hero-dark-3': '#0a1214',
    },
  },
  rose: {
    id: 'rose',
    label: 'Rose',
    particleRgb: '225, 29, 72',
    fadeLightRgb: '255, 241, 242',
    fadeDarkRgb: '10, 10, 10',
    vars: {
      '--skin-800': '#9f1239',
      '--skin-700': '#be123c',
      '--skin-600': '#e11d48',
      '--skin-500': '#f43f5e',
      '--skin-400': '#fb7185',
      '--skin-200': '#fecdd3',
      '--skin-rgb': '225, 29, 72',
      '--skin-light-rgb': '244, 63, 94',
      '--skin-lighter-rgb': '251, 113, 133',
      '--skin-hero-1': '#fff1f2',
      '--skin-hero-2': '#ffe4e6',
      '--skin-hero-3': '#fecdd3',
      '--skin-hero-dark-1': '#0a0a0a',
      '--skin-hero-dark-2': '#0f0a0b',
      '--skin-hero-dark-3': '#120a0b',
    },
  },
  sage: {
    id: 'sage',
    label: 'Sage',
    particleRgb: '5, 150, 105',
    fadeLightRgb: '240, 253, 244',
    fadeDarkRgb: '10, 10, 10',
    vars: {
      '--skin-800': '#065f46',
      '--skin-700': '#047857',
      '--skin-600': '#059669',
      '--skin-500': '#10b981',
      '--skin-400': '#34d399',
      '--skin-200': '#a7f3d0',
      '--skin-rgb': '5, 150, 105',
      '--skin-light-rgb': '16, 185, 129',
      '--skin-lighter-rgb': '52, 211, 153',
      '--skin-hero-1': '#f0fdf4',
      '--skin-hero-2': '#ecfce8',
      '--skin-hero-3': '#dcfce7',
      '--skin-hero-dark-1': '#0a0a0a',
      '--skin-hero-dark-2': '#0a0f0b',
      '--skin-hero-dark-3': '#0a110c',
    },
  },
}

export const BACKGROUNDS: Record<BgId, BgConfig> = {
  'flow-field': { id: 'flow-field', label: 'Flow Field' },
  'geometric-drift': { id: 'geometric-drift', label: 'Geometric Drift' },
  constellations: { id: 'constellations', label: 'Constellations' },
}

export const SKIN_IDS = Object.keys(SKINS) as SkinId[]
export const BG_IDS = Object.keys(BACKGROUNDS) as BgId[]

/* ============================================================================
   State (module-level, shared across all consumers)
   ============================================================================ */

const STORAGE_KEY_SKIN = 'appearance-skin'
const STORAGE_KEY_BG = 'appearance-bg'

function randomItem<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)]!
}

function getInitialSkin(): SkinId {
  if (typeof window === 'undefined') return 'amber'
  const stored = localStorage.getItem(STORAGE_KEY_SKIN)
  if (stored && stored in SKINS) return stored as SkinId
  return randomItem(SKIN_IDS)
}

function getInitialBg(): BgId {
  if (typeof window === 'undefined') return 'flow-field'
  const stored = localStorage.getItem(STORAGE_KEY_BG)
  if (stored && stored in BACKGROUNDS) return stored as BgId
  return randomItem(BG_IDS)
}

const skin = ref<SkinId>(getInitialSkin())
const background = ref<BgId>(getInitialBg())

/* ============================================================================
   CSS variable application
   ============================================================================ */

function applySkinVars(id: SkinId) {
  if (typeof document === 'undefined') return
  const config = SKINS[id]
  const el = document.documentElement
  for (const [prop, value] of Object.entries(config.vars)) {
    el.style.setProperty(prop, value)
  }
}

// Apply immediately on module load to prevent flash
applySkinVars(skin.value)

/* ============================================================================
   Public API
   ============================================================================ */

export function useAppearance() {
  // Watch for changes and persist
  watch(skin, (id) => {
    applySkinVars(id)
    localStorage.setItem(STORAGE_KEY_SKIN, id)
  })

  watch(background, (id) => {
    localStorage.setItem(STORAGE_KEY_BG, id)
  })

  const skinConfig = computed(() => SKINS[skin.value])

  function setSkin(id: SkinId) {
    if (id in SKINS) {
      skin.value = id
    }
  }

  function setBackground(id: BgId) {
    if (id in BACKGROUNDS) {
      background.value = id
    }
  }

  return {
    skin,
    background,
    skinConfig,
    setSkin,
    setBackground,
  }
}
