<script setup lang="ts">
import { ref, computed, onMounted, type Component } from 'vue'
import { useTheme } from '@/composables/useTheme'
import { useAppearance } from '@/composables/useAppearance'
import { useTerminalBridge } from '@/composables/useTerminalBridge'
import FlowFieldCanvas from './FlowFieldCanvas.vue'
import GeometricDriftCanvas from './GeometricDriftCanvas.vue'
import ConstellationCanvas from './ConstellationCanvas.vue'

const { theme } = useTheme()
const { background, skinConfig } = useAppearance()
const { triggerAutoType, triggerClearAutoType, triggerRunCommand } = useTerminalBridge()
const isDark = computed(() => theme.value === 'dark')

/* ========================================================================
   Dynamic background component
   ======================================================================== */

const BG_COMPONENTS: Record<string, Component> = {
  'flow-field': FlowFieldCanvas,
  'geometric-drift': GeometricDriftCanvas,
  constellations: ConstellationCanvas,
}

const backgroundComponent = computed(() => BG_COMPONENTS[background.value] ?? FlowFieldCanvas)

/* ========================================================================
   Ripple-blur text reveal
   ======================================================================== */
const entered = ref(false)

onMounted(() => {
  requestAnimationFrame(() => {
    entered.value = true
  })
})
</script>

<template>
  <section class="hero-dj relative flex min-h-screen items-center overflow-hidden">
    <!-- Dynamic background canvas -->
    <component
      :is="backgroundComponent"
      :is-dark="isDark"
      :particle-rgb="skinConfig.particleRgb"
      :fade-light-rgb="skinConfig.fadeLightRgb"
      :fade-dark-rgb="skinConfig.fadeDarkRgb"
    />

    <div class="relative z-10 mx-auto w-full max-w-5xl px-6 lg:px-12">
      <div class="grid items-center gap-10 lg:grid-cols-5">
        <!-- Left: main content — centered on mobile, left-aligned on desktop -->
        <div class="text-center lg:col-span-3 lg:text-left">
          <p :class="['reveal reveal-1 greeting', entered ? 'is-revealed' : '']">Hey, I'm</p>

          <h1 :class="['reveal reveal-2 hero-name', entered ? 'is-revealed' : '']">
            Justin Negron
          </h1>

          <div :class="['reveal reveal-3 role-line mt-3', entered ? 'is-revealed' : '']">
            <span class="role-bracket">&lt;</span>
            <span class="role-text">Software Engineer</span>
            <span class="role-bracket"> /&gt;</span>
          </div>

          <p :class="['reveal reveal-4 desc mt-6 max-w-lg', entered ? 'is-revealed' : '']">
            I build thoughtful web applications with
            <code>Rails</code> and <code>Vue</code>, obsessing over clean architecture, real test
            coverage, and interfaces that actually feel good to use.
          </p>

          <!-- CTAs with hover-to-type (via terminal bridge) -->
          <div
            :class="['reveal reveal-5 mt-8 flex flex-wrap justify-center gap-4 lg:justify-start', entered ? 'is-revealed' : '']"
          >
            <a
              href="/#projects"
              class="cta-primary"
              @click.prevent="triggerRunCommand('projects')"
              @mouseenter="triggerAutoType('projects')"
              @mouseleave="triggerClearAutoType()"
            >
              View Projects
              <svg
                width="16"
                height="16"
                viewBox="0 0 16 16"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
              >
                <line x1="2" y1="8" x2="12" y2="8" />
                <polyline points="8,4 12,8 8,12" />
              </svg>
            </a>
            <a
              href="/#contact"
              class="cta-secondary"
              @click.prevent="triggerRunCommand('contact')"
              @mouseenter="triggerAutoType('contact')"
              @mouseleave="triggerClearAutoType()"
            >
              Get in Touch
            </a>
          </div>
        </div>

        <!-- Right: terminal position reference (FloatingTerminal overlays this).
             Hidden on mobile — terminal starts minimized there; hero is centered. -->
        <div class="hidden lg:col-span-2 lg:block">
          <div id="hero-terminal-slot" class="min-h-[300px] sm:min-h-[320px]" />
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
/* ===================================================================
   Hero base — theme-aware, skin-driven gradients
   =================================================================== */
.hero-dj {
  background: linear-gradient(
    160deg,
    var(--skin-hero-1) 0%,
    var(--skin-hero-2) 50%,
    var(--skin-hero-3) 100%
  );
  color: #292524;
  font-family: 'Bricolage Grotesque', sans-serif;
  transition:
    background 0.4s ease,
    color 0.4s ease;
}

:is(.dark *).hero-dj {
  background: linear-gradient(
    160deg,
    var(--skin-hero-dark-1) 0%,
    var(--skin-hero-dark-2) 50%,
    var(--skin-hero-dark-3) 100%
  );
  color: #e7e5e4;
}

/* ===================================================================
   Linear-style directional blur reveal
   =================================================================== */
.reveal {
  opacity: 0;
  will-change: opacity, filter, transform, clip-path;
}

.reveal.is-revealed {
  animation: sweepReveal 1s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes sweepReveal {
  0% {
    opacity: 0;
    filter: blur(10px);
    transform: translateY(14px);
    clip-path: inset(0 100% 0 0);
  }
  100% {
    opacity: 1;
    filter: blur(0px);
    transform: translateY(0);
    clip-path: inset(-20px);
  }
}

/* Staggered delays */
.reveal-1.is-revealed {
  animation-delay: 0.2s;
  animation-duration: 1.2s;
}
.reveal-2.is-revealed {
  animation-delay: 0.6s;
  animation-duration: 1.4s;
}
.reveal-3.is-revealed {
  animation-delay: 1s;
  animation-duration: 1.2s;
}
.reveal-4.is-revealed {
  animation-delay: 1.5s;
  animation-duration: 1.3s;
}
.reveal-5.is-revealed {
  animation-delay: 2s;
  animation-duration: 1.2s;
}

/* === Typography === */
.greeting {
  font-size: 1.1rem;
  color: #78716c;
  font-weight: 400;
}

:is(.dark *).greeting {
  color: #a8a29e;
}

.hero-name {
  font-size: clamp(2.8rem, 7vw, 4.5rem);
  font-weight: 700;
  line-height: 1.05;
  letter-spacing: -0.025em;
  color: #1c1917;
}

:is(.dark *).hero-name {
  color: #fafaf9;
}

.role-line {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.95rem;
}
.role-bracket {
  color: var(--skin-600);
  font-weight: 400;
}
.role-text {
  color: var(--skin-800);
  font-weight: 600;
}

:is(.dark *).role-bracket {
  color: var(--skin-500);
}

:is(.dark *).role-text {
  color: var(--skin-400);
}

.desc {
  font-size: 1.05rem;
  line-height: 1.7;
  color: #57534e;
}

:is(.dark *).desc {
  color: #a8a29e;
}

.desc code {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.85em;
  background: rgba(var(--skin-rgb), 0.08);
  color: var(--skin-700);
  padding: 2px 8px;
  border-radius: 6px;
  font-weight: 600;
}

:is(.dark *).desc code {
  background: rgba(var(--skin-light-rgb), 0.12);
  color: var(--skin-400);
}

/* === CTAs === */
.cta-primary {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 12px 28px;
  background: linear-gradient(135deg, var(--skin-600), var(--skin-700));
  color: white;
  font-weight: 700;
  font-size: 0.9rem;
  border-radius: 14px;
  box-shadow: 0 4px 16px rgba(var(--skin-rgb), 0.25);
  transition: all 0.2s ease;
}
.cta-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(var(--skin-rgb), 0.3);
}

:is(.dark *).cta-primary {
  background: linear-gradient(135deg, var(--skin-500), var(--skin-600));
  box-shadow: 0 4px 16px rgba(var(--skin-light-rgb), 0.3);
}

:is(.dark *).cta-primary:hover {
  box-shadow: 0 8px 24px rgba(var(--skin-light-rgb), 0.4);
}

.cta-secondary {
  display: inline-flex;
  align-items: center;
  padding: 12px 28px;
  color: var(--skin-800);
  font-weight: 700;
  font-size: 0.9rem;
  border: 2px solid var(--skin-200);
  border-radius: 14px;
  transition: all 0.2s ease;
}
.cta-secondary:hover {
  border-color: var(--skin-500);
  background: rgba(var(--skin-light-rgb), 0.05);
  transform: translateY(-2px);
}

:is(.dark *).cta-secondary {
  color: var(--skin-400);
  border-color: rgba(var(--skin-lighter-rgb), 0.3);
}

:is(.dark *).cta-secondary:hover {
  border-color: rgba(var(--skin-lighter-rgb), 0.5);
  background: rgba(var(--skin-lighter-rgb), 0.08);
}
</style>
