import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import { createPinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
/// <reference types="node" />
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import App from '@/App.vue'
import { SKINS, SKIN_IDS } from '@/composables/useAppearance'
import { contrastRatio } from '@/test/contrast'

// Read from disk: a ?raw import would replace App.vue's real coverage with its raw module.
const appSource = readFileSync(resolve(__dirname, '../App.vue'), 'utf8')

const stub = vi.hoisted(() => ({ default: { template: '<div />' } }))
vi.mock('@/components/layout/AppHeader.vue', () => stub)
vi.mock('@/components/layout/MobileMenu.vue', () => stub)
vi.mock('@/components/layout/AppFooter.vue', () => stub)
vi.mock('@/components/layout/ToastContainer.vue', () => stub)
vi.mock('@/components/terminal/FloatingTerminal.vue', () => stub)

function stubReducedMotion(reduce: boolean) {
  vi.spyOn(window, 'matchMedia').mockImplementation(
    (query: string) =>
      ({
        matches: reduce && query === '(prefers-reduced-motion: reduce)',
        media: query,
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      }) as unknown as MediaQueryList
  )
}

async function mountApp() {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/', component: { template: '<p>home page</p>' } },
      { path: '/next', component: { template: '<p>next page</p>' } },
    ],
  })
  await router.push('/')
  const container = document.createElement('div')
  container.id = 'app'
  document.body.appendChild(container)
  const wrapper = mount(App, {
    attachTo: container,
    global: { plugins: [createPinia(), router], stubs: { transition: false } },
  })
  return { router, wrapper }
}

async function settle() {
  await new Promise((resolve) => setTimeout(resolve))
  await nextTick()
}

describe('App', () => {
  beforeEach(() => {
    document.body.innerHTML = ''
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('leaves exactly one #app element in the document', async () => {
    stubReducedMotion(false)
    const { wrapper } = await mountApp()

    expect(document.querySelectorAll('#app')).toHaveLength(1)
    wrapper.unmount()
  })

  it('swaps pages at once when the visitor prefers reduced motion', async () => {
    stubReducedMotion(true)
    const { router, wrapper } = await mountApp()

    await router.push('/next')
    await settle()

    expect(wrapper.get('main').text()).toBe('next page')
    expect(wrapper.get('main p').attributes('style')).toBeUndefined()
    wrapper.unmount()
  })

  it('draws the skip link on a skin shade that passes 4.5:1 under its white text', () => {
    const rule = appSource.match(/\.skip-link \{([^}]*)\}/)?.[1] ?? ''
    const token = rule.match(/background: var\((--skin-\d+)\)/)?.[1] ?? ''

    expect(rule).toContain('color: white;')
    const ratios = SKIN_IDS.map((id) =>
      contrastRatio('#ffffff', SKINS[id].vars[token] ?? '#ffffff')
    )
    expect(Math.min(...ratios)).toBeGreaterThanOrEqual(4.5)
  })

  it('fades the old page out first otherwise', async () => {
    stubReducedMotion(false)
    const { router, wrapper } = await mountApp()

    await router.push('/next')
    await settle()

    expect(wrapper.get('main').text()).toBe('home page')
    expect(wrapper.get('main p').attributes('style')).toBe(
      'transition: opacity 0.2s ease; opacity: 0;'
    )
    wrapper.unmount()
  })
})
