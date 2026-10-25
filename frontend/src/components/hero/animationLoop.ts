import { prefersReducedMotion } from '@/utils/motion'

export interface AnimationLoop {
  /** Repaints the still frame under reduced motion; a running loop picks changes up by itself. */
  redraw(): void
  stop(): void
}

export function startAnimationLoop(
  el: Element,
  frame: () => void,
  still: () => void = frame
): AnimationLoop {
  if (prefersReducedMotion()) {
    still()
    return { redraw: still, stop: () => {} }
  }

  let id = 0
  const tick = () => {
    frame()
    id = requestAnimationFrame(tick)
  }
  const observer = new IntersectionObserver(([entry]) => {
    cancelAnimationFrame(id)
    if (entry?.isIntersecting) id = requestAnimationFrame(tick)
  })
  observer.observe(el)

  return {
    redraw: () => {},
    stop: () => {
      observer.disconnect()
      cancelAnimationFrame(id)
    },
  }
}
