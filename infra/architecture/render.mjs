#!/usr/bin/env node
// Writes the architecture diagrams next to this file, each in a light and a
// dark palette (the site swaps slides with its theme; GitHub can do the same
// with a <picture> element):
//   system-architecture[-dark].svg  full C4 container view (detailed.mjs), for GitHub
//   system-overview[-dark].svg      glance version (overview.mjs), the portfolio card slide
//
//   node infra/architecture/render.mjs
//
// No dependencies. The card slide is system-overview.svg rasterized to a
// lossless WebP (2400 px wide) and uploaded to the assets bucket under a new
// key whenever it changes, because the CDN caches immutably.

import { writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { render as detailed } from './detailed.mjs'
import { render as overview } from './overview.mjs'

const here = dirname(fileURLToPath(import.meta.url))
for (const [name, build] of [['system-architecture', detailed], ['system-overview', overview]]) {
  for (const theme of ['light', 'dark']) {
    const file = theme === 'dark' ? `${name}-dark.svg` : `${name}.svg`
    const c = build(theme)
    const svg = c.toString()
    writeFileSync(join(here, file), svg)
    console.log(`wrote ${file} (${(svg.length / 1024).toFixed(1)} KB)`)
    for (const w of c.warnings) console.warn('  warning:', w)
  }
}
