<script setup lang="ts">
defineProps<{
  isDark: boolean
}>()

defineEmits<{
  toggle: [event: MouseEvent]
}>()
</script>

<template>
  <button
    type="button"
    class="theme-toggle"
    :class="{ 'is-dark': isDark }"
    :aria-label="isDark ? 'Switch to light mode' : 'Switch to dark mode'"
    role="switch"
    :aria-checked="isDark"
    @click="$emit('toggle', $event)"
  >
    <!-- Track background scenery -->
    <div class="toggle-track">
      <!-- Stars (visible in dark mode) -->
      <div class="stars">
        <span class="star star-1" />
        <span class="star star-2" />
        <span class="star star-3" />
        <span class="star star-4" />
        <span class="star star-5" />
        <span class="star star-6" />
      </div>

      <!-- Cloud (visible in light mode) -->
      <div class="cloud">
        <span class="cloud-puff cloud-1" />
        <span class="cloud-puff cloud-2" />
        <span class="cloud-puff cloud-3" />
      </div>
    </div>

    <!-- Sliding knob with sun/moon -->
    <div class="toggle-knob">
      <!-- Sun rays (visible in light mode) -->
      <div class="sun-rays">
        <span class="ray" />
        <span class="ray" />
        <span class="ray" />
        <span class="ray" />
        <span class="ray" />
        <span class="ray" />
        <span class="ray" />
        <span class="ray" />
      </div>

      <!-- Moon craters (visible in dark mode) -->
      <div class="moon-craters">
        <span class="crater crater-1" />
        <span class="crater crater-2" />
        <span class="crater crater-3" />
      </div>
    </div>
  </button>
</template>

<style scoped>
.theme-toggle {
  position: relative;
  width: 56px;
  height: 28px;
  border: none;
  border-radius: 999px;
  cursor: pointer;
  padding: 0;
  overflow: hidden;
  flex-shrink: 0;
  outline: none;
  transition: box-shadow 0.2s ease;
}

.theme-toggle:focus-visible {
  box-shadow: 0 0 0 2px rgba(14, 165, 233, 0.5);
}

/* === Track === */
.toggle-track {
  position: absolute;
  inset: 0;
  border-radius: 999px;
  background: linear-gradient(135deg, #87ceeb 0%, #60b3e0 50%, #4a9fd4 100%);
  transition: background 0.5s cubic-bezier(0.4, 0, 0.2, 1);
  overflow: hidden;
}

.is-dark .toggle-track {
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
}

/* === Stars === */
.stars {
  position: absolute;
  inset: 0;
  opacity: 0;
  transition: opacity 0.5s ease 0.1s;
}

.is-dark .stars {
  opacity: 1;
}

.star {
  position: absolute;
  width: 2px;
  height: 2px;
  background: white;
  border-radius: 50%;
}

.star-1 {
  top: 6px;
  left: 10px;
  animation: twinkle 2s ease-in-out infinite;
}
.star-2 {
  top: 14px;
  left: 6px;
  width: 1.5px;
  height: 1.5px;
  animation: twinkle 2.5s ease-in-out 0.3s infinite;
}
.star-3 {
  top: 8px;
  left: 18px;
  width: 1.5px;
  height: 1.5px;
  animation: twinkle 1.8s ease-in-out 0.7s infinite;
}
.star-4 {
  top: 18px;
  left: 14px;
  animation: twinkle 2.2s ease-in-out 0.5s infinite;
}
.star-5 {
  top: 5px;
  left: 24px;
  width: 1.5px;
  height: 1.5px;
  animation: twinkle 3s ease-in-out 1s infinite;
}
.star-6 {
  top: 20px;
  left: 22px;
  width: 1px;
  height: 1px;
  animation: twinkle 2.8s ease-in-out 0.2s infinite;
}

@keyframes twinkle {
  0%,
  100% {
    opacity: 1;
    transform: scale(1);
  }
  50% {
    opacity: 0.3;
    transform: scale(0.6);
  }
}

/* === Cloud === */
.cloud {
  position: absolute;
  top: 8px;
  left: 28px;
  opacity: 1;
  transition:
    opacity 0.4s ease,
    transform 0.4s ease;
}

.is-dark .cloud {
  opacity: 0;
  transform: translateX(-4px);
}

.cloud-puff {
  position: absolute;
  background: rgba(255, 255, 255, 0.7);
  border-radius: 50%;
}

.cloud-1 {
  width: 10px;
  height: 6px;
  top: 0;
  left: 0;
  border-radius: 6px;
}

.cloud-2 {
  width: 8px;
  height: 5px;
  top: -2px;
  left: 4px;
  border-radius: 5px;
}

.cloud-3 {
  width: 7px;
  height: 4px;
  top: 1px;
  left: 8px;
  border-radius: 4px;
}

/* === Knob === */
.toggle-knob {
  position: absolute;
  top: 3px;
  left: 3px;
  width: 22px;
  height: 22px;
  border-radius: 50%;
  background: linear-gradient(135deg, #ffd700 0%, #ffb300 100%);
  box-shadow:
    0 0 8px rgba(255, 183, 0, 0.4),
    inset 0 -1px 2px rgba(0, 0, 0, 0.1);
  transition:
    transform 0.5s cubic-bezier(0.4, 0, 0.2, 1),
    background 0.5s cubic-bezier(0.4, 0, 0.2, 1),
    box-shadow 0.5s cubic-bezier(0.4, 0, 0.2, 1);
  z-index: 2;
  overflow: hidden;
}

.is-dark .toggle-knob {
  transform: translateX(28px);
  background: linear-gradient(135deg, #e0e0e0 0%, #c8c8c8 100%);
  box-shadow:
    0 0 10px rgba(200, 200, 200, 0.2),
    inset 0 -1px 2px rgba(0, 0, 0, 0.15);
}

/* === Sun Rays === */
.sun-rays {
  position: absolute;
  inset: -4px;
  transition:
    opacity 0.3s ease,
    transform 0.5s ease;
}

.is-dark .sun-rays {
  opacity: 0;
  transform: scale(0) rotate(45deg);
}

.ray {
  position: absolute;
  width: 2px;
  height: 4px;
  background: #ffd700;
  border-radius: 1px;
  left: 50%;
  top: 50%;
  transform-origin: center center;
}

.ray:nth-child(1) {
  transform: translate(-50%, -50%) rotate(0deg) translateY(-13px);
}
.ray:nth-child(2) {
  transform: translate(-50%, -50%) rotate(45deg) translateY(-13px);
}
.ray:nth-child(3) {
  transform: translate(-50%, -50%) rotate(90deg) translateY(-13px);
}
.ray:nth-child(4) {
  transform: translate(-50%, -50%) rotate(135deg) translateY(-13px);
}
.ray:nth-child(5) {
  transform: translate(-50%, -50%) rotate(180deg) translateY(-13px);
}
.ray:nth-child(6) {
  transform: translate(-50%, -50%) rotate(225deg) translateY(-13px);
}
.ray:nth-child(7) {
  transform: translate(-50%, -50%) rotate(270deg) translateY(-13px);
}
.ray:nth-child(8) {
  transform: translate(-50%, -50%) rotate(315deg) translateY(-13px);
}

/* === Moon Craters === */
.moon-craters {
  position: absolute;
  inset: 0;
  opacity: 0;
  transition: opacity 0.4s ease 0.15s;
}

.is-dark .moon-craters {
  opacity: 1;
}

.crater {
  position: absolute;
  border-radius: 50%;
  background: rgba(0, 0, 0, 0.08);
  box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.1);
}

.crater-1 {
  width: 5px;
  height: 5px;
  top: 5px;
  left: 5px;
}

.crater-2 {
  width: 3px;
  height: 3px;
  top: 12px;
  left: 10px;
}

.crater-3 {
  width: 4px;
  height: 4px;
  top: 4px;
  left: 13px;
}
</style>
