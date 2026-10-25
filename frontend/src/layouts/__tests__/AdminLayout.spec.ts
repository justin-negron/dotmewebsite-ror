import { describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import { logout as apiLogout } from '@/services/auth'
import { useAuthStore } from '@/stores/auth'
import AdminLayout from '@/layouts/AdminLayout.vue'

vi.mock('@/services/auth', () => ({
  login: vi.fn(),
  refreshToken: vi.fn(),
  logout: vi.fn(),
}))

const Blank = { template: '<div />' }

async function mountSignedIn() {
  const pinia = createPinia()
  setActivePinia(pinia)
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: '/admin',
        component: AdminLayout,
        children: [{ path: ':section(.*)', component: Blank }],
      },
      { path: '/admin/login', name: 'admin-login', component: Blank },
    ],
  })
  await router.push('/admin')
  const auth = useAuthStore()
  auth.accessToken = 't'
  auth.admin = { id: 1, email: 'a@b.co', created_at: '2026-10-01T00:00:00Z' }
  const errorHandler = vi.fn()
  const wrapper = mount(AdminLayout, {
    global: { plugins: [pinia, router], config: { errorHandler } },
  })
  return { auth, errorHandler, router, wrapper }
}

describe('AdminLayout logout', () => {
  it('lands on the login page when the logout request fails', async () => {
    vi.mocked(apiLogout).mockRejectedValueOnce({ message: 'boom', errors: null, status: 500 })
    const { auth, router, wrapper } = await mountSignedIn()

    await wrapper.get('.logout-btn').trigger('click')
    await flushPromises()

    expect(router.currentRoute.value.name).toBe('admin-login')
    expect(auth.isAuthenticated).toBe(false)
  })

  it('still navigates when the store itself throws during logout', async () => {
    const { auth, errorHandler, router, wrapper } = await mountSignedIn()
    vi.spyOn(auth, 'logout').mockRejectedValueOnce(new Error('store blew up'))

    await wrapper.get('.logout-btn').trigger('click')
    await flushPromises()

    expect(router.currentRoute.value.name).toBe('admin-login')
    expect(errorHandler.mock.calls[0]?.[0]).toEqual(new Error('store blew up'))
  })
})
