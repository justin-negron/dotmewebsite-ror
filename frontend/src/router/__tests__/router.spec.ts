import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'

vi.mock('@/services/auth', () => ({
  login: vi.fn(),
  refreshToken: vi.fn(),
  logout: vi.fn(),
}))

const blank = { default: { template: '<div />' } }
vi.mock('@/views/HomeView.vue', () => blank)
vi.mock('@/views/BlogView.vue', () => blank)
vi.mock('@/views/NotFoundView.vue', () => blank)
vi.mock('@/views/admin/AdminLoginView.vue', () => blank)
vi.mock('@/views/admin/AdminProjectsView.vue', () => blank)
vi.mock('@/layouts/AdminLayout.vue', () => blank)

async function loadRouter() {
  vi.resetModules()
  setActivePinia(createPinia())
  const { refreshToken } = await import('@/services/auth')
  const { default: router } = await import('@/router')
  return { router, refreshToken: vi.mocked(refreshToken) }
}

function robots() {
  return document.querySelector('meta[name="robots"]')?.getAttribute('content') ?? null
}

function canonical() {
  return document.querySelector('link[rel="canonical"]')?.getAttribute('href') ?? null
}

describe('router', () => {
  beforeEach(() => {
    document.head.innerHTML = ''
    vi.stubEnv('VITE_SITE_URL', 'https://justinnegron.dev')
    vi.spyOn(window, 'scrollTo').mockImplementation(() => {})
  })

  afterEach(() => {
    vi.unstubAllEnvs()
    vi.restoreAllMocks()
  })

  describe('admin guard', () => {
    it('sends a signed-out visitor to login with a return path', async () => {
      const { router, refreshToken } = await loadRouter()
      refreshToken.mockRejectedValueOnce({ message: 'Unauthorized', errors: [], status: 401 })

      await router.push('/admin/projects')

      expect(router.currentRoute.value.name).toBe('admin-login')
      expect(router.currentRoute.value.query).toEqual({ redirect: '/admin/projects' })
    })

    it('lets a reload through when the silent refresh succeeds', async () => {
      const { router, refreshToken } = await loadRouter()
      refreshToken.mockResolvedValueOnce({
        success: true,
        data: {
          access_token: 't',
          admin: { id: 1, email: 'a@b.co', created_at: '2026-10-01T00:00:00Z' },
        },
      })

      await router.push('/admin/projects')

      expect(router.currentRoute.value.name).toBe('admin-projects')
      expect(refreshToken).toHaveBeenCalledTimes(1)
    })
  })

  describe('hash links from another page', () => {
    function stubReducedMotion(reduce: boolean) {
      vi.spyOn(window, 'matchMedia').mockImplementation(
        (query: string) =>
          ({
            matches: reduce && query === '(prefers-reduced-motion: reduce)',
            media: query,
          }) as MediaQueryList
      )
    }

    async function followHashFromBlog() {
      const section = document.createElement('section')
      section.id = 'contact'
      document.body.replaceChildren(section)
      const { router } = await loadRouter()
      await router.push('/blog')
      vi.useFakeTimers({ toFake: ['setTimeout'] })
      await router.push('/#contact')
      await vi.advanceTimersByTimeAsync(650)
      vi.useRealTimers()
      return section
    }

    it('moves focus to the section once the delayed scroll lands', async () => {
      stubReducedMotion(false)
      const section = await followHashFromBlog()

      expect(document.activeElement).toBe(section)
      expect(section.getAttribute('tabindex')).toBe('-1')
      expect(vi.mocked(window.scrollTo).mock.calls.at(-1)?.[0]).toMatchObject({
        behavior: 'smooth',
      })
    })

    it('jumps without smooth scrolling for reduced motion', async () => {
      stubReducedMotion(true)
      await followHashFromBlog()

      expect(vi.mocked(window.scrollTo).mock.calls.at(-1)?.[0]).toMatchObject({ behavior: 'auto' })
    })
  })

  describe('not-found head', () => {
    it('marks an unknown path noindex with a canonical at the site root', async () => {
      const { router } = await loadRouter()

      await router.push('/nope')

      expect(router.currentRoute.value.name).toBe('not-found')
      expect(robots()).toBe('noindex')
      expect(canonical()).toBe('https://justinnegron.dev/')
    })

    it('removes the robots tag again on a real page', async () => {
      const { router } = await loadRouter()

      await router.push('/nope')
      await router.push('/blog')

      expect(robots()).toBeNull()
      expect(canonical()).toBe('https://justinnegron.dev/blog')
    })
  })
})
