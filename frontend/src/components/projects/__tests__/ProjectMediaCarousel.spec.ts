import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import ProjectMediaCarousel from '../ProjectMediaCarousel.vue'

const urls = ['https://cdn.test/1.webp', 'https://cdn.test/2.webp', 'https://cdn.test/3.webp']

function accessibleName(el: Element): string {
  const parts: string[] = []
  el.childNodes.forEach((node) => {
    if (node.nodeType === Node.TEXT_NODE) parts.push(node.textContent ?? '')
    else if (node instanceof HTMLImageElement) parts.push(node.alt)
    else if (node instanceof Element) parts.push(accessibleName(node))
  })
  return parts.join('').replace(/\s+/g, ' ').trim()
}

function mountCarousel(props: Partial<{ urls: string[]; title: string }> = {}) {
  return mount(ProjectMediaCarousel, {
    props: { urls, title: 'Robot Swarm', ...props },
  })
}

describe('ProjectMediaCarousel', () => {
  it('shows the first slide with a descriptive alt', () => {
    const wrapper = mountCarousel()
    const img = wrapper.get('img')

    expect(img.attributes('src')).toBe(urls[0])
    expect(img.attributes('alt')).toBe('Robot Swarm, image 1 of 3')
    expect(wrapper.get('.counter').text()).toBe('1/3')
  })

  it('moves forward and wraps around to the first slide', async () => {
    const wrapper = mountCarousel()
    const next = wrapper.get('[aria-label="Next image"]')

    await next.trigger('click')
    expect(wrapper.get('img').attributes('src')).toBe(urls[1])

    await next.trigger('click')
    await next.trigger('click')
    expect(wrapper.get('img').attributes('src')).toBe(urls[0])
  })

  it('moves backward from the first slide to the last', async () => {
    const wrapper = mountCarousel()

    await wrapper.get('[aria-label="Previous image"]').trigger('click')
    expect(wrapper.get('img').attributes('src')).toBe(urls[2])
  })

  it('jumps to a slide from the dots and marks it current', async () => {
    const wrapper = mountCarousel()

    await wrapper.get('[aria-label="Go to image 3"]').trigger('click')
    expect(wrapper.get('img').attributes('src')).toBe(urls[2])
    expect(wrapper.get('[aria-label="Go to image 3"]').attributes('aria-current')).toBe('true')
    expect(wrapper.get('[aria-label="Go to image 1"]').attributes('aria-current')).toBeUndefined()
  })

  it('responds to arrow keys', async () => {
    const wrapper = mountCarousel()

    await wrapper.trigger('keydown', { key: 'ArrowRight' })
    expect(wrapper.get('img').attributes('src')).toBe(urls[1])

    await wrapper.trigger('keydown', { key: 'ArrowLeft' })
    expect(wrapper.get('img').attributes('src')).toBe(urls[0])
  })

  it('emits open with the current index when the slide is clicked', async () => {
    const wrapper = mountCarousel()

    await wrapper.get('[aria-label="Next image"]').trigger('click')
    await wrapper.get('.slide-btn').trigger('click')
    expect(wrapper.emitted('open')).toEqual([[1]])
  })

  it('does not emit open when an arrow is clicked', async () => {
    const wrapper = mountCarousel()

    await wrapper.get('[aria-label="Next image"]').trigger('click')
    expect(wrapper.emitted('open')).toBeUndefined()
  })

  it('hides navigation for a single image and uses the plain title as alt', () => {
    const wrapper = mountCarousel({ urls: [urls[0]!] })

    expect(wrapper.find('[aria-label="Next image"]').exists()).toBe(false)
    expect(wrapper.find('.dot').exists()).toBe(false)
    expect(wrapper.find('.counter').exists()).toBe(false)
    expect(wrapper.get('img').attributes('alt')).toBe('Robot Swarm')
  })

  it('advances on a touch swipe to the left', async () => {
    const wrapper = mountCarousel()

    await wrapper.trigger('pointerdown', { pointerType: 'touch', clientX: 200 })
    await wrapper.trigger('pointerup', { clientX: 100 })
    expect(wrapper.get('img').attributes('src')).toBe(urls[1])
  })

  it('ignores short touch moves and mouse drags', async () => {
    const wrapper = mountCarousel()

    await wrapper.trigger('pointerdown', { pointerType: 'touch', clientX: 200 })
    await wrapper.trigger('pointerup', { clientX: 190 })
    expect(wrapper.get('img').attributes('src')).toBe(urls[0])

    await wrapper.trigger('pointerdown', { pointerType: 'mouse', clientX: 200 })
    await wrapper.trigger('pointerup', { clientX: 100 })
    expect(wrapper.get('img').attributes('src')).toBe(urls[0])
  })

  it('resets to the first slide if the list shrinks below the current index', async () => {
    const wrapper = mountCarousel()

    await wrapper.get('[aria-label="Go to image 3"]').trigger('click')
    await wrapper.setProps({ urls: urls.slice(0, 2) })
    expect(wrapper.get('img').attributes('src')).toBe(urls[0])
  })

  it('names the slide button by its image and says it opens full size', () => {
    const btn = mountCarousel().get('.slide-btn')

    expect(btn.attributes('aria-label')).toBeUndefined()
    expect(accessibleName(btn.element)).toBe('Robot Swarm, image 1 of 3, opens full size')
  })

  it('announces the slide position politely', async () => {
    const wrapper = mountCarousel()

    await wrapper.get('[aria-label="Next image"]').trigger('click')
    expect(wrapper.get('[aria-live="polite"]').text()).toBe('Image 2 of 3')
  })
})
