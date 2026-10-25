// The glance version for the portfolio card: the same system with a name and
// one technology line per box, one or two words per arrow, and nothing to read.

import { canvas } from './svg.mjs'

export function render(theme = 'light') {
  const c = canvas({ width: 2000, height: 960, theme, title: 'justinnegron.dev architecture overview' })
  const { text, node, boundary, edge, legendBox, palette } = c
  const { muted: MUTED } = palette
  const big = { nameSize: 24, tagSize: 15 }

  text(80, 84, 'justinnegron.dev', { size: 36, weight: 700 })
  text(80, 116, 'Vue 3 on CloudFront + S3 · Rails 8.1 API on Lightsail · AWS · Terraform', { size: 17, fill: MUTED })

  node({ x: 80, y: 330, w: 260, h: 130, kind: 'person', name: 'Browser', tag: 'visitors', ...big })

  boundary({ x: 420, y: 200, w: 400, h: 520, title: 'Edge · Amazon CloudFront', titleSize: 17 })
  node({ x: 450, y: 280, w: 340, h: 140, kind: 'aws', name: 'justinnegron.dev', tag: 'CloudFront · Route 53 · ACM', ...big })
  node({ x: 450, y: 520, w: 340, h: 140, kind: 'aws', name: 'assets.justinnegron.dev', tag: 'CloudFront · S3 bucket · images', ...big })

  boundary({ x: 900, y: 200, w: 1040, h: 520, title: 'AWS', titleSize: 17 })
  node({ x: 940, y: 280, w: 260, h: 140, kind: 'app', name: 'Site bucket', tag: 'S3 · Vue 3 + TypeScript build', ...big })
  node({ x: 940, y: 560, w: 260, h: 130, kind: 'aws', name: 'ECR', tag: 'API container images', ...big })

  boundary({ x: 1280, y: 250, w: 620, h: 290, title: 'Lightsail · Docker Compose', titleSize: 17 })
  node({ x: 1310, y: 370, w: 160, h: 130, kind: 'service', name: 'Caddy', tag: 'TLS · reverse proxy', ...big })
  node({ x: 1510, y: 370, w: 170, h: 130, kind: 'service', name: 'Rails API', tag: 'Ruby 3.4 · Puma', ...big })
  node({ x: 1720, y: 370, w: 150, h: 130, kind: 'data', name: 'Postgres', tag: 'v17', ...big })

  node({ x: 1510, y: 580, w: 170, h: 110, kind: 'aws', name: 'SES', tag: 'contact emails', ...big })
  node({ x: 1720, y: 580, w: 150, h: 110, kind: 'data', name: 'Backups', tag: 'S3 · daily', ...big })

  boundary({ x: 80, y: 770, w: 1860, h: 165, title: 'Delivery', titleSize: 17 })
  node({ x: 120, y: 815, w: 280, h: 95, kind: 'delivery', name: 'GitHub', tag: 'source · public repo', ...big })
  node({ x: 480, y: 815, w: 280, h: 95, kind: 'delivery', name: 'CircleCI', tag: 'RSpec · Vitest · Brakeman', ...big })
  node({ x: 840, y: 815, w: 280, h: 95, kind: 'delivery', name: 'Terraform', tag: 'infrastructure as code', ...big })
  node({ x: 1200, y: 815, w: 420, h: 95, kind: 'delivery', name: 'Deploy scripts', tag: 'build → S3 · docker → ECR → ssh', ...big })

  const L = { size: 15 }
  edge([[340, 380], [450, 380]], { label: 'HTTPS', at: [395, 368], ...L })
  edge([[340, 430], [380, 430], [380, 590], [450, 590]], { label: 'images', at: [390, 515], anchor: 'start', ...L })
  edge([[790, 330], [940, 330]], { label: 'site files', at: [865, 318], ...L })
  edge([[790, 400], [860, 400], [860, 435], [1310, 435]], { label: '/api/*', at: [1240, 423], ...L })
  edge([[1470, 435], [1510, 435]], L)
  edge([[1680, 435], [1720, 435]], { label: 'SQL', at: [1700, 423], ...L })
  edge([[1595, 500], [1595, 580]], { label: 'email', at: [1607, 547], anchor: 'start', ...L })
  edge([[1795, 500], [1795, 580]], { label: 'pg_dump', at: [1807, 547], anchor: 'start', dashed: true, ...L })
  edge([[1200, 625], [1240, 625], [1240, 510], [1280, 510]], { label: 'docker pull', at: [1252, 598], anchor: 'start', dashed: true, ...L })

  edge([[400, 862], [480, 862]], { label: 'push', at: [440, 850], dashed: true, ...L })
  edge([[980, 815], [980, 720]], { label: 'apply', at: [992, 772], anchor: 'start', dashed: true, ...L })
  edge([[1410, 815], [1410, 720]], { label: 'deploy', at: [1422, 772], anchor: 'start', dashed: true, ...L })

  legendBox(80, 490)
  return c
}
