/// <reference types="node" />
import { createHash } from 'node:crypto'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import indexHtml from '../../index.html?raw'

const page = new DOMParser().parseFromString(indexHtml, 'text/html')

function themeScript(): string {
  const inline = [...page.head.querySelectorAll('script')].filter(
    (script) => !script.src && !script.type
  )
  expect(inline).toHaveLength(1)
  return inline[0]!.textContent ?? ''
}

function runThemeScript({ stored, systemDark }: { stored: string | null; systemDark: boolean }) {
  if (stored !== null) localStorage.setItem('theme-preference', stored)
  vi.spyOn(window, 'matchMedia').mockImplementation(
    (query: string) =>
      ({ matches: systemDark && query === '(prefers-color-scheme: dark)' }) as MediaQueryList
  )
  new Function(themeScript())()
  return {
    dark: document.documentElement.classList.contains('dark'),
    themeColor: document.querySelector('meta[name="theme-color"]')?.getAttribute('content'),
  }
}

function publicFile(path: string): Buffer {
  return readFileSync(resolve(__dirname, '../../public', path.replace(/^.*\//, '')))
}

function imageSize(buf: Buffer): { width: number; height: number } {
  if (buf.readUInt32BE(0) === 0x89504e47) {
    return { width: buf.readUInt32BE(16), height: buf.readUInt32BE(20) }
  }
  for (let i = 2; i + 9 < buf.length && buf[i] === 0xff; i += 2 + buf.readUInt16BE(i + 2)) {
    const marker = buf[i + 1]!
    if (marker >= 0xc0 && marker <= 0xcf && ![0xc4, 0xc8, 0xcc].includes(marker)) {
      return { width: buf.readUInt16BE(i + 7), height: buf.readUInt16BE(i + 5) }
    }
  }
  throw new Error('no image size found')
}

function meta(key: string): string | null {
  const el = page.head.querySelector(`meta[property="${key}"], meta[name="${key}"]`)
  return el?.getAttribute('content') ?? null
}

describe('index.html', () => {
  beforeEach(() => {
    localStorage.clear()
    document.documentElement.className = ''
    document.head.innerHTML = page.head.innerHTML
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  describe('first-paint theme script', () => {
    it('applies a stored dark theme', () => {
      expect(runThemeScript({ stored: 'dark', systemDark: false })).toEqual({
        dark: true,
        themeColor: '#0f0f0f',
      })
    })

    it('follows the system when nothing valid is stored', () => {
      expect(runThemeScript({ stored: null, systemDark: true })).toEqual({
        dark: true,
        themeColor: '#0f0f0f',
      })
      document.documentElement.className = ''
      expect(runThemeScript({ stored: 'purple', systemDark: false })).toEqual({
        dark: false,
        themeColor: '#ffffff',
      })
    })

    it('lets a stored light theme win over a dark system', () => {
      expect(runThemeScript({ stored: 'light', systemDark: true })).toEqual({
        dark: false,
        themeColor: '#ffffff',
      })
    })

    it('hashes to the sha256 that the CSP in infra/site.tf allows', () => {
      const digest = createHash('sha256').update(themeScript()).digest('base64')
      const siteTf = readFileSync(resolve(__dirname, '../../../infra/site.tf'), 'utf8')

      expect(siteTf.match(/script-src 'self' '(sha256-[^']+)'/)?.[1]).toBe(`sha256-${digest}`)
    })

    it('swallows blocked storage so the app can still boot', () => {
      vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
        throw new DOMException('denied', 'SecurityError')
      })

      expect(() => new Function(themeScript())()).not.toThrow()
      expect(document.documentElement.classList.contains('dark')).toBe(false)
    })
  })

  it('declares the share image at the size of the file it points to', () => {
    const og = imageSize(publicFile(meta('og:image') ?? ''))

    expect(og).toEqual({ width: 1200, height: 630 })
    expect([meta('og:image:width'), meta('og:image:height')]).toEqual(['1200', '630'])
    expect([meta('og:image:alt'), meta('twitter:image:alt')]).toEqual([
      'Justin Negron, Software Engineer II',
      'Justin Negron, Software Engineer II',
    ])
  })

  it('links an apple touch icon that exists at 180 by 180', () => {
    const href = page.head.querySelector('link[rel="apple-touch-icon"]')?.getAttribute('href')

    expect(href).toBe('/apple-touch-icon.png')
    expect(imageSize(publicFile(href ?? ''))).toEqual({ width: 180, height: 180 })
  })

  it('ships valid JSON-LD for the site and its owner', () => {
    const block = page.head.querySelector('script[type="application/ld+json"]')

    expect(JSON.parse(block?.textContent ?? 'null')).toEqual({
      '@context': 'https://schema.org',
      '@graph': [
        { '@type': 'WebSite', name: 'Justin Negron', url: 'https://justinnegron.dev' },
        {
          '@type': 'Person',
          name: 'Justin Negron',
          url: 'https://justinnegron.dev',
          jobTitle: 'Software Engineer II',
          sameAs: [
            'https://github.com/justin-negron',
            'https://www.linkedin.com/in/justin-negron/',
          ],
        },
      ],
    })
  })
})
