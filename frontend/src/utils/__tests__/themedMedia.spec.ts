import { describe, expect, it } from 'vitest'
import { DARK_ONLY, LIGHT_ONLY, slidesForTheme, stripThemeMarker } from '../themedMedia'

const photo = 'https://cdn.example.com/photo.webp'
const light = `https://cdn.example.com/diagram.webp${LIGHT_ONLY}`
const dark = `https://cdn.example.com/diagram-dark.webp${DARK_ONLY}`

describe('slidesForTheme', () => {
  it('keeps unmarked slides in both themes', () => {
    expect(slidesForTheme([photo], 'light')).toEqual([photo])
    expect(slidesForTheme([photo], 'dark')).toEqual([photo])
  })

  it('shows only the matching variant and strips the marker', () => {
    expect(slidesForTheme([light, dark], 'light')).toEqual(['https://cdn.example.com/diagram.webp'])
    expect(slidesForTheme([light, dark], 'dark')).toEqual([
      'https://cdn.example.com/diagram-dark.webp',
    ])
  })

  it('keeps the original order around a themed pair', () => {
    expect(slidesForTheme([photo, light, dark, photo], 'dark')).toEqual([
      photo,
      'https://cdn.example.com/diagram-dark.webp',
      photo,
    ])
  })

  it('ignores a marker that is not at the end of the URL', () => {
    const odd = 'https://cdn.example.com/a#dark-only.webp'
    expect(slidesForTheme([odd], 'light')).toEqual([odd])
  })

  it('returns an empty list when every slide belongs to the other theme', () => {
    expect(slidesForTheme([dark], 'light')).toEqual([])
  })
})

describe('stripThemeMarker', () => {
  it('removes either marker and leaves other fragments alone', () => {
    expect(stripThemeMarker(light)).toBe('https://cdn.example.com/diagram.webp')
    expect(stripThemeMarker('https://cdn.example.com/a.webp#section')).toBe(
      'https://cdn.example.com/a.webp#section'
    )
  })
})
