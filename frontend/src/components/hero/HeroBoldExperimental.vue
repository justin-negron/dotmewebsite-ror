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
  <section class="hero-bold relative flex min-h-screen items-center overflow-hidden">
    <!-- Floating shapes -->
    <div
      :class="[
        'shape shape-circle transition-all duration-1000 ease-out',
        entered ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-10',
      ]"
    />
    <div
      :class="[
        'shape shape-rect transition-all duration-1000 delay-200 ease-out',
        entered ? 'opacity-100 translate-x-0' : 'opacity-0 translate-x-10',
      ]"
    />
    <div
      :class="[
        'shape shape-triangle transition-all duration-1000 delay-300 ease-out',
        entered ? 'opacity-100 translate-y-0' : 'opacity-0 -translate-y-10',
      ]"
    />
    <div
      :class="[
        'shape shape-ring transition-all duration-1000 delay-500 ease-out',
        entered ? 'opacity-100 scale-100' : 'opacity-0 scale-50',
      ]"
    />
    <div
      :class="[
        'shape shape-dot-grid transition-all duration-1000 delay-700 ease-out',
        entered ? 'opacity-100' : 'opacity-0',
      ]"
    />

    <!-- Content -->
    <div class="relative z-10 mx-auto w-full max-w-7xl px-6 py-20 lg:px-12">
      <div class="grid items-center gap-8 lg:grid-cols-12">
        <!-- Name block — takes up most of the space -->
        <div class="lg:col-span-8">
          <!-- Overline stripe -->
          <div
            :class="[
              'mb-6 inline-block bg-yellow-400 px-4 py-1 transition-all duration-700 delay-100',
              entered ? 'opacity-100 translate-x-0' : 'opacity-0 -translate-x-8',
            ]"
          >
            <span class="stripe-label text-xs font-bold uppercase tracking-widest text-slate-900">
              Full-Stack Developer
            </span>
          </div>

          <!-- Name — massive, stacked, rotated -->
          <div class="name-stack">
            <h1
              :class="[
                'name-line transition-all duration-700 delay-200 ease-out',
                entered ? 'opacity-100 translate-x-0' : 'opacity-0 -translate-x-12',
              ]"
            >
              Justin
            </h1>
            <h1
              :class="[
                'name-line name-line-accent transition-all duration-700 delay-400 ease-out',
                entered ? 'opacity-100 translate-x-0' : 'opacity-0 translate-x-12',
              ]"
            >
              Negron
            </h1>
          </div>
        </div>

        <!-- Right side — vertical text + CTAs -->
        <div class="flex flex-col items-start gap-8 lg:col-span-4 lg:items-end">
          <!-- Vertical tagline (desktop) -->
          <p
            :class="[
              'vertical-text hidden text-sm tracking-widest uppercase lg:block transition-all duration-700 delay-700',
              entered ? 'opacity-50' : 'opacity-0',
            ]"
          >
            Rails &middot; Vue &middot; TypeScript
          </p>

          <!-- CTAs -->
          <div
            :class="[
              'flex flex-wrap gap-4 transition-all duration-700 delay-[800ms]',
              entered ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-6',
            ]"
          >
            <a
              href="/#projects"
              class="cta-bold inline-flex items-center gap-2 rounded-full bg-coral px-7 py-3 text-sm font-bold uppercase tracking-wider text-white transition-all hover:scale-105 hover:shadow-xl"
            >
              View Work
              <svg
                width="14"
                height="14"
                viewBox="0 0 14 14"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
              >
                <line x1="0" y1="7" x2="11" y2="7" />
                <polyline points="7,3 11,7 7,11" />
              </svg>
            </a>
            <a
              href="/#contact"
              class="inline-flex items-center gap-2 rounded-full border-2 border-white/30 px-7 py-3 text-sm font-bold uppercase tracking-wider text-white transition-all hover:border-white/70 hover:bg-white/10"
            >
              Say Hello
            </a>
          </div>
        </div>
      </div>
    </div>

    <!-- Diagonal stripe accent at bottom -->
    <div class="stripe-bottom" />
  </section>
</template>

<style scoped>
.hero-bold {
  background: #0f172a;
  color: #ffffff;
  font-family: 'Unbounded', sans-serif;
}

/* === Shapes === */
.shape {
  position: absolute;
  z-index: 1;
}

.shape-circle {
  width: clamp(180px, 25vw, 350px);
  height: clamp(180px, 25vw, 350px);
  border-radius: 50%;
  background: #ff6b6b;
  top: 8%;
  right: 5%;
  opacity: 0.85;
}

.shape-rect {
  width: clamp(120px, 15vw, 200px);
  height: clamp(120px, 15vw, 200px);
  background: #fbbf24;
  bottom: 15%;
  left: 8%;
  transform: rotate(-12deg);
  border-radius: 6px;
  opacity: 0.8;
}

.shape-triangle {
  width: 0;
  height: 0;
  border-left: clamp(50px, 8vw, 100px) solid transparent;
  border-right: clamp(50px, 8vw, 100px) solid transparent;
  border-bottom: clamp(90px, 14vw, 180px) solid #38bdf8;
  top: 55%;
  right: 22%;
  opacity: 0.7;
}

.shape-ring {
  width: clamp(100px, 12vw, 180px);
  height: clamp(100px, 12vw, 180px);
  border-radius: 50%;
  border: clamp(6px, 1vw, 12px) solid #a78bfa;
  bottom: 25%;
  right: 40%;
  opacity: 0.5;
}

.shape-dot-grid {
  top: 20%;
  left: 3%;
  width: 100px;
  height: 100px;
  background-image: radial-gradient(circle, rgba(255, 255, 255, 0.25) 1.5px, transparent 1.5px);
  background-size: 16px 16px;
}

/* === Name === */
.name-stack {
  position: relative;
}

.name-line {
  font-size: clamp(3.5rem, 11vw, 10rem);
  font-weight: 900;
  line-height: 0.9;
  letter-spacing: -0.03em;
  text-transform: uppercase;
}

.name-line-accent {
  color: transparent;
  -webkit-text-stroke: 2px #ff6b6b;
  margin-left: clamp(1rem, 4vw, 4rem);
}

.stripe-label {
  font-family: 'Outfit', sans-serif;
}

.bg-coral {
  background: #ff6b6b;
}

/* === Vertical Text === */
.vertical-text {
  writing-mode: vertical-rl;
  text-orientation: mixed;
  font-family: 'Outfit', sans-serif;
  font-weight: 300;
}

/* === Bottom stripe === */
.stripe-bottom {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 6px;
  background: repeating-linear-gradient(
    90deg,
    #ff6b6b 0px,
    #ff6b6b 25%,
    #fbbf24 25%,
    #fbbf24 50%,
    #38bdf8 50%,
    #38bdf8 75%,
    #a78bfa 75%,
    #a78bfa 100%
  );
}

@media (max-width: 1024px) {
  .shape-circle {
    width: 140px;
    height: 140px;
    top: 3%;
    right: -20px;
  }

  .shape-rect {
    width: 80px;
    height: 80px;
    bottom: 8%;
    left: -10px;
  }

  .shape-triangle {
    display: none;
  }

  .shape-ring {
    width: 70px;
    height: 70px;
    bottom: 10%;
    right: 10%;
  }
}
</style>
