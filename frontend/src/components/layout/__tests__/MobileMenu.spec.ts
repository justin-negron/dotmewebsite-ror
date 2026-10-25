import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { mount, flushPromises, type VueWrapper } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { createRouter, createMemoryHistory } from 'vue-router'
import MobileMenu from '../MobileMenu.vue'
import { useUiStore } from '@/stores'

const Blank = { render: () => null }

let wrapper: VueWrapper | null = null
let hamburger: HTMLButtonElement

async function mountMenu() {
  const pinia = createPinia()
  setActivePinia(pinia)
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{ path: '/', component: Blank }],
  })
  await router.push('/')
  await router.isReady()
  wrapper = mount(MobileMenu, {
    attachTo: document.body,
    global: { plugins: [pinia, router], stubs: { teleport: true } },
  })
  return { w: wrapper, ui: useUiStore() }
}

async function openMenu(ui: ReturnType<typeof useUiStore>) {
  hamburger.focus()
  ui.isMobileMenuOpen = true
  await flushPromises()
}

function pressTab(shiftKey = false) {
  const evt = new KeyboardEvent('keydown', {
    key: 'Tab',
    shiftKey,
    cancelable: true,
    bubbles: true,
  })
  document.activeElement?.dispatchEvent(evt)
  return evt
}

beforeEach(() => {
  hamburger = document.createElement('button')
  hamburger.setAttribute('aria-controls', 'mobile-menu')
  document.body.appendChild(hamburger)
})

afterEach(() => {
  wrapper?.unmount()
  wrapper = null
  hamburger.remove()
})

describe('MobileMenu focus management', () => {
  it('moves focus to the exit button when it opens', async () => {
    const { ui } = await mountMenu()

    await openMenu(ui)
    expect(document.activeElement?.textContent?.trim()).toBe('exit')
  })

  it('closes on Escape pressed anywhere and returns focus to the hamburger', async () => {
    const { ui } = await mountMenu()
    await openMenu(ui)

    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))
    await flushPromises()

    expect(ui.isMobileMenuOpen).toBe(false)
    expect(document.activeElement).toBe(hamburger)
  })

  it('keeps Tab inside the menu', async () => {
    const { w, ui } = await mountMenu()
    await openMenu(ui)
    const links = w.findAll('.overlay-item')
    const lastLink = links[links.length - 1]!.element as HTMLElement

    lastLink.focus()
    const forward = pressTab()
    expect(forward.defaultPrevented).toBe(true)
    expect(document.activeElement?.textContent?.trim()).toBe('exit')

    const backward = pressTab(true)
    expect(backward.defaultPrevented).toBe(true)
    expect(document.activeElement).toBe(lastLink)
  })
})

describe('MobileMenu names', () => {
  it('names the exit button by its visible text', async () => {
    const { w, ui } = await mountMenu()
    await openMenu(ui)
    const exit = w.get('.overlay-close')

    expect(exit.attributes('aria-label')).toBeUndefined()
    expect(exit.text()).toBe('exit')
  })

  it('marks the link for the section in view as the current location', async () => {
    const { w, ui } = await mountMenu()
    ui.setActiveSection('projects')
    await openMenu(ui)

    const current = w.findAll('.overlay-item').filter((a) => a.attributes('aria-current'))
    expect(current.map((a) => [a.get('.item-label').text(), a.attributes('aria-current')])).toEqual(
      [['projects', 'location']]
    )
  })
})
