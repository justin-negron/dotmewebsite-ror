import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { mount, type VueWrapper } from '@vue/test-utils'
import type { Component } from 'vue'
import FlowFieldCanvas from '../FlowFieldCanvas.vue'
import GeometricDriftCanvas from '../GeometricDriftCanvas.vue'
import ConstellationCanvas from '../ConstellationCanvas.vue'

const pending = new Map<number, FrameRequestCallback>()
let frameId = 0
let rafCalls = 0
let observerCallback: IntersectionObserverCallback | null = null
let reducedMotion = false
const draw = { strokes: 0, fills: [] as string[] }
let wrapper: VueWrapper | null = null

function fakeContext(): CanvasRenderingContext2D {
  let fillStyle = ''
  const noop = () => {}
  return new Proxy({} as CanvasRenderingContext2D, {
    get(_target, prop) {
      if (prop === 'fillStyle') return fillStyle
      if (prop === 'stroke') return () => draw.strokes++
      if (prop === 'fillRect') return () => draw.fills.push(fillStyle)
      return noop
    },
    set(_target, prop, value) {
      if (prop === 'fillStyle') fillStyle = String(value)
      return true
    },
  })
}

function flushFrames(count: number) {
  for (let i = 0; i < count; i++) {
    const callbacks = [...pending.values()]
    pending.clear()
    callbacks.forEach((cb) => cb(i * 16))
  }
}

function setOnScreen(isIntersecting: boolean) {
  observerCallback?.([{ isIntersecting } as IntersectionObserverEntry], {} as IntersectionObserver)
}

function resetDrawing() {
  draw.strokes = 0
  draw.fills = []
}

beforeEach(() => {
  pending.clear()
  rafCalls = 0
  observerCallback = null
  reducedMotion = false
  resetDrawing()
  vi.spyOn(HTMLCanvasElement.prototype, 'getContext').mockImplementation(
    () => fakeContext() as unknown as ReturnType<HTMLCanvasElement['getContext']>
  )
  vi.stubGlobal('requestAnimationFrame', (cb: FrameRequestCallback) => {
    rafCalls++
    pending.set(++frameId, cb)
    return frameId
  })
  vi.stubGlobal('cancelAnimationFrame', (id: number) => pending.delete(id))
  vi.stubGlobal(
    'IntersectionObserver',
    class {
      constructor(cb: IntersectionObserverCallback) {
        observerCallback = cb
      }
      observe() {}
      unobserve() {}
      disconnect() {
        observerCallback = null
      }
      takeRecords() {
        return []
      }
    }
  )
  vi.spyOn(window, 'matchMedia').mockImplementation(
    (query: string) =>
      ({
        matches: reducedMotion && query === '(prefers-reduced-motion: reduce)',
        media: query,
        addEventListener: () => {},
        removeEventListener: () => {},
      }) as unknown as MediaQueryList
  )
})

afterEach(() => {
  wrapper?.unmount()
  wrapper = null
  vi.unstubAllGlobals()
  vi.restoreAllMocks()
})

function mountCanvas(component: Component, isDark = false) {
  wrapper = mount(component, { props: { isDark } })
  return wrapper
}

describe('FlowFieldCanvas frame budget', () => {
  it('draws nothing while scrolled away and 800 strokes a frame on screen', () => {
    mountCanvas(FlowFieldCanvas)

    setOnScreen(false)
    resetDrawing()
    flushFrames(10)
    expect(draw.strokes).toBe(0)

    setOnScreen(true)
    flushFrames(10)
    expect(draw.strokes).toBe(8000)
  })
})

describe.each([
  ['FlowFieldCanvas', FlowFieldCanvas],
  ['GeometricDriftCanvas', GeometricDriftCanvas],
  ['ConstellationCanvas', ConstellationCanvas],
])('%s', (_name, component) => {
  it('paints one frame per animation frame only while on screen', () => {
    mountCanvas(component)

    setOnScreen(false)
    resetDrawing()
    flushFrames(10)
    expect(draw.fills).toHaveLength(0)

    setOnScreen(true)
    flushFrames(10)
    expect(draw.fills).toHaveLength(10)

    setOnScreen(false)
    flushFrames(10)
    expect(draw.fills).toHaveLength(10)
  })

  it('stops for good when unmounted', () => {
    const w = mountCanvas(component)
    setOnScreen(true)
    w.unmount()
    wrapper = null

    resetDrawing()
    flushFrames(10)
    expect(draw.fills).toHaveLength(0)
  })

  it('never requests a frame under reduced motion', () => {
    reducedMotion = true
    mountCanvas(component)
    setOnScreen(true)
    flushFrames(10)

    expect(rafCalls).toBe(0)
  })

  it('repaints its still frame in the new theme under reduced motion', async () => {
    reducedMotion = true
    const w = mountCanvas(component)
    resetDrawing()

    await w.setProps({ isDark: true })
    expect(draw.fills.at(-1)).toBe('rgb(10, 10, 10)')
  })
})
