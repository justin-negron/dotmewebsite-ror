import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { AxiosError, AxiosHeaders } from 'axios'
import type { InternalAxiosRequestConfig } from 'axios'
import { createPinia, setActivePinia } from 'pinia'
import { httpError, ok } from '@/test/axios'
import type { ApiErrorResponse } from '@/types'

const PROJECTS = '/api/v1/admin/projects'
const REFRESH = '/api/v1/admin/auth/refresh'

async function loadApi() {
  vi.resetModules()
  setActivePinia(createPinia())
  const apiModule = await import('@/services/api')
  const { useAuthStore } = await import('@/stores/auth')
  apiModule.setAuthTokenGetter(() => useAuthStore().accessToken)
  return { ...apiModule, useAuthStore }
}

function deferred<T>() {
  let resolve!: (value: T) => void
  const promise = new Promise<T>((r) => (resolve = r))
  return { promise, resolve }
}

describe('api 401 handling', () => {
  beforeEach(() => {
    vi.spyOn(console, 'error').mockImplementation(() => {})
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('shares one refresh between concurrent 401s and retries both with the new token', async () => {
    const { default: api, useAuthStore } = await loadApi()
    const refreshGate = deferred<void>()
    let failures = 0
    const seen: string[] = []

    api.defaults.adapter = vi.fn(async (config: InternalAxiosRequestConfig) => {
      const auth = String(config.headers.Authorization ?? '')
      seen.push(`${config.method} ${config.url} ${auth}`)
      if (config.url === REFRESH) {
        await refreshGate.promise
        return ok(config, {
          success: true,
          data: {
            access_token: 'new-token',
            admin: { id: 1, email: 'a@b.co', created_at: '2026-10-01T00:00:00Z' },
          },
        })
      }
      if (auth !== 'Bearer new-token') {
        failures += 1
        if (failures === 2) refreshGate.resolve()
        throw httpError(config, 401, { success: false, message: 'Unauthorized', errors: [] })
      }
      return ok(config, { success: true, data: [] })
    })

    const [first, second] = await Promise.all([api.get(PROJECTS), api.get(PROJECTS)])

    expect([first.status, second.status]).toEqual([200, 200])
    expect(seen.filter((line) => line.startsWith(`post ${REFRESH}`))).toHaveLength(1)
    expect(seen.filter((line) => line.endsWith('Bearer new-token'))).toEqual([
      `get ${PROJECTS} Bearer new-token`,
      `get ${PROJECTS} Bearer new-token`,
    ])
    expect(useAuthStore().accessToken).toBe('new-token')
  })

  it('stops after a 401 from the refresh call itself', async () => {
    const { default: api, useAuthStore } = await loadApi()
    const urls: string[] = []

    api.defaults.adapter = vi.fn(async (config: InternalAxiosRequestConfig) => {
      urls.push(`${config.method} ${config.url}`)
      throw httpError(config, 401, { success: false, message: 'Unauthorized', errors: [] })
    })

    const failure = await api.get(PROJECTS).catch((error: AxiosError) => error)

    expect(failure).toBeInstanceOf(AxiosError)
    expect((failure as AxiosError).response?.status).toBe(401)
    expect(urls).toEqual([`get ${PROJECTS}`, `post ${REFRESH}`])
    expect(useAuthStore().accessToken).toBeNull()
  })
})

describe('handleApiError', () => {
  const config = { headers: new AxiosHeaders() } as InternalAxiosRequestConfig

  it('keeps the server message and its list of error strings', async () => {
    const { handleApiError } = await loadApi()
    const body: ApiErrorResponse = {
      success: false,
      message: 'Failed to send message',
      errors: ['Email is invalid'],
    }

    const mapped = handleApiError(httpError(config, 422, body))
    const messages: string[] | null = mapped.errors

    expect(mapped).toEqual({
      message: 'Failed to send message',
      errors: ['Email is invalid'],
      status: 422,
    })
    expect(messages).toEqual(['Email is invalid'])
  })

  it('maps a request with no response to a network error', async () => {
    const { handleApiError } = await loadApi()
    const error = new AxiosError('timeout', 'ECONNABORTED', config, {})

    expect(handleApiError(error)).toEqual({
      message: 'Network error. Please check your connection.',
      errors: null,
      status: null,
    })
  })

  it('falls back to the client message when no request went out', async () => {
    const { handleApiError } = await loadApi()

    expect(handleApiError(new AxiosError('bad config'))).toEqual({
      message: 'bad config',
      errors: null,
      status: null,
    })
  })
})
