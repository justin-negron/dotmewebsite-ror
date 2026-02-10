<script setup lang="ts">
import { ref, onMounted } from 'vue'

const entered = ref(false)

onMounted(() => {
  requestAnimationFrame(() => {
    entered.value = true
  })
})
</script>

<template>
  <section class="hero-warm relative flex min-h-screen items-center overflow-hidden">
    <!-- Gradient blobs -->
    <div class="blob blob-1" />
    <div class="blob blob-2" />
    <div class="blob blob-3" />

    <!-- Content -->
    <div class="relative z-10 mx-auto w-full max-w-4xl px-6 text-center">
      <!-- Greeting -->
      <p
        :class="[
          'greeting mb-4 text-lg transition-all duration-700 ease-out md:text-xl',
          entered ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4',
        ]"
      >
        Hey there, I'm
      </p>

      <!-- Name -->
      <h1
        :class="[
          'hero-name mb-4 transition-all duration-700 delay-150 ease-out',
          entered ? 'opacity-100 translate-y-0 scale-100' : 'opacity-0 translate-y-6 scale-95',
        ]"
      >
        Justin Negron
      </h1>

      <!-- Role pill -->
      <div
        :class="[
          'mb-8 flex justify-center transition-all duration-700 delay-300 ease-out',
          entered ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4',
        ]"
      >
        <span class="role-pill">
          <span class="role-dot" />
          Full-Stack Developer
        </span>
      </div>

      <!-- Description -->
      <p
        :class="[
          'mx-auto mb-10 max-w-xl text-lg leading-relaxed transition-all duration-700 delay-500 ease-out md:text-xl',
          entered ? 'opacity-80 translate-y-0' : 'opacity-0 translate-y-4',
        ]"
        style="color: #475569"
      >
        I build clean, thoughtful web applications with
        <span class="highlight">Rails</span>, <span class="highlight">Vue</span>, and a lot of
        <span class="highlight-alt">curiosity</span>.
      </p>

      <!-- CTAs -->
      <div
        :class="[
          'flex flex-col items-center gap-4 sm:flex-row sm:justify-center transition-all duration-700 delay-700 ease-out',
          entered ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4',
        ]"
      >
        <a
          href="/#projects"
          class="cta-warm inline-flex items-center gap-2 rounded-2xl px-8 py-4 text-base font-bold text-white shadow-lg transition-all hover:-translate-y-0.5 hover:shadow-xl"
        >
          See My Work
          <svg
            width="18"
            height="18"
            viewBox="0 0 18 18"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
          >
            <line x1="3" y1="9" x2="14" y2="9" />
            <polyline points="10,5 14,9 10,13" />
          </svg>
        </a>
        <a
          href="/#contact"
          class="inline-flex items-center gap-2 rounded-2xl border-2 border-slate-200 px-8 py-4 text-base font-bold text-slate-600 transition-all hover:-translate-y-0.5 hover:border-orange-300 hover:text-orange-600"
        >
          Let's Chat
        </a>
      </div>

      <!-- Tech badges -->
      <div
        :class="[
          'mt-14 flex flex-wrap justify-center gap-3 transition-all duration-700 delay-[900ms] ease-out',
          entered ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4',
        ]"
      >
        <span
          v-for="tech in ['Rails 7', 'Vue 3', 'TypeScript', 'PostgreSQL', 'Tailwind']"
          :key="tech"
          class="tech-badge"
        >
          {{ tech }}
        </span>
      </div>
    </div>

    <!-- Wave divider -->
    <div class="absolute bottom-0 left-0 right-0 z-10">
      <svg viewBox="0 0 1440 100" fill="none" xmlns="http://www.w3.org/2000/svg" class="wave-svg">
        <path d="M0 40C240 80 480 10 720 50C960 90 1200 20 1440 60V100H0V40Z" fill="#f9fafb" />
      </svg>
    </div>
  </section>
</template>

<style scoped>
.hero-warm {
  background: linear-gradient(145deg, #fff8f0 0%, #fff0e6 40%, #fce7f3 100%);
  color: #1e293b;
  font-family: 'Bricolage Grotesque', sans-serif;
}

/* === Blobs === */
.blob {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  z-index: 0;
}

.blob-1 {
  width: clamp(300px, 40vw, 600px);
  height: clamp(300px, 40vw, 600px);
  background: rgba(249, 115, 22, 0.12);
  top: -10%;
  right: -5%;
  animation: blobFloat1 8s ease-in-out infinite;
}

.blob-2 {
  width: clamp(250px, 35vw, 500px);
  height: clamp(250px, 35vw, 500px);
  background: rgba(251, 113, 133, 0.1);
  bottom: 5%;
  left: -10%;
  animation: blobFloat2 10s ease-in-out infinite;
}

.blob-3 {
  width: clamp(200px, 25vw, 350px);
  height: clamp(200px, 25vw, 350px);
  background: rgba(56, 189, 248, 0.08);
  top: 40%;
  left: 50%;
  animation: blobFloat3 12s ease-in-out infinite;
}

@keyframes blobFloat1 {
  0%,
  100% {
    transform: translate(0, 0);
  }
  50% {
    transform: translate(-20px, 20px);
  }
}

@keyframes blobFloat2 {
  0%,
  100% {
    transform: translate(0, 0);
  }
  50% {
    transform: translate(20px, -15px);
  }
}

@keyframes blobFloat3 {
  0%,
  100% {
    transform: translate(0, 0);
  }
  50% {
    transform: translate(-15px, -20px);
  }
}

/* === Typography === */
.greeting {
  font-family: 'Nunito', 'Bricolage Grotesque', sans-serif;
  font-weight: 400;
  color: #64748b;
}

.hero-name {
  font-size: clamp(3rem, 9vw, 6rem);
  font-weight: 700;
  line-height: 1.05;
  letter-spacing: -0.02em;
  background: linear-gradient(135deg, #1e293b 0%, #f97316 100%);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
}

/* === Pill === */
.role-pill {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 20px;
  background: white;
  border-radius: 999px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
  font-size: 0.875rem;
  font-weight: 600;
  color: #475569;
}

.role-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #22c55e;
  animation: dotPulse 2s ease-in-out infinite;
}

@keyframes dotPulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.4;
  }
}

/* === Highlights === */
.highlight {
  color: #f97316;
  font-weight: 700;
}

.highlight-alt {
  color: #fb7185;
  font-weight: 700;
}

/* === CTA === */
.cta-warm {
  background: linear-gradient(135deg, #f97316 0%, #fb7185 100%);
}

/* === Tech badges === */
.tech-badge {
  display: inline-block;
  padding: 6px 16px;
  background: white;
  border: 1px solid #f1f5f9;
  border-radius: 999px;
  font-size: 0.8rem;
  font-weight: 600;
  color: #64748b;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.04);
  transition: all 0.2s ease;
}

.tech-badge:hover {
  border-color: #fed7aa;
  color: #f97316;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(249, 115, 22, 0.1);
}

/* === Wave === */
.wave-svg {
  display: block;
  width: 100%;
  height: auto;
}
</style>
