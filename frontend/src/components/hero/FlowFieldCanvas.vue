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
let particles: Particle[] = []

/* ========================================================================
   Simplex-ish noise (2D)
   ======================================================================== */
const PERM = new Uint8Array(512)
const GRAD = [
  [1, 1],
  [-1, 1],
  [1, -1],
  [-1, -1],
  [1, 0],
  [-1, 0],
  [0, 1],
  [0, -1],
]

function initNoise() {
  const p = new Uint8Array(256)
  for (let i = 0; i < 256; i++) p[i] = i
  for (let i = 255; i > 0; i--) {
    const j = (Math.random() * (i + 1)) | 0
    const tmp = p[i]!
    p[i] = p[j]!
    p[j] = tmp
  }
  for (let i = 0; i < 512; i++) PERM[i] = p[i & 255]!
}

function noise2d(x: number, y: number): number {
  const xi = Math.floor(x) & 255
  const yi = Math.floor(y) & 255
  const xf = x - Math.floor(x)
  const yf = y - Math.floor(y)

  const u = fade(xf)
  const v = fade(yf)

  const aa = PERM[(PERM[xi]! + yi) & 511]!
  const ab = PERM[(PERM[xi]! + yi + 1) & 511]!
  const ba = PERM[(PERM[(xi + 1) & 255]! + yi) & 511]!
  const bb = PERM[(PERM[(xi + 1) & 255]! + yi + 1) & 511]!

  const gaa = GRAD[aa & 7]!
  const gab = GRAD[ab & 7]!
  const gba = GRAD[ba & 7]!
  const gbb = GRAD[bb & 7]!

  const x1 = lerp(dot2(gaa, xf, yf), dot2(gba, xf - 1, yf), u)
  const x2 = lerp(dot2(gab, xf, yf - 1), dot2(gbb, xf - 1, yf - 1), u)
  return lerp(x1, x2, v)
}

function fade(t: number): number {
  return t * t * t * (t * (t * 6 - 15) + 10)
}

function lerp(a: number, b: number, t: number): number {
  return a + t * (b - a)
}

function dot2(g: number[], x: number, y: number): number {
  return g[0]! * x + g[1]! * y
}

/* ========================================================================
   Particles
   ======================================================================== */
const PARTICLE_COUNT = 800
const NOISE_SCALE = 0.003
const SPEED = 0.8
const MOUSE_RADIUS = 150
const MOUSE_FORCE = 3

interface Particle {
  x: number
  y: number
  prevX: number
  prevY: number
  vx: number
  vy: number
  life: number
  maxLife: number
}

function createParticle(): Particle {
  const x = Math.random() * width
  const y = Math.random() * height
  return {
    x,
    y,
    prevX: x,
    prevY: y,
    vx: 0,
    vy: 0,
    life: 0,
    maxLife: 200 + Math.random() * 300,
  }
}

function resetParticle(p: Particle) {
  p.x = Math.random() * width
  p.y = Math.random() * height
  p.prevX = p.x
  p.prevY = p.y
  p.vx = 0
  p.vy = 0
  p.life = 0
  p.maxLife = 200 + Math.random() * 300
}

let time = 0

function updateParticle(p: Particle) {
  p.prevX = p.x
  p.prevY = p.y

  // Flow field angle from noise
  const angle = noise2d(p.x * NOISE_SCALE, p.y * NOISE_SCALE + time * 0.0003) * Math.PI * 4

  p.vx += Math.cos(angle) * SPEED * 0.15
  p.vy += Math.sin(angle) * SPEED * 0.15

  // Cursor disturbance — push particles away
  if (mouse.active) {
    const dx = p.x - mouse.x
    const dy = p.y - mouse.y
    const dist = Math.sqrt(dx * dx + dy * dy)
    if (dist < MOUSE_RADIUS && dist > 0) {
      const force = ((MOUSE_RADIUS - dist) / MOUSE_RADIUS) * MOUSE_FORCE
      p.vx += (dx / dist) * force
      p.vy += (dy / dist) * force
    }
  }

  // Damping
  p.vx *= 0.92
  p.vy *= 0.92

  p.x += p.vx
  p.y += p.vy
  p.life++

  // Wrap around or reset
  if (p.x < -10 || p.x > width + 10 || p.y < -10 || p.y > height + 10 || p.life > p.maxLife) {
    resetParticle(p)
  }
}

/* ========================================================================
   Render
   ======================================================================== */

function getMaxAlpha(dark: boolean): number {
  return dark ? 0.35 : 0.18
}

function render() {
  if (!ctx) return

  // Fade trail — uses skin-aware colors
  const fadeFill = props.isDark
    ? `rgba(${props.fadeDarkRgb}, 0.06)`
    : `rgba(${props.fadeLightRgb}, 0.06)`
  ctx.fillStyle = fadeFill
  ctx.fillRect(0, 0, width, height)

  const maxAlpha = getMaxAlpha(props.isDark)
  const color = `rgba(${props.particleRgb},`

  for (const p of particles) {
    updateParticle(p)

    // Life-based alpha: fade in, sustain, fade out
    const lifeRatio = p.life / p.maxLife
    let alpha: number
    if (lifeRatio < 0.1) {
      alpha = (lifeRatio / 0.1) * maxAlpha
    } else if (lifeRatio > 0.85) {
      alpha = ((1 - lifeRatio) / 0.15) * maxAlpha
    } else {
      alpha = maxAlpha
    }

    // Speed-based line width
    const speed = Math.sqrt(p.vx * p.vx + p.vy * p.vy)
    const lineWidth = Math.min(2.5, 0.5 + speed * 0.4)

    ctx.strokeStyle = `${color} ${alpha})`
    ctx.lineWidth = lineWidth
    ctx.beginPath()
    ctx.moveTo(p.prevX, p.prevY)
    ctx.lineTo(p.x, p.y)
    ctx.stroke()
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

  // Clear and reinitialize with skin-aware background
  const bgRgb = props.isDark ? props.fadeDarkRgb : props.fadeLightRgb
  ctx.fillStyle = `rgb(${bgRgb})`
  ctx.fillRect(0, 0, width, height)
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

// Theme changes are handled naturally by the render loop's fadeFill —
// no hard clear needed, particles and trails blend smoothly to the new bg.

onMounted(() => {
  if (!canvasRef.value) return
  ctx = canvasRef.value.getContext('2d')
  if (!ctx) return

  initNoise()
  handleResize()

  // Create particles
  particles = Array.from({ length: PARTICLE_COUNT }, createParticle)

  // Start render loop
  animationId = requestAnimationFrame(render)

  // Events
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
  <canvas ref="canvasRef" class="flow-canvas" />
</template>

<style scoped>
.flow-canvas {
  position: absolute;
  inset: 0;
  z-index: 0;
  pointer-events: none;
}
</style>
