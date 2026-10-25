import type { Theme } from '@/composables/useTheme'

/**
 * Slides can opt into one theme by ending their URL with one of these markers.
 * It is a URL fragment, so browsers never send it to the CDN, and a URL without
 * a marker shows in both themes. Same idea as GitHub's #gh-dark-mode-only.
 */
export const LIGHT_ONLY = '#light-only'
export const DARK_ONLY = '#dark-only'

const MARKER = /#(light|dark)-only$/

export function stripThemeMarker(url: string): string {
  return url.replace(MARKER, '')
}

/** The slides to show for `theme`, in their original order, markers removed. */
export function slidesForTheme(urls: readonly string[], theme: Theme): string[] {
  const hidden = theme === 'dark' ? LIGHT_ONLY : DARK_ONLY
  return urls.filter((url) => !url.endsWith(hidden)).map(stripThemeMarker)
}
