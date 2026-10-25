import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { mount, flushPromises, type VueWrapper } from '@vue/test-utils'
import { createPinia } from 'pinia'
import ContactSection from '../ContactSection.vue'
import { submitContactForm } from '@/services/contacts'
import type { Contact } from '@/types'

vi.mock('@/services/contacts', () => ({ submitContactForm: vi.fn() }))

const submit = vi.mocked(submitContactForm)
const sentContact: Contact = {
  id: 1,
  name: 'Ada',
  email: 'ada@example.com',
  subject: '',
  message: 'Hello there, Justin!',
  status: 'new',
  created_at: '2026-10-14T00:00:00Z',
}
let wrapper: VueWrapper | null = null

function mountContact() {
  wrapper = mount(ContactSection, {
    attachTo: document.body,
    global: { plugins: [createPinia()] },
  })
  return wrapper
}

function spokenText(el: Element): string {
  const parts: string[] = []
  el.childNodes.forEach((node) => {
    if (node.nodeType === Node.TEXT_NODE) parts.push(node.textContent ?? '')
    else if (node instanceof Element && node.getAttribute('aria-hidden') !== 'true') {
      parts.push(spokenText(node))
    }
  })
  return parts.join('').replace(/\s+/g, ' ').trim()
}

async function fillValidForm(w: VueWrapper) {
  await w.get('#contact-name').setValue('  Ada  ')
  await w.get('#contact-email').setValue(' ada@example.com ')
  await w.get('#contact-subject').setValue('')
  await w.get('#contact-message').setValue('  Hello there, Justin!  ')
}

beforeEach(() => {
  submit.mockReset()
})

afterEach(() => {
  wrapper?.unmount()
  wrapper = null
})

describe('ContactSection validation', () => {
  it('shows a field error on blur', async () => {
    const w = mountContact()
    const email = w.get('#contact-email')

    await email.setValue('ada@')
    await email.trigger('blur')
    expect(w.get('.field-error').text()).toBe('Invalid email format')
  })

  it('marks an invalid field and points it at its message', async () => {
    const w = mountContact()
    const name = w.get('#contact-name')

    await name.trigger('blur')
    expect(name.attributes('aria-invalid')).toBe('true')
    expect(name.attributes('aria-describedby')).toBe('contact-name-error')
    expect(w.get('#contact-name-error').text()).toBe('Name is required')

    await name.setValue('Ada')
    await name.trigger('blur')
    expect(name.attributes('aria-invalid')).toBe('false')
    expect(name.attributes('aria-describedby')).toBeUndefined()
  })

  it('marks the three required fields as required and subject as optional', () => {
    const w = mountContact()
    const required = (sel: string) => (w.get(sel).element as HTMLInputElement).required

    expect(required('#contact-name')).toBe(true)
    expect(required('#contact-email')).toBe(true)
    expect(required('#contact-message')).toBe(true)
    expect(required('#contact-subject')).toBe(false)
  })

  it('reads each label without the decorative prompt and star', () => {
    const w = mountContact()

    expect(spokenText(w.get('label[for="contact-name"]').element)).toBe('name')
    expect(spokenText(w.get('label[for="contact-subject"]').element)).toBe('subject')
  })
})

describe('ContactSection submit', () => {
  it('posts trimmed values, then announces and focuses the success message', async () => {
    submit.mockResolvedValue({ success: true, data: sentContact })
    const w = mountContact()
    await fillValidForm(w)

    await w.get('form').trigger('submit')
    await flushPromises()

    expect(submit).toHaveBeenCalledTimes(1)
    expect(submit).toHaveBeenCalledWith({
      name: 'Ada',
      email: 'ada@example.com',
      subject: undefined,
      message: 'Hello there, Justin!',
    })
    expect(w.get('[role="status"]').text()).toContain('Message sent!')
    expect(document.activeElement?.textContent).toBe('Message sent!')
  })

  it('returns focus to the name field when starting another message', async () => {
    submit.mockResolvedValue({ success: true, data: sentContact })
    const w = mountContact()
    await fillValidForm(w)
    await w.get('form').trigger('submit')
    await flushPromises()

    await w.get('.reset-btn').trigger('click')
    await flushPromises()
    expect(document.activeElement?.id).toBe('contact-name')
  })

  it('announces a server error as an alert', async () => {
    submit.mockRejectedValue({ message: 'Failed to send message', errors: null, status: 422 })
    const w = mountContact()
    await fillValidForm(w)

    await w.get('form').trigger('submit')
    await flushPromises()

    expect(w.get('[role="alert"]').text()).toBe('err: Failed to send message')
  })
})
