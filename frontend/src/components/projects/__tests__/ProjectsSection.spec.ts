import { describe, it, expect, vi, afterEach } from 'vitest'
import { mount, flushPromises, type VueWrapper } from '@vue/test-utils'
import { createPinia } from 'pinia'
import ProjectsSection from '../ProjectsSection.vue'
import { getFeaturedProjects } from '@/services/projects'
import type { Project } from '@/types'

vi.hoisted(() => {
  localStorage.setItem('theme-preference', 'dark')
})

vi.mock('@/services/projects', () => ({
  getProjects: vi.fn(),
  getProject: vi.fn(),
  getFeaturedProjects: vi.fn(),
  getProjectsByTechnology: vi.fn(),
}))

const project: Project = {
  id: 1,
  title: 'Robot Swarm',
  description: 'Robots that coordinate without a leader.',
  tech_stack: ['ROS'],
  featured: true,
  display_order: 1,
  github_url: 'https://github.com/example/swarm',
  live_url: 'https://swarm.example.com',
  paper_url: 'https://link.springer.com/example',
  media_urls: [
    'https://cdn.test/p.webp',
    'https://cdn.test/d.webp#light-only',
    'https://cdn.test/d-dark.webp#dark-only',
  ],
  created_at: '2026-10-14T00:00:00Z',
  updated_at: '2026-10-14T00:00:00Z',
}

let wrapper: VueWrapper | null = null

async function mountSection() {
  vi.mocked(getFeaturedProjects).mockResolvedValue({ success: true, data: [project] })
  wrapper = mount(ProjectsSection, {
    attachTo: document.body,
    global: { plugins: [createPinia()], stubs: { teleport: true } },
  })
  await flushPromises()
  return wrapper
}

afterEach(() => {
  wrapper?.unmount()
  wrapper = null
})

describe('ProjectsSection media wiring', () => {
  it('shows the dark-theme slides in the card and in the lightbox', async () => {
    const w = await mountSection()

    await w.get('.media-carousel [aria-label="Next image"]').trigger('click')
    expect(w.get('.media-carousel img').attributes('src')).toBe('https://cdn.test/d-dark.webp')

    await w.get('.slide-btn').trigger('click')
    expect(w.get('.lightbox img').attributes('src')).toBe('https://cdn.test/d-dark.webp')
    expect(w.get('.lb-counter').text()).toBe('2 / 2')

    await w.get('[aria-label="Close image viewer"]').trigger('click')
    expect(w.find('.lightbox').exists()).toBe(false)
  })
})

describe('ProjectsSection link names', () => {
  it('names each card link by its visible text plus the project', async () => {
    const w = await mountSection()
    const links = w.findAll('.project-link')

    expect(links.map((a) => a.attributes('aria-label'))).toEqual([undefined, undefined, undefined])
    expect(links.map((a) => a.text())).toEqual([
      'Source for Robot Swarm',
      'Live for Robot Swarm',
      'Publication for Robot Swarm',
    ])
  })
})
