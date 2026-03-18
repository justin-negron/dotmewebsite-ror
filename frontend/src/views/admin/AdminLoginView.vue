<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const email = ref('')
const password = ref('')
const showPassword = ref(false)
const entered = ref(false)

onMounted(() => {
  requestAnimationFrame(() => {
    entered.value = true
  })
})

async function handleLogin() {
  try {
    await authStore.login(email.value, password.value)
    const redirect = (route.query.redirect as string) || '/admin'
    router.push(redirect)
  } catch {
    // Error is in authStore.error — displayed in template
  }
}

function handleKeydown(e: KeyboardEvent) {
  if (e.key === 'Enter') {
    handleLogin()
  }
}
</script>

<template>
  <div class="login-page">
    <div :class="['login-card', entered ? 'is-revealed' : '']">
      <!-- Terminal-style header -->
      <div class="card-header">
        <div class="dots">
          <span class="dot dot-red" />
          <span class="dot dot-yellow" />
          <span class="dot dot-green" />
        </div>
        <span class="header-title">admin@justinnegron.dev</span>
      </div>

      <!-- Terminal content -->
      <div class="card-body">
        <p class="prompt-line">
          <span class="prompt">~$</span>
          <span class="prompt-text">ssh admin@justinnegron.dev</span>
        </p>

        <div class="mt-6">
          <!-- Error -->
          <div v-if="authStore.error" class="error-block" @click="authStore.clearError()">
            <span class="error-prefix">error:</span> {{ authStore.error.message }}
          </div>

          <!-- Email -->
          <label class="field-label">
            <span class="label-prompt">email:</span>
            <input
              v-model="email"
              type="email"
              autocomplete="email"
              spellcheck="false"
              class="field-input"
              placeholder="admin@justinnegron.dev"
              @keydown="handleKeydown"
            />
          </label>

          <!-- Password -->
          <label class="field-label mt-4">
            <span class="label-prompt">password:</span>
            <div class="password-row">
              <input
                v-model="password"
                :type="showPassword ? 'text' : 'password'"
                autocomplete="current-password"
                class="field-input"
                placeholder="••••••••••••"
                @keydown="handleKeydown"
              />
              <button
                type="button"
                class="toggle-pw"
                :aria-label="showPassword ? 'Hide password' : 'Show password'"
                @click="showPassword = !showPassword"
              >
                {{ showPassword ? 'hide' : 'show' }}
              </button>
            </div>
          </label>

          <!-- Submit -->
          <button
            class="login-btn mt-6"
            :disabled="authStore.loading || !email || !password"
            @click="handleLogin"
          >
            <span v-if="authStore.loading" class="loading-dots">authenticating...</span>
            <span v-else>
              <span class="btn-prompt">~$</span> login
            </span>
          </button>
        </div>

        <p class="footer-hint mt-6">
          <span class="hint-dim">Press</span> Enter
          <span class="hint-dim">to authenticate</span>
        </p>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* ===================================================================
   Page layout
   =================================================================== */
.login-page {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  padding: 1.5rem;
  background: linear-gradient(
    160deg,
    var(--skin-hero-1) 0%,
    var(--skin-hero-2) 50%,
    var(--skin-hero-3) 100%
  );
  transition: background 0.4s ease;
}

:is(.dark *).login-page {
  background: linear-gradient(
    160deg,
    var(--skin-hero-dark-1) 0%,
    var(--skin-hero-dark-2) 50%,
    var(--skin-hero-dark-3) 100%
  );
}

/* ===================================================================
   Card
   =================================================================== */
.login-card {
  width: 100%;
  max-width: 440px;
  border-radius: 14px;
  overflow: hidden;
  background: #ffffff;
  border: 1px solid #e7e5e4;
  box-shadow:
    0 4px 24px rgba(0, 0, 0, 0.06),
    0 12px 48px rgba(0, 0, 0, 0.04);
  opacity: 0;
  transform: translateY(20px);
  transition:
    opacity 0.8s cubic-bezier(0.16, 1, 0.3, 1),
    transform 0.8s cubic-bezier(0.16, 1, 0.3, 1),
    background 0.3s ease,
    border-color 0.3s ease;
}

.login-card.is-revealed {
  opacity: 1;
  transform: translateY(0);
}

:is(.dark *).login-card {
  background: #1c1917;
  border-color: rgba(var(--skin-light-rgb), 0.08);
  box-shadow:
    0 4px 24px rgba(0, 0, 0, 0.2),
    0 12px 48px rgba(0, 0, 0, 0.15);
}

/* ===================================================================
   Header — terminal window chrome
   =================================================================== */
.card-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  background: #f5f5f4;
  border-bottom: 1px solid #e7e5e4;
  transition:
    background 0.3s ease,
    border-color 0.3s ease;
}

:is(.dark *).card-header {
  background: rgba(var(--skin-light-rgb), 0.03);
  border-color: rgba(var(--skin-light-rgb), 0.06);
}

.dots {
  display: flex;
  gap: 6px;
}

.dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

.dot-red {
  background: #ef4444;
}
.dot-yellow {
  background: #eab308;
}
.dot-green {
  background: #22c55e;
}

.header-title {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem;
  color: #78716c;
  font-weight: 500;
}

:is(.dark *).header-title {
  color: #a8a29e;
}

/* ===================================================================
   Body
   =================================================================== */
.card-body {
  padding: 1.5rem;
}

.prompt-line {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.85rem;
  display: flex;
  gap: 0.5rem;
}

.prompt {
  color: var(--skin-600);
  font-weight: 600;
}

:is(.dark *).prompt {
  color: var(--skin-400);
}

.prompt-text {
  color: #44403c;
}

:is(.dark *).prompt-text {
  color: #a8a29e;
}

/* ===================================================================
   Error
   =================================================================== */
.error-block {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
  padding: 0.6rem 0.8rem;
  margin-bottom: 1.25rem;
  border-radius: 8px;
  background: rgba(239, 68, 68, 0.06);
  border: 1px solid rgba(239, 68, 68, 0.15);
  color: #dc2626;
  cursor: pointer;
  transition:
    background 0.2s ease,
    border-color 0.2s ease;
}

:is(.dark *).error-block {
  background: rgba(239, 68, 68, 0.08);
  border-color: rgba(239, 68, 68, 0.2);
  color: #f87171;
}

.error-prefix {
  font-weight: 700;
}

/* ===================================================================
   Fields
   =================================================================== */
.field-label {
  display: block;
}

.label-prompt {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--skin-600);
  margin-bottom: 0.35rem;
  display: block;
}

:is(.dark *).label-prompt {
  color: var(--skin-400);
}

.field-input {
  width: 100%;
  padding: 0.6rem 0.75rem;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.85rem;
  color: #1c1917;
  background: #fafaf9;
  border: 1.5px solid #e7e5e4;
  border-radius: 8px;
  outline: none;
  transition:
    border-color 0.2s ease,
    background 0.2s ease,
    box-shadow 0.2s ease;
}

.field-input::placeholder {
  color: #a8a29e;
}

.field-input:focus {
  border-color: var(--skin-400);
  box-shadow: 0 0 0 3px rgba(var(--skin-rgb), 0.08);
}

:is(.dark *).field-input {
  color: #e7e5e4;
  background: rgba(var(--skin-light-rgb), 0.03);
  border-color: rgba(var(--skin-light-rgb), 0.1);
}

:is(.dark *).field-input::placeholder {
  color: #57534e;
}

:is(.dark *).field-input:focus {
  border-color: var(--skin-500);
  box-shadow: 0 0 0 3px rgba(var(--skin-light-rgb), 0.06);
}

.password-row {
  position: relative;
}

.password-row .field-input {
  padding-right: 3.5rem;
}

.toggle-pw {
  position: absolute;
  right: 0.6rem;
  top: 50%;
  transform: translateY(-50%);
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.7rem;
  font-weight: 600;
  color: var(--skin-500);
  background: none;
  border: none;
  cursor: pointer;
  padding: 0.2rem 0.3rem;
  border-radius: 4px;
  transition:
    color 0.2s ease,
    background 0.2s ease;
}

.toggle-pw:hover {
  color: var(--skin-700);
  background: rgba(var(--skin-rgb), 0.06);
}

:is(.dark *).toggle-pw {
  color: var(--skin-400);
}

:is(.dark *).toggle-pw:hover {
  color: var(--skin-300);
  background: rgba(var(--skin-light-rgb), 0.08);
}

/* ===================================================================
   Login button
   =================================================================== */
.login-btn {
  width: 100%;
  padding: 0.7rem 1rem;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.85rem;
  font-weight: 600;
  color: white;
  background: linear-gradient(135deg, var(--skin-600), var(--skin-700));
  border: none;
  border-radius: 10px;
  cursor: pointer;
  box-shadow: 0 2px 12px rgba(var(--skin-rgb), 0.2);
  transition: all 0.2s ease;
}

.login-btn:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 4px 16px rgba(var(--skin-rgb), 0.3);
}

.login-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

:is(.dark *).login-btn {
  background: linear-gradient(135deg, var(--skin-500), var(--skin-600));
  box-shadow: 0 2px 12px rgba(var(--skin-light-rgb), 0.2);
}

:is(.dark *).login-btn:hover:not(:disabled) {
  box-shadow: 0 4px 16px rgba(var(--skin-light-rgb), 0.3);
}

.btn-prompt {
  opacity: 0.7;
}

.loading-dots {
  animation: blink 1.2s steps(1) infinite;
}

@keyframes blink {
  50% {
    opacity: 0.4;
  }
}

/* ===================================================================
   Footer hint
   =================================================================== */
.footer-hint {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem;
  text-align: center;
  color: #78716c;
}

:is(.dark *).footer-hint {
  color: #57534e;
}

.hint-dim {
  opacity: 0.6;
}
</style>
