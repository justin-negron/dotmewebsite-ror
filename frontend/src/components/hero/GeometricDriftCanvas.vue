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
let shapes: Shape[] = []
let time = 0

/* ========================================================================
   Shape types
   ======================================================================== */

type ShapeKind = 'triangle' | 'circle' | 'hexagon' | 'square' | 'diamond'

interface Shape {
  x: number
  y: number
  vx: number
  vy: number
  size: number
  rotation: number
  rotationSpeed: number
  kind: ShapeKind
  baseAlpha: number
  phase: number // for sinusoidal movement variation
}

const SHAPE_COUNT = 35
const MOUSE_RADIUS = 200
const MOUSE_FORCE = 0.8
const KINDS: ShapeKind[] = ['triangle', 'circle', 'hexagon', 'square', 'diamond']

function createShape(): Shape {
  return {
    x: Math.random() * width,
    y: Math.random() * height,
    vx: (Math.random() - 0.5) * 0.3,
    vy: (Math.random() - 0.5) * 0.3,
    size: 15 + Math.random() * 40,
    rotation: Math.random() * Math.PI * 2,
    rotationSpeed: (Math.random() - 0.5) * 0.003,
    kind: KINDS[Math.floor(Math.random() * KINDS.length)]!,
    baseAlpha: 0.04 + Math.random() * 0.06,
    phase: Math.random() * Math.PI * 2,
  }
}

/* ========================================================================
   Drawing shapes
   ======================================================================== */

function drawTriangle(ctx: CanvasRenderingContext2D, size: number) {
  const h = size * 0.866
  ctx.beginPath()
  ctx.moveTo(0, -h * 0.6)
  ctx.lineTo(-size / 2, h * 0.4)
  ctx.lineTo(size / 2, h * 0.4)
  ctx.closePath()
}

function drawHexagon(ctx: CanvasRenderingContext2D, size: number) {
  const r = size / 2
  ctx.beginPath()
  for (let i = 0; i < 6; i++) {
    const angle = (Math.PI / 3) * i - Math.PI / 6
    const px = Math.cos(angle) * r
    const py = Math.sin(angle) * r
    if (i === 0) ctx.moveTo(px, py)
    else ctx.lineTo(px, py)
  }
  ctx.closePath()
}

function drawSquare(ctx: CanvasRenderingContext2D, size: number) {
  const half = size / 2
  ctx.beginPath()
  ctx.rect(-half, -half, size, size)
}

function drawDiamond(ctx: CanvasRenderingContext2D, size: number) {
  const half = size / 2
  ctx.beginPath()
  ctx.moveTo(0, -half)
  ctx.lineTo(half * 0.6, 0)
  ctx.lineTo(0, half)
  ctx.lineTo(-half * 0.6, 0)
  ctx.closePath()
}

function drawShape(ctx: CanvasRenderingContext2D, shape: Shape, alpha: number) {
  ctx.save()
  ctx.translate(shape.x, shape.y)
  ctx.rotate(shape.rotation)
  ctx.strokeStyle = `rgba(${props.particleRgb}, ${alpha})`
  ctx.lineWidth = 1.2

  switch (shape.kind) {
    case 'triangle':
      drawTriangle(ctx, shape.size)
      break
    case 'circle':
      ctx.beginPath()
      ctx.arc(0, 0, shape.size / 2, 0, Math.PI * 2)
      break
    case 'hexagon':
      drawHexagon(ctx, shape.size)
      break
    case 'square':
      drawSquare(ctx, shape.size)
      break
    case 'diamond':
      drawDiamond(ctx, shape.size)
      break
  }

  ctx.stroke()
  ctx.restore()
}

/* ========================================================================
   Update & render
   ======================================================================== */

function updateShape(s: Shape) {
  // Sinusoidal drift variation
  const drift = Math.sin(time * 0.001 + s.phase) * 0.05
  s.x += s.vx + drift
  s.y += s.vy + Math.cos(time * 0.0008 + s.phase) * 0.03

  // Mouse repulsion
  if (mouse.active) {
    const dx = s.x - mouse.x
    const dy = s.y - mouse.y
    const dist = Math.sqrt(dx * dx + dy * dy)
    if (dist < MOUSE_RADIUS && dist > 0) {
      const force = ((MOUSE_RADIUS - dist) / MOUSE_RADIUS) * MOUSE_FORCE
      s.vx += (dx / dist) * force * 0.02
      s.vy += (dy / dist) * force * 0.02
      s.rotationSpeed += force * 0.001 // spin faster near cursor
    }
  }

  // Gentle damping on velocity added by mouse
  s.vx *= 0.998
  s.vy *= 0.998
  s.rotationSpeed *= 0.999

  s.rotation += s.rotationSpeed

  // Wrap around edges
  const margin = s.size
  if (s.x < -margin) s.x = width + margin
  if (s.x > width + margin) s.x = -margin
  if (s.y < -margin) s.y = height + margin
  if (s.y > height + margin) s.y = -margin
}

function render() {
  if (!ctx) return

  // Clear with background
  const bgRgb = props.isDark ? props.fadeDarkRgb : props.fadeLightRgb
  ctx.fillStyle = `rgb(${bgRgb})`
  ctx.fillRect(0, 0, width, height)

  const alphaMultiplier = props.isDark ? 3.5 : 1.8

  for (const s of shapes) {
    updateShape(s)
    const alpha = s.baseAlpha * alphaMultiplier
    drawShape(ctx, s, alpha)
  }

  time++
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
  shapes = Array.from({ length: SHAPE_COUNT }, createShape)
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
  <canvas ref="canvasRef" class="geo-canvas" />
</template>

<style scoped>
.geo-canvas {
  position: absolute;
  inset: 0;
  z-index: 0;
  pointer-events: none;
}
</style>
