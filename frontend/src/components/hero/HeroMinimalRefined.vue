<script setup lang="ts">
import { ref, onMounted } from 'vue'

const revealed = ref(false)

onMounted(() => {
  requestAnimationFrame(() => {
    revealed.value = true
  })
})
</script>

<template>
  <section
    class="hero-minimal relative flex min-h-screen flex-col items-center justify-center overflow-hidden px-6"
  >
    <!-- Subtle paper texture -->
    <div class="paper-texture" />

    <div class="relative z-10 w-full max-w-6xl">
      <!-- Overline -->
      <p
        :class="[
          'overline mb-6 text-center font-light tracking-[0.35em] uppercase transition-all duration-1000 ease-out',
          revealed ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-3',
        ]"
      >
        Portfolio
      </p>

      <!-- The Name — massive serif -->
      <h1
        :class="[
          'hero-name text-center leading-[0.85] tracking-[-0.04em] transition-all duration-1000 delay-200 ease-out',
          revealed ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-6',
        ]"
      >
        Justin<br />Negron
      </h1>

      <!-- Hairline -->
      <div class="my-8 flex justify-center md:my-10">
        <div
          :class="[
            'hairline h-px bg-current transition-all duration-1000 delay-500 ease-out',
            revealed ? 'w-24 opacity-30' : 'w-0 opacity-0',
          ]"
        />
      </div>

      <!-- Role -->
      <p
        :class="[
          'role text-center text-sm tracking-[0.3em] uppercase transition-all duration-1000 delay-700 ease-out md:text-base',
          revealed ? 'opacity-60 translate-y-0' : 'opacity-0 translate-y-3',
        ]"
      >
        Full-Stack Developer
      </p>

      <!-- Scroll indicator -->
      <div
        :class="[
          'mt-16 flex flex-col items-center gap-2 transition-all duration-1000 delay-1000 ease-out md:mt-24',
          revealed ? 'opacity-40' : 'opacity-0',
        ]"
      >
        <span class="scroll-label text-[10px] tracking-[0.4em] uppercase">Scroll</span>
        <div class="scroll-arrow">
          <svg
            width="16"
            height="24"
            viewBox="0 0 16 24"
            fill="none"
            stroke="currentColor"
            stroke-width="1.5"
          >
            <line x1="8" y1="0" x2="8" y2="20" />
            <polyline points="2,15 8,21 14,15" />
          </svg>
        </div>
      </div>
    </div>

    <!-- Gold accent dot — a single deliberate mark -->
    <div
      :class="[
        'accent-dot absolute transition-all duration-1000 delay-[1200ms] ease-out',
        revealed ? 'opacity-100 scale-100' : 'opacity-0 scale-0',
      ]"
    />
  </section>
</template>

<style scoped>
.hero-minimal {
  background: #faf9f6;
  color: #1a1a1a;
  font-family: 'Outfit', sans-serif;
}

.paper-texture {
  position: absolute;
  inset: 0;
  opacity: 0.4;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)' opacity='0.04'/%3E%3C/svg%3E");
  background-size: 256px;
}

.hero-name {
  font-family: 'Instrument Serif', serif;
  font-size: clamp(4rem, 15vw, 12rem);
  font-weight: 400;
  font-style: italic;
}

.overline {
  font-family: 'Outfit', sans-serif;
  font-size: 0.75rem;
  color: #b5985a;
}

.role {
  font-family: 'Outfit', sans-serif;
  font-weight: 300;
  letter-spacing: 0.3em;
}

.scroll-label {
  font-family: 'Outfit', sans-serif;
  font-weight: 300;
}

.scroll-arrow {
  animation: gentleBounce 2.5s ease-in-out infinite;
}

@keyframes gentleBounce {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(6px);
  }
}

.accent-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #b5985a;
  right: 12%;
  top: 28%;
}

@media (max-width: 768px) {
  .accent-dot {
    display: none;
  }
}
</style>
