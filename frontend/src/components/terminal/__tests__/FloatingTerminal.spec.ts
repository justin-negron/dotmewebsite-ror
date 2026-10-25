import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { mount, flushPromises, type VueWrapper } from '@vue/test-utils'
import { createRouter, createMemoryHistory, type Router } from 'vue-router'
import FloatingTerminal from '../FloatingTerminal.vue'

const Blank = { render: () => null }

function makeRouter(): Router {
  return createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/', component: Blank },
      { path: '/blog', component: Blank },
    ],
  })
}

let wrapper: VueWrapper | null = null

async function mountTerminal(router: Router = makeRouter()) {
  await router.push('/')
  await router.isReady()
  wrapper = mount(FloatingTerminal, {
    attachTo: document.body,
    global: { plugins: [router] },
  })
  await vi.advanceTimersByTimeAsync(2000)
  return wrapper
}

function keydown(el: Element, key: string, init: KeyboardEventInit = {}) {
  const evt = new KeyboardEvent('keydown', { key, cancelable: true, bubbles: true, ...init })
  el.dispatchEvent(evt)
  return evt
}

async function run(w: VueWrapper, cmd: string) {
  const input = w.get('input.terminal-input')
  await input.setValue(cmd)
  keydown(input.element, 'Enter')
  await vi.advanceTimersByTimeAsync(500)
}

beforeEach(() => {
  vi.useFakeTimers()
})

afterEach(() => {
  wrapper?.unmount()
  wrapper = null
  vi.useRealTimers()
  vi.restoreAllMocks()
})

describe('FloatingTerminal keyboard access', () => {
  it('leaves focus on the page after the boot sequence', async () => {
    const w = await mountTerminal()

    expect(w.find('input.terminal-input').exists()).toBe(true)
    expect(document.activeElement).toBe(document.body)
  })

  it('lets Tab leave an empty input', async () => {
    const w = await mountTerminal()

    const evt = keydown(w.get('input.terminal-input').element, 'Tab')
    expect(evt.defaultPrevented).toBe(false)
  })

  it('completes a unique prefix on Tab and keeps focus there', async () => {
    const w = await mountTerminal()
    const input = w.get<HTMLInputElement>('input.terminal-input')
    await input.setValue('pr')

    const evt = keydown(input.element, 'Tab')
    await flushPromises()
    expect(evt.defaultPrevented).toBe(true)
    expect(input.element.value).toBe('projects')
  })

  it('lets Tab leave when completion would not change the value', async () => {
    const w = await mountTerminal()
    const input = w.get<HTMLInputElement>('input.terminal-input')
    await input.setValue('c')

    const evt = keydown(input.element, 'Tab')
    await flushPromises()
    expect(evt.defaultPrevented).toBe(false)
    expect(input.element.value).toBe('c')
  })

  it('never holds Shift+Tab', async () => {
    const w = await mountTerminal()
    const input = w.get<HTMLInputElement>('input.terminal-input')
    await input.setValue('pr')

    const evt = keydown(input.element, 'Tab', { shiftKey: true })
    await flushPromises()
    expect(evt.defaultPrevented).toBe(false)
    expect(input.element.value).toBe('pr')
  })

  it('blurs the input on Escape', async () => {
    const w = await mountTerminal()
    const input = w.get<HTMLInputElement>('input.terminal-input').element
    input.focus()
    expect(document.activeElement).toBe(input)

    keydown(input, 'Escape')
    expect(document.activeElement).toBe(document.body)
  })
})

describe('FloatingTerminal router guards', () => {
  function countGuards(router: Router) {
    const runs = { before: 0, after: 0 }
    const addBefore = router.beforeEach.bind(router)
    const addAfter = router.afterEach.bind(router)
    router.beforeEach = (guard) =>
      addBefore((to, from) => {
        runs.before++
        return guard.call(undefined, to, from, () => {})
      })
    router.afterEach = (hook) =>
      addAfter((to, from, failure) => {
        runs.after++
        hook(to, from, failure)
      })
    return runs
  }

  it('removes both guards when it unmounts', async () => {
    const router = makeRouter()
    const runs = countGuards(router)
    for (let i = 0; i < 3; i++) {
      const w = await mountTerminal(router)
      w.unmount()
      wrapper = null
    }

    Object.assign(runs, { before: 0, after: 0 })
    await router.push('/blog')
    expect(runs).toEqual({ before: 0, after: 0 })
  })

  it('runs each guard once per navigation while mounted', async () => {
    const router = makeRouter()
    const runs = countGuards(router)
    await mountTerminal(router)

    Object.assign(runs, { before: 0, after: 0 })
    await router.push('/blog')
    expect(runs).toEqual({ before: 1, after: 1 })
  })
})

describe('FloatingTerminal screen reader semantics', () => {
  it('names the input and describes it with the hint', async () => {
    const w = await mountTerminal()
    const input = w.get('input.terminal-input')

    expect(input.attributes('aria-label')).toBe('Terminal command')
    const hintId = input.attributes('aria-describedby') ?? ''
    expect(document.getElementById(hintId)?.textContent?.trim()).toBe('type "help" for commands')
  })

  it('exposes the card as a region and the output as a log', async () => {
    const w = await mountTerminal()

    expect(w.get('[role="region"]').attributes('aria-label')).toBe('Terminal')
    await run(w, 'help')
    expect(w.get('[role="log"]').text()).toContain(
      'commands: home, projects, experience, contact, about, resume, article, skin, bg, clear, exit'
    )
  })
})

describe('FloatingTerminal command lookup', () => {
  it.each(['constructor', '__proto__'])(
    'treats the inherited name %s as unknown and opens nothing',
    async (cmd) => {
      const open = vi.spyOn(window, 'open').mockReturnValue(null)
      const w = await mountTerminal()

      await run(w, cmd)
      expect(w.findAll('.cmd-error').at(-1)?.text()).toBe(
        `command not found: ${cmd}. type "help" for commands.`
      )
      expect(open).not.toHaveBeenCalled()
    }
  )

  it('still opens a real link command', async () => {
    const open = vi.spyOn(window, 'open').mockReturnValue(null)
    const w = await mountTerminal()

    await run(w, 'github')
    expect(open).toHaveBeenCalledWith(
      'https://github.com/justin-negron',
      '_blank',
      'noopener,noreferrer'
    )
  })

  it('rejects inherited names as skins and backgrounds', async () => {
    const w = await mountTerminal()

    await run(w, 'skin constructor')
    expect(w.findAll('.cmd-error').at(-1)?.text()).toBe(
      'unknown skin: constructor. try: amber, ocean, rose, sage'
    )
    await run(w, 'bg constructor')
    expect(w.findAll('.cmd-error').at(-1)?.text()).toBe(
      'unknown background: constructor. try: flow-field, geometric-drift, constellations'
    )
  })
})
