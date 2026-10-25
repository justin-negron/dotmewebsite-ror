import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { submitContactForm } from '@/services/contacts'
import { useContactStore } from '@/stores/contact'

vi.mock('@/services/contacts', () => ({ submitContactForm: vi.fn() }))

const form = { name: 'Ada', email: 'ada@example', subject: '', message: 'Hello there, Justin!' }

describe('contact store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.mocked(submitContactForm).mockReset()
  })

  it('keeps the server validation messages from a 422', async () => {
    vi.mocked(submitContactForm).mockRejectedValueOnce({
      message: 'Failed to send message',
      errors: ['Email is invalid'],
      status: 422,
    })
    const store = useContactStore()

    expect(await store.submitForm(form)).toBe(false)
    expect(store.validationErrors).toEqual(['Email is invalid'])
    expect(store.hasValidationErrors).toBe(true)
  })

  it('reports no validation errors for a network failure', async () => {
    vi.mocked(submitContactForm).mockRejectedValueOnce({
      message: 'Network error. Please check your connection.',
      errors: null,
      status: null,
    })
    const store = useContactStore()

    expect(await store.submitForm(form)).toBe(false)
    expect(store.error?.message).toBe('Network error. Please check your connection.')
    expect(store.hasValidationErrors).toBe(false)
  })
})
