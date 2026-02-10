<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'

const entered = ref(false)
const cmdText = ref('')
const cmdDone = ref(false)
let timeout: ReturnType<typeof setTimeout>

onMounted(() => {
  requestAnimationFrame(() => {
    entered.value = true
  })

  const fullText = 'ready to build'
  let i = 0
  timeout = setTimeout(function tick() {
    cmdText.value = fullText.slice(0, i + 1)
    i++
    if (i < fullText.length) {
      timeout = setTimeout(tick, 50)
    } else {
      cmdDone.value = true
    }
  }, 2200)
})

onUnmounted(() => {
  clearTimeout(timeout)
})
</script>

<template>
  <section class="hero-nd relative flex min-h-screen flex-col overflow-hidden">
    <!-- Dusk gradient layers -->
    <div class="gradient-base" />
    <div class="gradient-warm" />
    <div class="stars" />

    <!-- Top warm zone -->
    <div class="relative z-10 flex flex-1 flex-col items-center justify-center px-6 pt-20">
      <!-- Greeting -->
      <p
        :class="[
          'greeting text-center transition-all duration-800 ease-out',
          entered ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4',
        ]"
      >
        Hey, I'm
      </p>

      <!-- Name — gradient from warm to cool -->
      <h1
        :class="[
          'hero-name text-center transition-all duration-800 delay-200 ease-out',
          entered ? 'opacity-100 translate-y-0 scale-100' : 'opacity-0 translate-y-6 scale-[0.97]',
        ]"
      >
        Justin Negron
      </h1>

      <!-- Role pill -->
      <div
        :class="[
          'mt-5 transition-all duration-700 delay-400 ease-out',
          entered ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-3',
        ]"
      >
        <span class="role-pill">
          <span class="status-dot" />
          Full-Stack Developer
        </span>
      </div>

      <!-- Description -->
      <p
        :class="[
          'desc mx-auto mt-6 max-w-lg text-center transition-all duration-700 delay-500 ease-out',
          entered ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4',
        ]"
      >
        Building clean, enterprise-grade applications<br class="hidden sm:inline" />
        from database to deployment.
      </p>

      <!-- CTAs -->
      <div
        :class="[
          'mt-8 flex flex-wrap justify-center gap-4 transition-all duration-700 delay-[650ms] ease-out',
          entered ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4',
        ]"
      >
        <a href="/#projects" class="cta-warm">
          View Projects
          <svg
            width="15"
            height="15"
            viewBox="0 0 15 15"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
          >
            <line x1="2" y1="7.5" x2="11" y2="7.5" />
            <polyline points="8,4 11,7.5 8,11" />
          </svg>
        </a>
        <a href="/#contact" class="cta-cool"> Let's Connect </a>
      </div>
    </div>

    <!-- Bottom dark zone — technical identity -->
    <div class="relative z-10 pb-10 pt-14">
      <div class="mx-auto flex max-w-2xl flex-col items-center gap-5 px-6">
        <!-- Terminal line -->
        <div
          :class="[
            'cmd-line transition-all duration-700 delay-[900ms] ease-out',
            entered ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4',
          ]"
        >
          <span class="cmd-prompt">$</span>
          <span class="cmd-label">status</span>
          <span class="cmd-sep">&mdash;</span>
          <span class="cmd-output">{{ cmdText }}</span>
          <span v-if="!cmdDone" class="cursor-blink cmd-cursor">|</span>
        </div>

        <!-- Tech row -->
        <div
          :class="[
            'flex flex-wrap justify-center gap-3 transition-all duration-700 delay-[1100ms] ease-out',
            entered ? 'opacity-100' : 'opacity-0',
          ]"
        >
          <span
            v-for="tech in ['Rails 7', 'Vue 3', 'TypeScript', 'PostgreSQL', 'Redis']"
            :key="tech"
            class="tech-chip"
          >
            {{ tech }}
          </span>
        </div>
      </div>
    </div>

    <!-- Horizon line -->
    <div class="horizon" />
  </section>
</template>

<style scoped>
.hero-nd {
  position: relative;
  color: #fefce8;
  font-family: 'Bricolage Grotesque', sans-serif;
}

/* === Gradient layers === */
.gradient-base {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    180deg,
    #fef3e2 0%,
    #fcd9b6 15%,
    #e8956c 30%,
    #8b3a5e 48%,
    #2d1b4e 62%,
    #0c0f1a 78%,
    #060810 100%
  );
  z-index: 0;
}

.gradient-warm {
  position: absolute;
  inset: 0;
  background:
    radial-gradient(ellipse at 30% 20%, rgba(251, 191, 36, 0.15) 0%, transparent 50%),
    radial-gradient(ellipse at 70% 35%, rgba(244, 114, 82, 0.1) 0%, transparent 40%);
  z-index: 1;
}

.stars {
  position: absolute;
  inset: 0;
  z-index: 2;
  background-image:
    radial-gradient(1px 1px at 15% 75%, rgba(255, 255, 255, 0.4), transparent),
    radial-gradient(1px 1px at 35% 85%, rgba(255, 255, 255, 0.3), transparent),
    radial-gradient(1.5px 1.5px at 55% 70%, rgba(255, 255, 255, 0.5), transparent),
    radial-gradient(1px 1px at 72% 80%, rgba(255, 255, 255, 0.3), transparent),
    radial-gradient(1px 1px at 88% 68%, rgba(255, 255, 255, 0.4), transparent),
    radial-gradient(1px 1px at 25% 90%, rgba(255, 255, 255, 0.2), transparent),
    radial-gradient(1.5px 1.5px at 60% 92%, rgba(255, 255, 255, 0.3), transparent),
    radial-gradient(1px 1px at 82% 95%, rgba(255, 255, 255, 0.35), transparent),
    radial-gradient(1px 1px at 45% 78%, rgba(255, 255, 255, 0.25), transparent),
    radial-gradient(1px 1px at 10% 82%, rgba(255, 255, 255, 0.3), transparent);
  pointer-events: none;
}

/* === Typography === */
.greeting {
  font-size: 1.15rem;
  color: #92400e;
  font-weight: 400;
}

.hero-name {
  font-size: clamp(3rem, 9vw, 6.5rem);
  font-weight: 700;
  line-height: 1;
  letter-spacing: -0.03em;
  background: linear-gradient(
    180deg,
    #78350f 0%,
    #fef3c7 35%,
    #fde68a 50%,
    #a78bfa 75%,
    #c4b5fd 100%
  );
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
}

/* === Role pill === */
.role-pill {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 22px;
  background: rgba(255, 255, 255, 0.12);
  backdrop-filter: blur(8px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 999px;
  font-size: 0.85rem;
  font-weight: 600;
  color: #fef3c7;
}

.status-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #a3e635;
  box-shadow: 0 0 8px rgba(163, 230, 53, 0.5);
  animation: pulse 2s ease-in-out infinite;
}

@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.4;
  }
}

.desc {
  font-size: 1rem;
  line-height: 1.7;
  color: rgba(254, 243, 199, 0.6);
}

/* === CTAs === */
.cta-warm {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 12px 28px;
  background: linear-gradient(135deg, #d97706, #c2410c);
  color: white;
  font-weight: 700;
  font-size: 0.9rem;
  border-radius: 14px;
  box-shadow: 0 4px 20px rgba(217, 119, 6, 0.3);
  transition: all 0.2s ease;
}
.cta-warm:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 30px rgba(217, 119, 6, 0.4);
}

.cta-cool {
  display: inline-flex;
  align-items: center;
  padding: 12px 28px;
  color: #c4b5fd;
  font-weight: 700;
  font-size: 0.9rem;
  border: 1.5px solid rgba(196, 181, 253, 0.25);
  border-radius: 14px;
  transition: all 0.2s ease;
}
.cta-cool:hover {
  border-color: rgba(196, 181, 253, 0.5);
  background: rgba(196, 181, 253, 0.05);
  transform: translateY(-2px);
}

/* === Command line === */
.cmd-line {
  display: flex;
  align-items: center;
  gap: 8px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
}

.cmd-prompt {
  color: #d97706;
  font-weight: 700;
}
.cmd-label {
  color: rgba(255, 255, 255, 0.35);
}
.cmd-sep {
  color: rgba(255, 255, 255, 0.15);
}
.cmd-output {
  color: #a3e635;
}
.cmd-cursor {
  color: #d97706;
}

/* === Tech chips === */
.tech-chip {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.7rem;
  color: rgba(255, 255, 255, 0.3);
  padding: 4px 14px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 999px;
  transition: all 0.2s ease;
}
.tech-chip:hover {
  color: #fbbf24;
  border-color: rgba(251, 191, 36, 0.2);
  background: rgba(251, 191, 36, 0.05);
}

/* === Horizon === */
.horizon {
  position: absolute;
  left: 0;
  right: 0;
  top: 46%;
  height: 1px;
  background: linear-gradient(
    90deg,
    transparent 5%,
    rgba(251, 191, 36, 0.15) 30%,
    rgba(244, 114, 82, 0.2) 50%,
    rgba(139, 92, 246, 0.1) 70%,
    transparent 95%
  );
  z-index: 3;
  pointer-events: none;
}

/* === Cursor === */
.cursor-blink {
  animation: blink 1s step-end infinite;
}
@keyframes blink {
  50% {
    opacity: 0;
  }
}
</style>
