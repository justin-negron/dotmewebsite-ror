<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'

const lines = ref<{ prompt: string; response: string; visible: boolean }[]>([
  { prompt: 'whoami', response: 'justin_negron', visible: false },
  { prompt: 'cat role.txt', response: 'Full-Stack Developer', visible: false },
  {
    prompt: 'cat stack.txt',
    response: 'Rails 7 \u00b7 Vue 3 \u00b7 TypeScript \u00b7 PostgreSQL',
    visible: false,
  },
  {
    prompt: 'cat status.txt',
    response: 'Open to opportunities \u2014 let\u2019s build something.',
    visible: false,
  },
])

const cursorLine = ref(0)
const showPrompt = ref(false)
const showResponse = ref(false)
const typedPrompt = ref('')
const typedResponse = ref('')
const doneTyping = ref(false)
let timeout: ReturnType<typeof setTimeout>

function typeText(text: string, target: typeof typedPrompt, speed: number): Promise<void> {
  return new Promise((resolve) => {
    let i = 0
    const interval = setInterval(() => {
      target.value = text.slice(0, i + 1)
      i++
      if (i >= text.length) {
        clearInterval(interval)
        resolve()
      }
    }, speed)
  })
}

async function runSequence() {
  await new Promise((r) => (timeout = setTimeout(r, 700)))

  for (let i = 0; i < lines.value.length; i++) {
    const line = lines.value[i]
    if (!line) continue
    cursorLine.value = i
    showPrompt.value = true
    typedPrompt.value = ''
    typedResponse.value = ''
    showResponse.value = false

    await typeText(line.prompt, typedPrompt, 55)
    await new Promise((r) => (timeout = setTimeout(r, 280)))

    showResponse.value = true
    await typeText(line.response, typedResponse, 28)
    line.visible = true
    showPrompt.value = false
    showResponse.value = false

    await new Promise((r) => (timeout = setTimeout(r, 350)))
  }

  cursorLine.value = lines.value.length
  showPrompt.value = true
  typedPrompt.value = ''
  doneTyping.value = true
}

onMounted(() => {
  runSequence()
})

onUnmounted(() => {
  clearTimeout(timeout)
})
</script>

<template>
  <section class="hero-wt relative flex min-h-screen items-center justify-center overflow-hidden">
    <!-- Warm ambient blobs on dark -->
    <div class="blob blob-1" />
    <div class="blob blob-2" />
    <div class="blob blob-3" />

    <!-- Subtle grain -->
    <div class="grain" />

    <!-- Content -->
    <div class="relative z-10 mx-auto w-full max-w-3xl px-6">
      <!-- Friendly greeting above terminal -->
      <p
        :class="[
          'greeting mb-6 text-center transition-all duration-700 ease-out',
          doneTyping || cursorLine > 0 ? 'opacity-0 translate-y-2' : 'opacity-70',
        ]"
      >
        Hey, welcome to my corner of the internet.
      </p>

      <!-- Terminal -->
      <div class="terminal">
        <div class="terminal-bar">
          <div class="flex items-center gap-1.5">
            <span class="dot dot-red" />
            <span class="dot dot-yellow" />
            <span class="dot dot-green" />
          </div>
          <span class="terminal-title">justin@dev ~ </span>
          <div class="w-12" />
        </div>

        <div class="terminal-body font-mono text-sm leading-relaxed md:text-base">
          <template v-for="(line, i) in lines" :key="i">
            <div v-if="line.visible" class="flex gap-2">
              <span class="select-none prompt-char">$</span>
              <span class="text-stone-400">{{ line.prompt }}</span>
            </div>
            <div
              v-if="line.visible"
              :class="[
                'ml-5 mb-3',
                i === 0 ? 'response-name' : '',
                i === 1 ? 'response-role' : '',
                i === 2 ? 'response-stack' : '',
                i === 3 ? 'response-status' : '',
              ]"
            >
              {{ line.response }}
            </div>
          </template>

          <div v-if="showPrompt && !doneTyping" class="flex gap-2">
            <span class="select-none prompt-char">$</span>
            <span class="text-stone-400">{{ typedPrompt }}</span>
            <span v-if="!showResponse" class="cursor-blink prompt-char">_</span>
          </div>
          <div v-if="showResponse" class="ml-5 text-stone-500">
            {{ typedResponse }}<span class="cursor-blink prompt-char">_</span>
          </div>

          <div v-if="doneTyping" class="flex gap-2">
            <span class="select-none prompt-char">$</span>
            <span class="cursor-blink prompt-char">_</span>
          </div>
        </div>
      </div>

      <!-- CTAs -->
      <div
        class="mt-8 flex flex-col items-center gap-4 sm:flex-row sm:justify-center"
        :class="{ 'animate-fade-up': doneTyping }"
      >
        <a
          href="/#projects"
          class="cta-primary group inline-flex items-center gap-2 rounded-xl px-7 py-3 text-sm font-semibold text-white transition-all hover:-translate-y-0.5 hover:shadow-xl"
        >
          <span class="font-mono text-amber-200/70">~/</span>projects
          <span class="translate-x-0 transition-transform group-hover:translate-x-1">&rarr;</span>
        </a>
        <a
          href="/#contact"
          class="group inline-flex items-center gap-2 rounded-xl border border-amber-600/20 bg-amber-500/5 px-7 py-3 text-sm font-semibold text-amber-300/80 transition-all hover:border-amber-500/40 hover:bg-amber-500/10"
        >
          <span class="font-mono text-amber-500/50">~/</span>contact
          <span class="translate-x-0 transition-transform group-hover:translate-x-1">&rarr;</span>
        </a>
      </div>

      <!-- Warm tech pills -->
      <div
        class="mt-10 flex flex-wrap justify-center gap-2"
        :class="{ 'animate-fade-up-delay': doneTyping }"
      >
        <span
          v-for="tech in ['Rails', 'Vue', 'TypeScript', 'PostgreSQL', 'Redis']"
          :key="tech"
          class="tech-pill"
        >
          {{ tech }}
        </span>
      </div>
    </div>
  </section>
</template>

<style scoped>
.hero-wt {
  background: #0d0b08;
  color: #e8e0d4;
  font-family: 'Syne', sans-serif;
}

/* === Ambient blobs === */
.blob {
  position: absolute;
  border-radius: 50%;
  filter: blur(100px);
  z-index: 0;
}

.blob-1 {
  width: clamp(300px, 35vw, 500px);
  height: clamp(300px, 35vw, 500px);
  background: rgba(245, 158, 11, 0.06);
  top: -15%;
  right: -10%;
  animation: drift1 10s ease-in-out infinite;
}

.blob-2 {
  width: clamp(250px, 30vw, 450px);
  height: clamp(250px, 30vw, 450px);
  background: rgba(251, 113, 133, 0.04);
  bottom: -10%;
  left: -10%;
  animation: drift2 13s ease-in-out infinite;
}

.blob-3 {
  width: clamp(200px, 20vw, 300px);
  height: clamp(200px, 20vw, 300px);
  background: rgba(217, 119, 6, 0.04);
  top: 50%;
  left: 40%;
  animation: drift3 11s ease-in-out infinite;
}

@keyframes drift1 {
  0%,
  100% {
    transform: translate(0, 0);
  }
  50% {
    transform: translate(-15px, 15px);
  }
}
@keyframes drift2 {
  0%,
  100% {
    transform: translate(0, 0);
  }
  50% {
    transform: translate(18px, -12px);
  }
}
@keyframes drift3 {
  0%,
  100% {
    transform: translate(0, 0);
  }
  50% {
    transform: translate(-10px, -18px);
  }
}

/* === Grain === */
.grain {
  position: absolute;
  inset: 0;
  opacity: 0.3;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.035'/%3E%3C/svg%3E");
  background-size: 200px;
  pointer-events: none;
  z-index: 1;
}

/* === Greeting === */
.greeting {
  font-family: 'Bricolage Grotesque', sans-serif;
  font-size: 1rem;
  color: #a89984;
  transition:
    opacity 0.8s ease,
    transform 0.8s ease;
}

/* === Terminal === */
.terminal {
  background: rgba(18, 15, 10, 0.8);
  border: 1px solid rgba(245, 158, 11, 0.1);
  border-radius: 16px;
  box-shadow:
    0 0 60px rgba(245, 158, 11, 0.04),
    0 25px 50px rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(12px);
  overflow: hidden;
}

.terminal-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  border-bottom: 1px solid rgba(245, 158, 11, 0.06);
  background: rgba(245, 158, 11, 0.02);
}

.dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

.dot-red {
  background: #e85d4a;
}
.dot-yellow {
  background: #e2a93b;
}
.dot-green {
  background: #5db85e;
}

.terminal-title {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.7rem;
  color: rgba(245, 158, 11, 0.3);
}

.terminal-body {
  padding: 1.5rem;
}

.prompt-char {
  color: #d97706;
}

.response-name {
  font-size: 1.15rem;
  font-weight: 700;
  font-family: 'Syne', sans-serif;
  color: #fbbf24;
  text-shadow: 0 0 20px rgba(251, 191, 36, 0.3);
}

.response-role {
  color: #f59e0b;
  font-family: 'Bricolage Grotesque', sans-serif;
  font-weight: 600;
}

.response-stack {
  color: #92722a;
}

.response-status {
  color: #a3e635;
  font-style: italic;
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

/* === CTAs === */
.cta-primary {
  background: linear-gradient(135deg, #d97706, #b45309);
  box-shadow: 0 4px 20px rgba(217, 119, 6, 0.2);
}

/* === Tech pills === */
.tech-pill {
  display: inline-block;
  padding: 4px 14px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.7rem;
  color: #92722a;
  border: 1px solid rgba(245, 158, 11, 0.1);
  border-radius: 999px;
  transition: all 0.2s ease;
}

.tech-pill:hover {
  color: #fbbf24;
  border-color: rgba(251, 191, 36, 0.3);
  background: rgba(251, 191, 36, 0.05);
}

/* === Animations === */
.animate-fade-up {
  animation: fadeUp 0.6s ease-out both;
}
.animate-fade-up-delay {
  animation: fadeUp 0.6s 0.15s ease-out both;
}
@keyframes fadeUp {
  from {
    opacity: 0;
    transform: translateY(12px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
