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
  { prompt: 'cat mission.txt', response: 'Building things that matter.', visible: false },
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
  await new Promise((r) => (timeout = setTimeout(r, 600)))

  for (let i = 0; i < lines.value.length; i++) {
    const line = lines.value[i]
    if (!line) continue
    cursorLine.value = i
    showPrompt.value = true
    typedPrompt.value = ''
    typedResponse.value = ''
    showResponse.value = false

    await typeText(line.prompt, typedPrompt, 50)
    await new Promise((r) => (timeout = setTimeout(r, 300)))

    showResponse.value = true
    await typeText(line.response, typedResponse, 30)
    line.visible = true
    showPrompt.value = false
    showResponse.value = false

    await new Promise((r) => (timeout = setTimeout(r, 400)))
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
  <section class="hero-dark relative flex min-h-screen items-center justify-center overflow-hidden">
    <!-- Grid background -->
    <div class="grid-bg" />

    <!-- Scanline overlay -->
    <div class="scanlines" />

    <!-- Content -->
    <div class="relative z-10 mx-auto w-full max-w-3xl px-6">
      <!-- Terminal window -->
      <div class="terminal">
        <!-- Window chrome -->
        <div class="flex items-center gap-2 border-b border-cyan-900/40 px-4 py-3">
          <span class="h-3 w-3 rounded-full bg-red-500/80" />
          <span class="h-3 w-3 rounded-full bg-yellow-500/80" />
          <span class="h-3 w-3 rounded-full bg-green-500/80" />
          <span class="ml-4 font-mono text-xs text-cyan-600/60">justin@portfolio ~ </span>
        </div>

        <!-- Terminal body -->
        <div class="space-y-1 p-6 font-mono text-sm leading-relaxed md:text-base">
          <!-- Completed lines -->
          <template v-for="(line, i) in lines" :key="i">
            <div v-if="line.visible" class="flex gap-2">
              <span class="select-none text-cyan-500">$</span>
              <span class="text-gray-300">{{ line.prompt }}</span>
            </div>
            <div
              v-if="line.visible"
              :class="[
                'ml-5 mb-2',
                i === 0 ? 'text-glow-cyan text-lg font-bold md:text-xl' : '',
                i === 1 ? 'text-glow-purple text-purple-400' : '',
                i === 2 ? 'text-cyan-300/70' : '',
                i === 3 ? 'text-emerald-400 italic' : '',
              ]"
            >
              {{ line.response }}
            </div>
          </template>

          <!-- Currently typing line -->
          <div v-if="showPrompt && !doneTyping" class="flex gap-2">
            <span class="select-none text-cyan-500">$</span>
            <span class="text-gray-300">{{ typedPrompt }}</span>
            <span v-if="!showResponse" class="cursor-blink text-cyan-400">_</span>
          </div>
          <div v-if="showResponse" class="ml-5 text-gray-400">
            {{ typedResponse }}<span class="cursor-blink text-cyan-400">_</span>
          </div>

          <!-- Final blinking cursor -->
          <div v-if="doneTyping" class="flex gap-2">
            <span class="select-none text-cyan-500">$</span>
            <span class="cursor-blink text-cyan-400">_</span>
          </div>
        </div>
      </div>

      <!-- CTAs below terminal -->
      <div
        class="mt-8 flex flex-col items-center gap-4 sm:flex-row sm:justify-center"
        :class="{ 'animate-fade-up': doneTyping }"
      >
        <a
          href="/#projects"
          class="group flex items-center gap-2 rounded-lg border border-cyan-500/30 bg-cyan-500/10 px-6 py-3 font-mono text-sm text-cyan-400 transition-all hover:border-cyan-400/60 hover:bg-cyan-500/20 hover:shadow-[0_0_20px_rgba(0,229,255,0.15)]"
        >
          <span class="text-cyan-600">~/</span>projects
          <span class="translate-x-0 transition-transform group-hover:translate-x-1">&rarr;</span>
        </a>
        <a
          href="/#contact"
          class="group flex items-center gap-2 rounded-lg border border-purple-500/30 bg-purple-500/10 px-6 py-3 font-mono text-sm text-purple-400 transition-all hover:border-purple-400/60 hover:bg-purple-500/20 hover:shadow-[0_0_20px_rgba(139,92,246,0.15)]"
        >
          <span class="text-purple-600">~/</span>contact
          <span class="translate-x-0 transition-transform group-hover:translate-x-1">&rarr;</span>
        </a>
      </div>
    </div>
  </section>
</template>

<style scoped>
.hero-dark {
  background: #06060e;
  font-family: 'Syne', sans-serif;
}

.grid-bg {
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(rgba(0, 229, 255, 0.03) 1px, transparent 1px),
    linear-gradient(90deg, rgba(0, 229, 255, 0.03) 1px, transparent 1px);
  background-size: 60px 60px;
}

.scanlines {
  position: absolute;
  inset: 0;
  background: repeating-linear-gradient(
    0deg,
    transparent,
    transparent 2px,
    rgba(0, 0, 0, 0.15) 2px,
    rgba(0, 0, 0, 0.15) 4px
  );
  pointer-events: none;
  z-index: 5;
}

.terminal {
  background: rgba(6, 6, 14, 0.85);
  border: 1px solid rgba(0, 229, 255, 0.12);
  border-radius: 12px;
  box-shadow:
    0 0 40px rgba(0, 229, 255, 0.05),
    0 20px 60px rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(10px);
}

.text-glow-cyan {
  color: #00e5ff;
  text-shadow:
    0 0 10px rgba(0, 229, 255, 0.5),
    0 0 40px rgba(0, 229, 255, 0.2);
}

.text-glow-purple {
  text-shadow:
    0 0 10px rgba(139, 92, 246, 0.5),
    0 0 40px rgba(139, 92, 246, 0.2);
}

.cursor-blink {
  animation: blink 1s step-end infinite;
}

@keyframes blink {
  50% {
    opacity: 0;
  }
}

.animate-fade-up {
  animation: fadeUp 0.6s ease-out both;
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
