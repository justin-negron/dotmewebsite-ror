<script setup lang="ts">
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import { useContactStore, useUiStore } from '@/stores'
import type { ContactFormData } from '@/types'

const contactStore = useContactStore()
const uiStore = useUiStore()
const sectionRef = ref<HTMLElement | null>(null)
const hasRevealed = ref(false)
const focusedField = ref<string | null>(null)
let observer: IntersectionObserver | null = null

const form = reactive<ContactFormData>({
  name: '',
  email: '',
  subject: '',
  message: '',
})

const errors = reactive<Record<string, string>>({
  name: '',
  email: '',
  message: '',
})

const isFormValid = computed(() => {
  return form.name.trim() !== '' && isValidEmail(form.email) && form.message.trim().length >= 10
})

function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}

function validateField(field: string) {
  switch (field) {
    case 'name':
      errors.name = form.name.trim() === '' ? 'Name is required' : ''
      break
    case 'email':
      if (form.email.trim() === '') {
        errors.email = 'Email is required'
      } else if (!isValidEmail(form.email)) {
        errors.email = 'Invalid email format'
      } else {
        errors.email = ''
      }
      break
    case 'message':
      if (form.message.trim() === '') {
        errors.message = 'Message is required'
      } else if (form.message.trim().length < 10) {
        errors.message = 'Message must be at least 10 characters'
      } else {
        errors.message = ''
      }
      break
  }
}

async function handleSubmit() {
  // Validate all fields
  validateField('name')
  validateField('email')
  validateField('message')

  if (errors.name || errors.email || errors.message) return

  await contactStore.submitForm({
    name: form.name.trim(),
    email: form.email.trim(),
    subject: form.subject?.trim() || undefined,
    message: form.message.trim(),
  })
}

function handleBlur(field: string) {
  focusedField.value = null
  validateField(field)
}

function handleReset() {
  form.name = ''
  form.email = ''
  form.subject = ''
  form.message = ''
  errors.name = ''
  errors.email = ''
  errors.message = ''
  contactStore.resetForm()
}

onMounted(() => {
  observer = new IntersectionObserver(
    ([entry]) => {
      if (entry?.isIntersecting) {
        uiStore.setActiveSection('contact')
        if (!hasRevealed.value) {
          hasRevealed.value = true
        }
      }
    },
    { threshold: 0.15, rootMargin: '0px 0px -80px 0px' }
  )

  if (sectionRef.value) {
    observer.observe(sectionRef.value)
  }
})

onUnmounted(() => {
  observer?.disconnect()
})
</script>

<template>
  <section id="contact" ref="sectionRef" class="contact-section">
    <div class="container py-20 lg:py-28">
      <!-- Section heading -->
      <div class="mb-14 text-center">
        <span class="section-label">$ mail -s "hello"</span>
        <h2 class="section-title mt-3">Get In Touch</h2>
        <p class="section-subtitle mt-4 mx-auto max-w-xl">
          Have a project in mind, want to collaborate, or just want to say hi? Drop me a message.
        </p>
      </div>

      <!-- Contact layout -->
      <div class="contact-grid">
        <!-- Left: Info panel -->
        <div :class="['info-panel', hasRevealed ? 'is-revealed' : '']">
          <div class="info-card">
            <div class="info-terminal-bar">
              <span class="info-dot dot-red" />
              <span class="info-dot dot-yellow" />
              <span class="info-dot dot-green" />
              <span class="info-terminal-title">contact.sh</span>
            </div>

            <div class="info-body">
              <div class="info-line">
                <span class="info-prompt">$</span>
                <span class="info-cmd">echo $STATUS</span>
              </div>
              <div class="info-response">open to opportunities</div>

              <div class="info-line mt-4">
                <span class="info-prompt">$</span>
                <span class="info-cmd">echo $LOCATION</span>
              </div>
              <div class="info-response">remote / anywhere</div>

              <div class="info-line mt-4">
                <span class="info-prompt">$</span>
                <span class="info-cmd">echo $RESPONSE_TIME</span>
              </div>
              <div class="info-response">usually within 24h</div>

              <div class="info-divider" />

              <div class="info-line">
                <span class="info-prompt">$</span>
                <span class="info-cmd">cat socials.txt</span>
              </div>

              <div class="social-links">
                <a
                  href="https://github.com/justin-negron"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="social-link"
                >
                  <svg class="social-icon" fill="currentColor" viewBox="0 0 24 24">
                    <path
                      d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"
                    />
                  </svg>
                  <span>github</span>
                </a>
                <a
                  href="https://www.linkedin.com/in/justin-negron/"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="social-link"
                >
                  <svg class="social-icon" fill="currentColor" viewBox="0 0 24 24">
                    <path
                      d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"
                    />
                  </svg>
                  <span>linkedin</span>
                </a>
                <a href="mailto:justinnegron174@gmail.com" class="social-link">
                  <svg
                    class="social-icon"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M21.75 6.75v10.5a2.25 2.25 0 0 1-2.25 2.25h-15a2.25 2.25 0 0 1-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25m19.5 0v.243a2.25 2.25 0 0 1-1.07 1.916l-7.5 4.615a2.25 2.25 0 0 1-2.36 0L3.32 8.91a2.25 2.25 0 0 1-1.07-1.916V6.75"
                    />
                  </svg>
                  <span>email</span>
                </a>
              </div>
            </div>
          </div>
        </div>

        <!-- Right: Contact form -->
        <div :class="['form-panel', hasRevealed ? 'is-revealed' : '']">
          <!-- Success state -->
          <div v-if="contactStore.submitted" class="success-card">
            <div class="success-icon-wrap">
              <svg
                class="success-icon"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                stroke-width="1.5"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
                />
              </svg>
            </div>
            <p class="success-title">Message sent!</p>
            <p class="success-text">Thanks for reaching out. I'll get back to you soon.</p>
            <button class="reset-btn" @click="handleReset">Send another message</button>
          </div>

          <!-- Form -->
          <form v-else class="contact-form" novalidate @submit.prevent="handleSubmit">
            <!-- Name -->
            <div class="field-group">
              <label class="field-label" for="contact-name">
                <span class="field-prompt">~$</span> name <span class="field-required">*</span>
              </label>
              <input
                id="contact-name"
                v-model="form.name"
                type="text"
                class="field-input"
                :class="{ 'has-error': errors.name, 'is-focused': focusedField === 'name' }"
                placeholder="Your name"
                autocomplete="name"
                @focus="focusedField = 'name'"
                @blur="handleBlur('name')"
              />
              <span v-if="errors.name" class="field-error">{{ errors.name }}</span>
            </div>

            <!-- Email -->
            <div class="field-group">
              <label class="field-label" for="contact-email">
                <span class="field-prompt">~$</span> email <span class="field-required">*</span>
              </label>
              <input
                id="contact-email"
                v-model="form.email"
                type="email"
                class="field-input"
                :class="{ 'has-error': errors.email, 'is-focused': focusedField === 'email' }"
                placeholder="your@email.com"
                autocomplete="email"
                @focus="focusedField = 'email'"
                @blur="handleBlur('email')"
              />
              <span v-if="errors.email" class="field-error">{{ errors.email }}</span>
            </div>

            <!-- Subject -->
            <div class="field-group">
              <label class="field-label" for="contact-subject">
                <span class="field-prompt">~$</span> subject
              </label>
              <input
                id="contact-subject"
                v-model="form.subject"
                type="text"
                class="field-input"
                :class="{ 'is-focused': focusedField === 'subject' }"
                placeholder="What's this about? (optional)"
                @focus="focusedField = 'subject'"
                @blur="focusedField = null"
              />
            </div>

            <!-- Message -->
            <div class="field-group">
              <label class="field-label" for="contact-message">
                <span class="field-prompt">~$</span> message <span class="field-required">*</span>
              </label>
              <textarea
                id="contact-message"
                v-model="form.message"
                class="field-textarea"
                :class="{ 'has-error': errors.message, 'is-focused': focusedField === 'message' }"
                placeholder="Tell me about your project, idea, or just say hello..."
                rows="5"
                @focus="focusedField = 'message'"
                @blur="handleBlur('message')"
              />
              <span v-if="errors.message" class="field-error">{{ errors.message }}</span>
            </div>

            <!-- Server error -->
            <div v-if="contactStore.error" class="server-error">
              <span class="error-prefix">err:</span>
              {{ contactStore.error.message || 'Something went wrong. Please try again.' }}
            </div>

            <!-- Submit -->
            <button
              type="submit"
              class="submit-btn"
              :disabled="contactStore.submitting || !isFormValid"
            >
              <span v-if="contactStore.submitting" class="submit-spinner" />
              <span v-else class="submit-prompt">$</span>
              <span>{{ contactStore.submitting ? 'Sending...' : 'Send Message' }}</span>
              <svg
                v-if="!contactStore.submitting"
                class="submit-arrow"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                stroke-width="2"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M6 12 3.269 3.125A59.769 59.769 0 0 1 21.485 12 59.768 59.768 0 0 1 3.27 20.875L5.999 12Zm0 0h7.5"
                />
              </svg>
            </button>
          </form>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
/* ===================================================================
   Section base
   =================================================================== */
.contact-section {
  background: #ffffff;
  color: #1c1917;
  transition:
    background 0.4s ease,
    color 0.4s ease;
}

:is(.dark *).contact-section {
  background: #0f0f0f;
  color: #e7e5e4;
}

/* ===================================================================
   Section heading
   =================================================================== */
.section-label {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.85rem;
  color: var(--skin-600);
  letter-spacing: 0.02em;
}

:is(.dark *).section-label {
  color: var(--skin-400);
}

.section-title {
  font-size: clamp(2rem, 5vw, 3rem);
  font-weight: 700;
  letter-spacing: -0.025em;
  color: #1c1917;
}

:is(.dark *).section-title {
  color: #fafaf9;
}

.section-subtitle {
  font-size: 1.05rem;
  line-height: 1.7;
  color: #57534e;
}

:is(.dark *).section-subtitle {
  color: #a8a29e;
}

/* ===================================================================
   Contact grid
   =================================================================== */
.contact-grid {
  display: grid;
  gap: 2rem;
  max-width: 960px;
  margin: 0 auto;
}

@media (min-width: 768px) {
  .contact-grid {
    grid-template-columns: 5fr 7fr;
    gap: 2.5rem;
  }
}

/* ===================================================================
   Reveal animations
   =================================================================== */
.info-panel,
.form-panel {
  opacity: 0;
  will-change: opacity, transform;
}

.info-panel.is-revealed {
  animation: cardReveal 0.6s cubic-bezier(0.16, 1, 0.3, 1) 0.2s forwards;
}

.form-panel.is-revealed {
  animation: cardReveal 0.6s cubic-bezier(0.16, 1, 0.3, 1) 0.4s forwards;
}

@keyframes cardReveal {
  0% {
    opacity: 0;
    transform: translateY(24px);
  }
  100% {
    opacity: 1;
    transform: translateY(0);
  }
}

/* ===================================================================
   Info panel — terminal-inspired card
   =================================================================== */
.info-card {
  background: #faf9f7;
  border: 1px solid #e7e5e4;
  border-radius: 16px;
  overflow: hidden;
  box-shadow:
    0 1px 3px rgba(0, 0, 0, 0.06),
    0 4px 12px rgba(0, 0, 0, 0.03);
  transition:
    background 0.3s ease,
    border-color 0.3s ease;
  height: 100%;
}

:is(.dark *).info-card {
  background: #141211;
  border-color: rgba(var(--skin-light-rgb), 0.12);
  box-shadow:
    0 1px 3px rgba(0, 0, 0, 0.2),
    0 4px 12px rgba(0, 0, 0, 0.15);
}

.info-terminal-bar {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 10px 14px;
  background: rgba(0, 0, 0, 0.02);
  border-bottom: 1px solid #e7e5e4;
  transition:
    background 0.3s ease,
    border-color 0.3s ease;
}

:is(.dark *).info-terminal-bar {
  background: rgba(var(--skin-light-rgb), 0.03);
  border-bottom-color: rgba(var(--skin-light-rgb), 0.06);
}

.info-dot {
  width: 8px;
  height: 8px;
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

.info-terminal-title {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.6rem;
  color: #a8a29e;
  margin-left: auto;
}

:is(.dark *).info-terminal-title {
  color: rgba(var(--skin-light-rgb), 0.3);
}

.info-body {
  padding: 1.25rem;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
}

.info-line {
  display: flex;
  align-items: center;
  gap: 8px;
}

.info-prompt {
  color: var(--skin-700);
  font-weight: 600;
}

:is(.dark *).info-prompt {
  color: var(--skin-500);
}

.info-cmd {
  color: #57534e;
}

:is(.dark *).info-cmd {
  color: #a8a29e;
}

.info-response {
  margin-left: 1.25rem;
  color: #059669;
  margin-top: 2px;
}

:is(.dark *).info-response {
  color: #10b981;
}

.info-divider {
  margin: 1rem 0;
  border-top: 1px solid #e7e5e4;
}

:is(.dark *).info-divider {
  border-top-color: rgba(var(--skin-light-rgb), 0.08);
}

/* ===================================================================
   Social links
   =================================================================== */
.social-links {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 0.75rem;
  margin-left: 1.25rem;
}

.social-link {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  color: #78716c;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  text-decoration: none;
  transition: color 0.2s ease;
}

.social-link:hover {
  color: var(--skin-600);
}

:is(.dark *).social-link {
  color: #78716c;
}

:is(.dark *).social-link:hover {
  color: var(--skin-400);
}

.social-icon {
  width: 16px;
  height: 16px;
  flex-shrink: 0;
}

/* ===================================================================
   Contact form
   =================================================================== */
.contact-form {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.field-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field-label {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  font-weight: 500;
  color: #57534e;
  display: flex;
  align-items: center;
  gap: 6px;
}

:is(.dark *).field-label {
  color: #a8a29e;
}

.field-prompt {
  color: var(--skin-600);
  font-weight: 600;
}

:is(.dark *).field-prompt {
  color: var(--skin-400);
}

.field-required {
  color: #dc2626;
  font-size: 0.7rem;
}

:is(.dark *).field-required {
  color: #f87171;
}

.field-input,
.field-textarea {
  width: 100%;
  padding: 12px 16px;
  font-size: 0.9rem;
  color: #1c1917;
  background: #fafaf9;
  border: 1px solid #e7e5e4;
  border-radius: 12px;
  outline: none;
  transition:
    border-color 0.25s ease,
    background 0.25s ease,
    box-shadow 0.25s ease;
}

.field-input::placeholder,
.field-textarea::placeholder {
  color: #a8a29e;
}

.field-input:focus,
.field-input.is-focused,
.field-textarea:focus,
.field-textarea.is-focused {
  border-color: var(--skin-500);
  box-shadow: 0 0 0 3px rgba(var(--skin-rgb), 0.1);
  background: #ffffff;
}

.field-input.has-error,
.field-textarea.has-error {
  border-color: #dc2626;
  box-shadow: 0 0 0 3px rgba(220, 38, 38, 0.08);
}

:is(.dark *).field-input,
:is(.dark *).field-textarea {
  background: #141312;
  border-color: #292524;
  color: #e7e5e4;
}

:is(.dark *).field-input::placeholder,
:is(.dark *).field-textarea::placeholder {
  color: #57534e;
}

:is(.dark *).field-input:focus,
:is(.dark *).field-input.is-focused,
:is(.dark *).field-textarea:focus,
:is(.dark *).field-textarea.is-focused {
  border-color: var(--skin-400);
  box-shadow: 0 0 0 3px rgba(var(--skin-light-rgb), 0.1);
  background: #1a1918;
}

:is(.dark *).field-input.has-error,
:is(.dark *).field-textarea.has-error {
  border-color: #f87171;
  box-shadow: 0 0 0 3px rgba(248, 113, 113, 0.1);
}

.field-textarea {
  resize: vertical;
  min-height: 120px;
  line-height: 1.6;
}

.field-error {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.7rem;
  color: #dc2626;
}

:is(.dark *).field-error {
  color: #f87171;
}

/* ===================================================================
   Server error
   =================================================================== */
.server-error {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  padding: 10px 14px;
  border-radius: 10px;
  background: rgba(220, 38, 38, 0.06);
  border: 1px solid rgba(220, 38, 38, 0.15);
  color: #dc2626;
}

:is(.dark *).server-error {
  background: rgba(248, 113, 113, 0.06);
  border-color: rgba(248, 113, 113, 0.15);
  color: #f87171;
}

.error-prefix {
  font-weight: 700;
}

/* ===================================================================
   Submit button
   =================================================================== */
.submit-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 14px 32px;
  font-size: 0.9rem;
  font-weight: 600;
  color: white;
  background: linear-gradient(135deg, var(--skin-600), var(--skin-700));
  border: none;
  border-radius: 14px;
  cursor: pointer;
  transition:
    transform 0.2s ease,
    box-shadow 0.2s ease,
    opacity 0.2s ease;
  box-shadow:
    0 2px 8px rgba(var(--skin-rgb), 0.25),
    0 4px 16px rgba(var(--skin-rgb), 0.1);
  align-self: flex-start;
}

.submit-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow:
    0 4px 12px rgba(var(--skin-rgb), 0.3),
    0 8px 24px rgba(var(--skin-rgb), 0.15);
}

.submit-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.submit-prompt {
  font-family: 'JetBrains Mono', monospace;
  font-weight: 700;
  opacity: 0.7;
}

.submit-arrow {
  width: 18px;
  height: 18px;
}

.submit-spinner {
  width: 18px;
  height: 18px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

/* ===================================================================
   Success state
   =================================================================== */
.success-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 3rem 2rem;
  background: #fafaf9;
  border: 1px solid #e7e5e4;
  border-radius: 16px;
  animation: cardReveal 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

:is(.dark *).success-card {
  background: #141312;
  border-color: rgba(var(--skin-light-rgb), 0.12);
}

.success-icon-wrap {
  width: 56px;
  height: 56px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: rgba(34, 197, 94, 0.1);
  margin-bottom: 1.25rem;
}

:is(.dark *).success-icon-wrap {
  background: rgba(34, 197, 94, 0.15);
}

.success-icon {
  width: 28px;
  height: 28px;
  color: #16a34a;
}

:is(.dark *).success-icon {
  color: #4ade80;
}

.success-title {
  font-size: 1.25rem;
  font-weight: 700;
  color: #1c1917;
}

:is(.dark *).success-title {
  color: #fafaf9;
}

.success-text {
  margin-top: 0.5rem;
  font-size: 0.9rem;
  color: #78716c;
}

:is(.dark *).success-text {
  color: #a8a29e;
}

.reset-btn {
  margin-top: 1.5rem;
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--skin-600);
  background: transparent;
  border: 1px solid var(--skin-500);
  border-radius: 10px;
  padding: 8px 20px;
  cursor: pointer;
  transition:
    background 0.2s ease,
    color 0.2s ease;
}

.reset-btn:hover {
  background: rgba(var(--skin-rgb), 0.06);
}

:is(.dark *).reset-btn {
  color: var(--skin-400);
  border-color: var(--skin-400);
}

:is(.dark *).reset-btn:hover {
  background: rgba(var(--skin-light-rgb), 0.06);
}
</style>
