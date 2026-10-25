import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import AdminUrlListInput from '../AdminUrlListInput.vue'

const urls = ['https://cdn.test/1.webp', 'https://cdn.test/2.webp']

describe('AdminUrlListInput', () => {
  it('renders the current URLs one per line', () => {
    const wrapper = mount(AdminUrlListInput, { props: { modelValue: urls } })

    expect((wrapper.get('textarea').element as HTMLTextAreaElement).value).toBe(urls.join('\n'))
  })

  it('emits a cleaned list, dropping blank lines and whitespace', async () => {
    const wrapper = mount(AdminUrlListInput, { props: { modelValue: [] } })

    await wrapper
      .get('textarea')
      .setValue('  https://cdn.test/a.webp \n\n   \nhttps://cdn.test/b.webp\n')

    const emitted = wrapper.emitted('update:modelValue')
    expect(emitted?.[emitted.length - 1]).toEqual([
      ['https://cdn.test/a.webp', 'https://cdn.test/b.webp'],
    ])
  })

  it('keeps the raw text while typing so a trailing newline survives', async () => {
    const wrapper = mount(AdminUrlListInput, { props: { modelValue: [] } })

    await wrapper.get('textarea').setValue('https://cdn.test/a.webp\n')
    await wrapper.setProps({ modelValue: ['https://cdn.test/a.webp'] })

    expect((wrapper.get('textarea').element as HTMLTextAreaElement).value).toBe(
      'https://cdn.test/a.webp\n'
    )
  })

  it('resyncs the textarea when the parent replaces the list', async () => {
    const wrapper = mount(AdminUrlListInput, { props: { modelValue: [] } })

    await wrapper.setProps({ modelValue: urls })

    expect((wrapper.get('textarea').element as HTMLTextAreaElement).value).toBe(urls.join('\n'))
  })

  it('shows a numbered thumbnail for each URL in order', () => {
    const wrapper = mount(AdminUrlListInput, { props: { modelValue: urls } })
    const thumbs = wrapper.findAll('.thumb')

    expect(thumbs).toHaveLength(2)
    expect(thumbs[0]!.get('img').attributes('src')).toBe(urls[0])
    expect(thumbs[1]!.get('.thumb-index').text()).toBe('2')
  })

  it('shows no thumbnails when the list is empty', () => {
    const wrapper = mount(AdminUrlListInput, { props: { modelValue: [] } })

    expect(wrapper.find('.thumb-list').exists()).toBe(false)
  })
})
