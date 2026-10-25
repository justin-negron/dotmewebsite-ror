import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { getPresignedUrl } from '@/services/admin/uploads'
import { useImageUpload } from '@/composables/useImageUpload'

vi.mock('@/services/admin/uploads', () => ({ getPresignedUrl: vi.fn() }))

class FakeXhr {
  static sent: { method: string; url: string; type: string | null; body: unknown }[] = []
  status = 200
  upload = new EventTarget()
  private events = new EventTarget()
  private method = ''
  private url = ''
  private type: string | null = null

  addEventListener(name: string, listener: EventListener) {
    this.events.addEventListener(name, listener)
  }
  open(method: string, url: string) {
    this.method = method
    this.url = url
  }
  setRequestHeader(_name: string, value: string) {
    this.type = value
  }
  send(body: unknown) {
    FakeXhr.sent.push({ method: this.method, url: this.url, type: this.type, body })
    queueMicrotask(() => this.events.dispatchEvent(new Event('load')))
  }
}

function png(name: string, bytes: number) {
  return new File([new Uint8Array(bytes)], name, { type: 'image/png' })
}

describe('useImageUpload', () => {
  beforeEach(() => {
    vi.mocked(getPresignedUrl).mockReset()
    FakeXhr.sent = []
    vi.stubGlobal('XMLHttpRequest', FakeXhr)
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('rejects a file over 5 MB before asking for a presigned URL', async () => {
    const { uploadFile, error } = useImageUpload()

    const result = await uploadFile(png('big.png', 5 * 1024 * 1024 + 1))

    expect(result).toBeNull()
    expect(error.value).toBe('File too large. Maximum size is 5 MB.')
    expect(getPresignedUrl).toHaveBeenCalledTimes(0)
  })

  it('uploads a small file to the presigned URL and returns the public URL', async () => {
    vi.mocked(getPresignedUrl).mockResolvedValueOnce({
      success: true,
      data: {
        presigned_url: 'https://bucket.test/put?sig=1',
        public_url: 'https://assets.test/ok.png',
        key: 'ok.png',
      },
    })
    const file = png('ok.png', 1)
    const { uploadFile, error, progress } = useImageUpload()

    const result = await uploadFile(file)

    expect(vi.mocked(getPresignedUrl).mock.calls).toEqual([['ok.png', 'image/png']])
    expect(FakeXhr.sent).toEqual([
      { method: 'PUT', url: 'https://bucket.test/put?sig=1', type: 'image/png', body: file },
    ])
    expect(result).toBe('https://assets.test/ok.png')
    expect(progress.value).toBe(100)
    expect(error.value).toBeNull()
  })

  it('shows the server message when presigning fails', async () => {
    vi.mocked(getPresignedUrl).mockRejectedValueOnce({
      message: 'An unexpected error occurred',
      errors: null,
      status: 500,
    })
    const { uploadFile, error, uploading } = useImageUpload()

    const result = await uploadFile(png('ok.png', 1))

    expect(result).toBeNull()
    expect(error.value).toBe('An unexpected error occurred')
    expect(uploading.value).toBe(false)
  })
})
