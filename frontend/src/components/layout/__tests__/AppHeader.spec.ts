import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { mount, flushPromises, type VueWrapper } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { createRouter, createMemoryHistory } from 'vue-router'
import AppHeader from '../AppHeader.vue'
import { useUiStore } from '@/stores'

const Blank = { render: () => null }

let wrapper: VueWrapper | null = null
let section: HTMLElement

async function mountHeader() {
  const pinia = createPinia()
  setActivePinia(pinia)
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{ path: '/', component: Blank }],
  })
  await router.push('/')
  await router.isReady()
  wrapper = mount(AppHeader, { attachTo: document.body, global: { plugins: [pinia, router] } })
  return { w: wrapper, ui: useUiStore() }
}

function navLink(w: VueWrapper, label: string) {
  const link = w.findAll('.nav-link').find((a) => a.text() === label)
  if (!link) throw new Error(`no nav link named ${label}`)
  return link
}

beforeEach(() => {
  vi.spyOn(window, 'scrollTo').mockImplementation(() => {})
  section = document.createElement('section')
  section.id = 'contact'
  document.body.appendChild(section)
})

afterEach(() => {
  wrapper?.unmount()
  wrapper = null
  section.remove()
  vi.restoreAllMocks()
})

describe('AppHeader in-page navigation', () => {
  it('moves focus to the section it scrolls to', async () => {
    const { w } = await mountHeader()

    await navLink(w, 'Contact').trigger('click')
    await flushPromises()

    expect(document.activeElement?.id).toBe('contact')
    expect(section.getAttribute('tabindex')).toBe('-1')
  })

  it('keeps a tabindex the section already has', async () => {
    section.setAttribute('tabindex', '0')
    const { w } = await mountHeader()

    await navLink(w, 'Contact').trigger('click')
    await flushPromises()

    expect(document.activeElement?.id).toBe('contact')
    expect(section.getAttribute('tabindex')).toBe('0')
  })

  it('scrolls smoothly by default and jumps under reduced motion', async () => {
    const scrollTo = vi.mocked(window.scrollTo)
    const { w } = await mountHeader()

    await navLink(w, 'Contact').trigger('click')
    expect(scrollTo).toHaveBeenLastCalledWith({ top: -80, behavior: 'smooth' })

    vi.spyOn(window, 'matchMedia').mockImplementation(
      (query: string) =>
        ({ matches: query === '(prefers-reduced-motion: reduce)', media: query }) as MediaQueryList
    )
    await navLink(w, 'Contact').trigger('click')
    expect(scrollTo).toHaveBeenLastCalledWith({ top: -80, behavior: 'auto' })
  })

  it('marks only the link for the section in view as the current location', async () => {
    const { w, ui } = await mountHeader()
    ui.setActiveSection('contact')
    await flushPromises()

    const current = w.findAll('.nav-link').filter((a) => a.attributes('aria-current'))
    expect(current.map((a) => [a.text(), a.attributes('aria-current')])).toEqual([
      ['Contact', 'location'],
    ])
  })
})
