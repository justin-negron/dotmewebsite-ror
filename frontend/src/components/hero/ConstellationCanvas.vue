<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'

const props = withDefaults(
  defineProps<{
    isDark: boolean
    particleRgb?: string
    fadeLightRgb?: string
    fadeDarkRgb?: string
  }>(),
  {
    particleRgb: '217, 119, 6',
    fadeLightRgb: '254, 252, 248',
    fadeDarkRgb: '10, 10, 10',
  }
)

const canvasRef = ref<HTMLCanvasElement | null>(null)
let animationId = 0
let ctx: CanvasRenderingContext2D | null = null
let width = 0
let height = 0
const mouse = { x: -1000, y: -1000, active: false }
let dots: Dot[] = []

/* ========================================================================
   Dot (node) definition
   ======================================================================== */

const DOT_COUNT = 100
const CONNECTION_DIST = 150
const MOUSE_CONNECTION_DIST = 200
const DOT_RADIUS_MIN = 1.5
const DOT_RADIUS_MAX = 3

interface Dot {
  x: number
  y: number
  vx: number
  vy: number
  radius: number
}

function createDot(): Dot {
  return {
    x: Math.random() * width,
    y: Math.random() * height,
    vx: (Math.random() - 0.5) * 0.4,
    vy: (Math.random() - 0.5) * 0.4,
    radius: DOT_RADIUS_MIN + Math.random() * (DOT_RADIUS_MAX - DOT_RADIUS_MIN),
  }
}

/* ========================================================================
   Update & render
   ======================================================================== */

function updateDot(d: Dot) {
  d.x += d.vx
  d.y += d.vy

  // Bounce off edges with padding
  if (d.x < 0 || d.x > width) d.vx *= -1
  if (d.y < 0 || d.y > height) d.vy *= -1

  // Keep in bounds
  d.x = Math.max(0, Math.min(width, d.x))
  d.y = Math.max(0, Math.min(height, d.y))
}

function render() {
  if (!ctx) return

  // Clear with background
  const bgRgb = props.isDark ? props.fadeDarkRgb : props.fadeLightRgb
  ctx.fillStyle = `rgb(${bgRgb})`
  ctx.fillRect(0, 0, width, height)

  const dotAlpha = props.isDark ? 0.5 : 0.25
  const lineAlpha = props.isDark ? 0.2 : 0.08
  const mouseLineAlpha = props.isDark ? 0.35 : 0.15
  const color = props.particleRgb

  // Update positions
  for (const d of dots) {
    updateDot(d)
  }

  // Draw connections between nearby dots
  for (let i = 0; i < dots.length; i++) {
    for (let j = i + 1; j < dots.length; j++) {
      const a = dots[i]!
      const b = dots[j]!
      const dx = a.x - b.x
      const dy = a.y - b.y
      const dist = Math.sqrt(dx * dx + dy * dy)

      if (dist < CONNECTION_DIST) {
        const alpha = (1 - dist / CONNECTION_DIST) * lineAlpha
        ctx.strokeStyle = `rgba(${color}, ${alpha})`
        ctx.lineWidth = 0.8
        ctx.beginPath()
        ctx.moveTo(a.x, a.y)
        ctx.lineTo(b.x, b.y)
        ctx.stroke()
      }
    }
  }

  // Draw connections from mouse to nearby dots
  if (mouse.active) {
    for (const d of dots) {
      const dx = d.x - mouse.x
      const dy = d.y - mouse.y
      const dist = Math.sqrt(dx * dx + dy * dy)

      if (dist < MOUSE_CONNECTION_DIST) {
        const alpha = (1 - dist / MOUSE_CONNECTION_DIST) * mouseLineAlpha
        ctx.strokeStyle = `rgba(${color}, ${alpha})`
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(mouse.x, mouse.y)
        ctx.lineTo(d.x, d.y)
        ctx.stroke()
      }
    }
  }

  // Draw dots
  for (const d of dots) {
    ctx.fillStyle = `rgba(${color}, ${dotAlpha})`
    ctx.beginPath()
    ctx.arc(d.x, d.y, d.radius, 0, Math.PI * 2)
    ctx.fill()
  }

  // Draw mouse node
  if (mouse.active) {
    ctx.fillStyle = `rgba(${color}, ${dotAlpha * 0.6})`
    ctx.beginPath()
    ctx.arc(mouse.x, mouse.y, 3, 0, Math.PI * 2)
    ctx.fill()
  }

  animationId = requestAnimationFrame(render)
}

/* ========================================================================
   Setup & teardown
   ======================================================================== */

function handleResize() {
  if (!canvasRef.value || !ctx) return
  const dpr = Math.min(window.devicePixelRatio, 2)
  width = window.innerWidth
  height = window.innerHeight
  canvasRef.value.width = width * dpr
  canvasRef.value.height = height * dpr
  canvasRef.value.style.width = `${width}px`
  canvasRef.value.style.height = `${height}px`
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
}

function handleMouseMove(e: MouseEvent) {
  mouse.x = e.clientX
  mouse.y = e.clientY
  mouse.active = true
}

function handleMouseLeave() {
  mouse.active = false
}

function handleTouchMove(e: TouchEvent) {
  const touch = e.touches[0]
  if (!touch) return
  mouse.x = touch.clientX
  mouse.y = touch.clientY
  mouse.active = true
}

function handleTouchEnd() {
  mouse.active = false
}

onMounted(() => {
  if (!canvasRef.value) return
  ctx = canvasRef.value.getContext('2d')
  if (!ctx) return

  handleResize()
  dots = Array.from({ length: DOT_COUNT }, createDot)
  animationId = requestAnimationFrame(render)

  window.addEventListener('resize', handleResize)
  window.addEventListener('mousemove', handleMouseMove)
  window.addEventListener('mouseleave', handleMouseLeave)
  window.addEventListener('touchmove', handleTouchMove, { passive: true })
  window.addEventListener('touchend', handleTouchEnd)
})

onUnmounted(() => {
  cancelAnimationFrame(animationId)
  window.removeEventListener('resize', handleResize)
  window.removeEventListener('mousemove', handleMouseMove)
  window.removeEventListener('mouseleave', handleMouseLeave)
  window.removeEventListener('touchmove', handleTouchMove)
  window.removeEventListener('touchend', handleTouchEnd)
})
</script>

<template>
  <canvas ref="canvasRef" class="constellation-canvas" />
</template>

<style scoped>
.constellation-canvas {
  position: absolute;
  inset: 0;
  z-index: 0;
  pointer-events: none;
}
</style>
