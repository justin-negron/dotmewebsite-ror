/// <reference types="node" />
import { readdirSync, readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, it, expect } from 'vitest'
import { SKINS, SKIN_IDS } from '@/composables/useAppearance'

// Read styles from disk. Vitest blanks CSS modules even with ?raw, and a ?raw import of an
// SFC replaces that file's entry in the coverage report.
const mainCss = readFileSync(resolve(__dirname, '../../assets/styles/main.css'), 'utf8')

const componentsDir = resolve(__dirname, '..')
const sources: Record<string, string> = Object.fromEntries(
  readdirSync(componentsDir, { recursive: true, encoding: 'utf8' })
    .filter((path) => path.endsWith('.vue'))
    .map((path) => [`/${path}`, readFileSync(resolve(componentsDir, path), 'utf8')])
)

const LIGHT_BG = '#fafaf9'
const DARK_BG = '#0a0a0a'

const ALWAYS_DARK = ['MobileMenu.vue', 'MediaLightbox.vue', 'ProjectMediaCarousel.vue']

const DARK_OVERLAYS = [
  ['MediaLightbox.vue', '.lightbox'],
  ['MobileMenu.vue', '.mobile-overlay'],
] as const

const NOT_BODY_TEXT: Record<string, string> = {
  '.brand-prompt': 'part of the logotype',
  '.card-placeholder': 'icon',
  '.card-arrow': 'icon',
  '.tag-flag': 'aria-hidden decoration',
  '.photo-btn:hover': 'icon button, 3:1 applies',
}

// White on --skin-600 measures 3.19 to 4.70; it needs a darker button token, not a text change.
const NOT_ON_PAGE_BG: Record<string, string> = {
  'ContactSection.vue .submit-btn': 'white on the --skin-600 to --skin-700 gradient',
  'HeroDevJournal.vue .cta-primary': 'white on the --skin-600 to --skin-700 gradient',
  'ExperienceSection.vue .retry-btn': 'white on --skin-600',
  'ProjectsSection.vue .retry-btn': 'white on --skin-600',
  'FloatingTerminal.vue .terminal-pill': 'white icon on --skin-600',
  'FloatingTerminal.vue .mobile-pill': 'white icon on --skin-600',
  'AboutSection.vue .location-pin': 'icon on the dark scrim over the photo',
  'AboutSection.vue .location-text': 'caption on the dark scrim over the photo',
  'ContactSection.vue .success-icon': 'icon, 3:1 applies and it measures 3.16',
}

const OWN_FOCUS_INDICATOR = [
  'ProjectMediaCarousel.vue .media-carousel',
  'FloatingTerminal.vue .terminal-input',
  'FloatingTerminal.vue .terminal-input:focus, .terminal-input:focus-visible',
  'FloatingTerminal.vue .terminal-card:focus, .terminal-card:focus-visible, .terminal-card:focus-within',
  'FloatingTerminal.vue :is(.dark *).terminal-card:focus, :is(.dark *).terminal-card:focus-visible, :is(.dark *).terminal-card:focus-within',
]

function luminance(hex: string): number {
  const channels = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255)
  const [r, g, b] = channels.map((c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4))
  return 0.2126 * r! + 0.7152 * g! + 0.0722 * b!
}

function flattenOver(color: string, background: string): string | null {
  if (/^#[0-9a-f]{6}$/i.test(color)) return color
  const m = color.match(/^rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)$/)
  if (!m) return null
  const alpha = Number(m[4])
  const hex = [1, 2, 3].map((i) => {
    const under = parseInt(background.slice(2 * i - 1, 2 * i + 1), 16)
    const value = Math.round(Number(m[i]) * alpha + under * (1 - alpha))
    return value.toString(16).padStart(2, '0')
  })
  return `#${hex.join('')}`
}

function ratio(a: string, b: string): number {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x)
  return (hi! + 0.05) / (lo! + 0.05)
}

interface Rule {
  file: string
  selector: string
  body: string
}

function rules(css: string, file: string): Rule[] {
  const clean = css.replace(/\/\*[\s\S]*?\*\//g, '')
  return [...clean.matchAll(/([^{}]+)\{([^{}]*)\}/g)].map((m) => ({
    file,
    selector: m[1]!.trim().replace(/\s+/g, ' '),
    body: m[2]!,
  }))
}

const componentRules: Rule[] = Object.entries(sources).flatMap(([path, src]) => {
  const file = path.split('/').pop()!
  if (path.includes('/admin/')) return []
  const styles = [...src.matchAll(/<style[^>]*>([\s\S]*?)<\/style>/g)].map((m) => m[1]).join('\n')
  return rules(styles, file)
})

const isDarkRule = (r: Rule) => r.selector.includes('.dark')
const skinValue = (skin: (typeof SKIN_IDS)[number], token: string) => SKINS[skin].vars[token]!
const describeRule = (r: Rule) => `${r.file} ${r.selector}`

describe('skin tokens', () => {
  it.each(SKIN_IDS)('%s --skin-700 reads as small text on the lightest section', (skin) => {
    expect(ratio(skinValue(skin, '--skin-700'), LIGHT_BG)).toBeGreaterThanOrEqual(4.5)
  })
})

describe('component text contrast', () => {
  it('uses a skin shade for light-mode accent text that passes 4.5:1 in every skin', () => {
    const failures = componentRules
      .filter((r) => !isDarkRule(r) && !ALWAYS_DARK.includes(r.file))
      .filter((r) => !(r.selector in NOT_BODY_TEXT))
      .flatMap((r) => {
        const token = r.body.match(/(?:^|[;\s])color:\s*var\((--skin-\d+)\)/)?.[1]
        if (!token) return []
        return SKIN_IDS.map((skin) => [skin, ratio(skinValue(skin, token), LIGHT_BG)] as const)
          .filter(([, value]) => value < 4.5)
          .map(([skin, value]) => `${describeRule(r)} ${token} ${skin} ${value.toFixed(2)}`)
      })

    expect(failures).toEqual([])
  })

  it('gives light-mode hex and white text a color that passes 4.5:1 on the page background', () => {
    const failures = componentRules
      .filter((r) => !isDarkRule(r) && !ALWAYS_DARK.includes(r.file))
      .filter((r) => !(describeRule(r) in NOT_ON_PAGE_BG))
      .flatMap((r) => {
        const declared = r.body.match(/(?:^|[;\s])color:\s*(#[0-9a-f]{6}|white)\s*;/i)?.[1]
        if (!declared) return []
        const value = ratio(declared === 'white' ? '#ffffff' : declared, LIGHT_BG)
        return value < 4.5 ? [`${describeRule(r)} ${declared} ${value.toFixed(2)}`] : []
      })

    expect(failures).toEqual([])
  })

  it('gives dark-mode text a color that passes 4.5:1 on the dark background', () => {
    const failures = componentRules.filter(isDarkRule).flatMap((r) => {
      const hex = r.body.match(/(?:^|[;\s])color:\s*(#[0-9a-f]{6})\s*;/i)?.[1]
      if (!hex) return []
      const value = ratio(hex, DARK_BG)
      return value < 4.5 ? [`${describeRule(r)} ${hex} ${value.toFixed(2)}`] : []
    })

    expect(failures).toEqual([])
  })

  it.each([
    ['light', (r: Rule) => !isDarkRule(r), LIGHT_BG],
    ['dark', isDarkRule, DARK_BG],
  ] as const)('gives %s-mode placeholder text a color that passes 4.5:1', (_mode, inMode, bg) => {
    const failures = componentRules
      .filter(inMode)
      .filter((r) => /::placeholder|\.terminal-placeholder/.test(r.selector))
      .flatMap((r) => {
        const declared = r.body.match(/(?:^|[;\s])color:\s*([^;]+);/)?.[1]?.trim() ?? 'none'
        const color = flattenOver(declared, bg)
        const value = color ? ratio(color, bg) : 0
        return value < 4.5 ? [`${describeRule(r)} ${declared} ${value.toFixed(2)}`] : []
      })

    expect(failures).toEqual([])
  })
})

describe('focus indicator', () => {
  const globalRules = rules(mainCss, 'main.css')
  const themeColor = (name: string) =>
    mainCss.match(new RegExp(`--color-${name}:\\s*(#[0-9a-f]{6})`, 'i'))?.[1]

  function focusColors(selector: string): string[] {
    const body = globalRules.find((r) => r.selector === selector)?.body ?? ''
    const token = body.match(/var\((--skin-\d+)\)/)?.[1]
    if (token) return SKIN_IDS.map((skin) => skinValue(skin, token))
    const ring = body.match(/ring-([a-z]+-\d+)/)?.[1]
    return [ring ? (themeColor(ring) ?? '#ffffff') : '#ffffff']
  }

  it('draws the light-mode focus outline at 3:1 or better on white in every skin', () => {
    const ratios = focusColors('*:focus-visible').map((c) => Number(ratio(c, '#ffffff').toFixed(2)))
    expect(Math.min(...ratios)).toBeGreaterThanOrEqual(3)
  })

  it('draws the dark-mode focus outline at 3:1 or better on the dark background', () => {
    const ratios = focusColors(':is(.dark *):focus-visible').map((c) =>
      Number(ratio(c, DARK_BG).toFixed(2))
    )
    expect(Math.min(...ratios)).toBeGreaterThanOrEqual(3)
  })

  it('draws the focus outline at 3:1 or better on the always-dark overlays', () => {
    const skinToken = (body = '') => body.match(/outline(?:-color)?:[^;]*var\((--skin-\d+)\)/)?.[1]
    const modes = [
      ['light', '*:focus-visible', LIGHT_BG],
      ['dark', ':is(.dark *):focus-visible', DARK_BG],
    ] as const

    const failures = DARK_OVERLAYS.flatMap(([file, container]) => {
      const own = componentRules.filter((r) => r.file === file)
      const backdrop = own
        .find((r) => r.selector === container)
        ?.body.match(/(?:^|[;\s])background:\s*([^;]+);/)?.[1]
        ?.trim()
      const override = skinToken(
        own.find((r) => r.selector === `${container} :focus-visible`)?.body
      )

      return modes.flatMap(([mode, globalSelector, pageBg]) => {
        const surface = flattenOver(backdrop ?? 'none', pageBg)
        const token =
          override ?? skinToken(globalRules.find((r) => r.selector === globalSelector)?.body)
        if (!surface || !token) return [`${file} ${container} ${mode} ${backdrop} ${token}`]
        return SKIN_IDS.map((skin) => [skin, ratio(skinValue(skin, token), surface)] as const)
          .filter(([, value]) => value < 3)
          .map(
            ([skin, value]) => `${file} ${container} ${mode} ${token} ${skin} ${value.toFixed(2)}`
          )
      })
    })

    expect(failures).toEqual([])
  })

  it('is not switched off by components that draw no indicator of their own', () => {
    const suppressors = componentRules
      .filter((r) => /(?:^|[;\s])outline:\s*(?:none|0)\s*;/.test(r.body))
      .map(describeRule)

    expect(suppressors).toEqual(OWN_FOCUS_INDICATOR)
  })

  it('is not replaced by a weaker skin outline in light mode', () => {
    const failures = componentRules
      .filter((r) => !isDarkRule(r) && !ALWAYS_DARK.includes(r.file))
      .flatMap((r) => {
        const token = r.body.match(/outline:[^;]*var\((--skin-\d+)\)/)?.[1]
        if (!token) return []
        const worst = Math.min(...SKIN_IDS.map((s) => ratio(skinValue(s, token), '#ffffff')))
        return worst < 3 ? [`${describeRule(r)} ${token} ${worst.toFixed(2)}`] : []
      })

    expect(failures).toEqual([])
  })
})
