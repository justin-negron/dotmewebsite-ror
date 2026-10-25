import { describe, it, expect, afterEach } from 'vitest'
import { mount, type VueWrapper } from '@vue/test-utils'
import { nextTick } from 'vue'
import MediaLightbox from '../MediaLightbox.vue'

const urls = ['https://cdn.test/1.webp', 'https://cdn.test/2.webp']

let wrapper: VueWrapper | null = null

function mountLightbox(props: Partial<{ urls: string[]; startIndex: number; title: string }> = {}) {
  wrapper = mount(MediaLightbox, {
    props: { urls, startIndex: 0, title: 'Discord Bot', ...props },
    attachTo: document.body,
    global: { stubs: { teleport: true } },
  })
  return wrapper
}

function pressKey(key: string) {
  document.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true }))
}

afterEach(() => {
  wrapper?.unmount()
  wrapper = null
})

describe('MediaLightbox', () => {
  it('opens on the requested slide with a counter', () => {
    const w = mountLightbox({ startIndex: 1 })

    expect(w.get('img').attributes('src')).toBe(urls[1])
    expect(w.get('img').attributes('alt')).toBe('Discord Bot, image 2 of 2')
    expect(w.get('.lb-counter').text()).toBe('2 / 2')
  })

  it('emits close on Escape', () => {
    const w = mountLightbox()

    pressKey('Escape')
    expect(w.emitted('close')).toHaveLength(1)
  })

  it('navigates with the arrow keys and wraps', async () => {
    const w = mountLightbox()

    pressKey('ArrowRight')
    await nextTick()
    expect(w.get('img').attributes('src')).toBe(urls[1])

    pressKey('ArrowRight')
    await nextTick()
    expect(w.get('img').attributes('src')).toBe(urls[0])

    pressKey('ArrowLeft')
    await nextTick()
    expect(w.get('img').attributes('src')).toBe(urls[1])
  })

  it('closes when the backdrop is clicked but not when the image is clicked', async () => {
    const w = mountLightbox()

    await w.get('img').trigger('click')
    expect(w.emitted('close')).toBeUndefined()

    await w.get('.lightbox').trigger('click')
    expect(w.emitted('close')).toHaveLength(1)
  })

  it('closes from the close button', async () => {
    const w = mountLightbox()

    await w.get('[aria-label="Close image viewer"]').trigger('click')
    expect(w.emitted('close')).toHaveLength(1)
  })

  it('locks body scroll while open and restores it on unmount', () => {
    document.body.style.overflow = 'auto'
    const w = mountLightbox()

    expect(document.body.style.overflow).toBe('hidden')

    w.unmount()
    wrapper = null
    expect(document.body.style.overflow).toBe('auto')
    document.body.style.overflow = ''
  })

  it('moves focus to the close button on open', async () => {
    const w = mountLightbox()
    await nextTick()

    expect(document.activeElement).toBe(w.get('[aria-label="Close image viewer"]').element)
  })

  it('hides the arrows and counter for a single image', () => {
    const w = mountLightbox({ urls: [urls[0]!] })

    expect(w.find('[aria-label="Next image"]').exists()).toBe(false)
    expect(w.find('.lb-counter').exists()).toBe(false)
    expect(w.get('img').attributes('alt')).toBe('Discord Bot')
  })

  it('stops handling keys after unmount', () => {
    const w = mountLightbox()
    const arrow = () => {
      const evt = new KeyboardEvent('keydown', { key: 'ArrowRight', cancelable: true })
      document.dispatchEvent(evt)
      return evt.defaultPrevented
    }

    expect(arrow()).toBe(true)
    w.unmount()
    wrapper = null
    expect(arrow()).toBe(false)
  })

  it('clamps to a real slide when the list shrinks under it', async () => {
    const w = mountLightbox({ startIndex: 1 })

    await w.setProps({ urls: [urls[0]!] })
    expect(w.get('img').attributes('src')).toBe(urls[0])
    expect(w.find('.lb-counter').exists()).toBe(false)
  })

  it('closes when no slide is left to show', async () => {
    const w = mountLightbox()

    await w.setProps({ urls: [] })
    expect(w.emitted('close')).toHaveLength(1)
  })

  it('announces the slide position politely', async () => {
    const w = mountLightbox()

    pressKey('ArrowRight')
    await nextTick()
    expect(w.get('[aria-live="polite"]').text()).toBe('Image 2 of 2')
  })

  it('keeps Tab inside the dialog', async () => {
    const w = mountLightbox()
    const next = w.get('[aria-label="Next image"]').element as HTMLElement
    next.focus()

    const evt = new KeyboardEvent('keydown', { key: 'Tab', cancelable: true, bubbles: true })
    next.dispatchEvent(evt)
    expect(evt.defaultPrevented).toBe(true)
    expect(document.activeElement).toBe(w.get('[aria-label="Close image viewer"]').element)
  })
})
