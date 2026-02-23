export interface HeadOptions {
  title: string
  description: string
  /** Path portion of the URL, e.g. "/blog/my-post". Prefixed with VITE_SITE_URL. */
  path?: string
  /** Absolute image URL. Defaults to ${VITE_SITE_URL}/og-image.jpg */
  image?: string
  type?: 'website' | 'article'
  /** ISO date string for article:published_time */
  publishedAt?: string | null
  tags?: string[]
}

const SITE_URL = (import.meta.env.VITE_SITE_URL as string) || ''
const SITE_TITLE = (import.meta.env.VITE_APP_TITLE as string) || 'Portfolio'
const TWITTER_HANDLE = (import.meta.env.VITE_TWITTER_HANDLE as string) || ''

function setMeta(attr: 'name' | 'property', key: string, content: string): void {
  const selector = `meta[${attr}="${key}"]`
  let el = document.querySelector<HTMLMetaElement>(selector)
  if (!el) {
    el = document.createElement('meta')
    el.setAttribute(attr, key)
    document.head.appendChild(el)
  }
  el.content = content
}

function setCanonical(href: string): void {
  let el = document.querySelector<HTMLLinkElement>('link[rel="canonical"]')
  if (!el) {
    el = document.createElement('link')
    el.rel = 'canonical'
    document.head.appendChild(el)
  }
  el.href = href
}

export function updateHead(options: HeadOptions): void {
  const fullTitle = `${options.title} | ${SITE_TITLE}`
  const canonicalUrl = `${SITE_URL}${options.path ?? ''}`
  const image = options.image ?? `${SITE_URL}/og-image.jpg`
  const type = options.type ?? 'website'

  // <title>
  document.title = fullTitle

  // Standard meta
  setMeta('name', 'description', options.description)

  // Open Graph
  setMeta('property', 'og:title', fullTitle)
  setMeta('property', 'og:description', options.description)
  setMeta('property', 'og:url', canonicalUrl)
  setMeta('property', 'og:image', image)
  setMeta('property', 'og:type', type)
  setMeta('property', 'og:site_name', SITE_TITLE)

  // Article-specific Open Graph
  if (type === 'article') {
    if (options.publishedAt) {
      setMeta('property', 'article:published_time', options.publishedAt)
    }
    // article:tag allows multiples — remove stale set then rebuild
    document.querySelectorAll('meta[property="article:tag"]').forEach((el) => el.remove())
    options.tags?.forEach((tag) => {
      const tagEl = document.createElement('meta')
      tagEl.setAttribute('property', 'article:tag')
      tagEl.content = tag
      document.head.appendChild(tagEl)
    })
  }

  // Twitter Cards
  setMeta('name', 'twitter:card', 'summary_large_image')
  setMeta('name', 'twitter:title', fullTitle)
  setMeta('name', 'twitter:description', options.description)
  setMeta('name', 'twitter:image', image)
  if (TWITTER_HANDLE) {
    setMeta(
      'name',
      'twitter:site',
      TWITTER_HANDLE.startsWith('@') ? TWITTER_HANDLE : `@${TWITTER_HANDLE}`,
    )
  }

  // Canonical
  setCanonical(canonicalUrl)
}
