import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { logout as apiLogout, refreshToken as apiRefresh } from '@/services/auth'
import { useAuthStore } from '@/stores/auth'
import { useAdminProjectsStore } from '@/stores/admin'
import type { AdminUser, ApiError, Project } from '@/types'

vi.mock('@/services/auth', () => ({
  login: vi.fn(),
  refreshToken: vi.fn(),
  logout: vi.fn(),
}))

const admin: AdminUser = { id: 1, email: 'a@b.co', created_at: '2026-10-01T00:00:00Z' }

const networkError: ApiError = {
  message: 'Network error. Please check your connection.',
  errors: null,
  status: null,
}

const expiredToken: ApiError = { status: 401, message: 'Token has expired', errors: null }

function signedIn() {
  const auth = useAuthStore()
  auth.accessToken = 't'
  auth.admin = admin
  return auth
}

describe('auth store logout', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.mocked(apiLogout).mockReset()
    vi.mocked(apiRefresh).mockReset()
  })

  it('signs out and clears admin data even when the API call fails', async () => {
    vi.mocked(apiLogout).mockRejectedValueOnce(networkError)
    const auth = signedIn()
    useAdminProjectsStore().projects = [{ id: 7 } as Project]

    await expect(auth.logout()).resolves.toBeUndefined()

    expect(vi.mocked(apiLogout).mock.calls).toEqual([['t']])
    expect(auth.accessToken).toBeNull()
    expect(auth.isAuthenticated).toBe(false)
    expect(auth.error).toBeNull()
    expect(useAdminProjectsStore().projects).toEqual([])
  })

  it('refreshes an expired token once and revokes the session with the new one', async () => {
    vi.mocked(apiLogout).mockRejectedValueOnce(expiredToken).mockResolvedValueOnce(undefined)
    vi.mocked(apiRefresh).mockResolvedValueOnce({
      success: true,
      data: { access_token: 'new-token', admin },
    })
    const auth = signedIn()

    await auth.logout()

    expect(vi.mocked(apiLogout).mock.calls).toEqual([['t'], ['new-token']])
    expect(auth.error).toBeNull()
    expect(auth.accessToken).toBeNull()
  })

  it('gives up quietly when the refresh fails too', async () => {
    vi.mocked(apiLogout).mockRejectedValueOnce(expiredToken)
    vi.mocked(apiRefresh).mockRejectedValueOnce(expiredToken)
    const auth = signedIn()

    await expect(auth.logout()).resolves.toBeUndefined()

    expect(vi.mocked(apiLogout).mock.calls).toEqual([['t']])
    expect(auth.accessToken).toBeNull()
    expect(auth.error).toBeNull()
  })

  it('gives up quietly when the retried logout fails', async () => {
    vi.mocked(apiLogout).mockRejectedValueOnce(expiredToken).mockRejectedValueOnce(networkError)
    vi.mocked(apiRefresh).mockResolvedValueOnce({
      success: true,
      data: { access_token: 'new-token', admin },
    })
    const auth = signedIn()

    await expect(auth.logout()).resolves.toBeUndefined()

    expect(vi.mocked(apiLogout).mock.calls).toEqual([['t'], ['new-token']])
    expect(auth.accessToken).toBeNull()
    expect(auth.error).toBeNull()
  })
})
