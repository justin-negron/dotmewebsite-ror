// The full C4 container view: every deployable unit, with a sentence each.
// Meant for the README and for anyone who wants to understand the system;
// too dense for the portfolio card (see overview.mjs for that).

import { canvas, KIND_LABELS } from './svg.mjs'

export function render(theme = 'light') {
  const c = canvas({ width: 2000, height: 1290, theme, title: 'justinnegron.dev system architecture (C4 container view)' })
  const { text, raw, node, note, boundary, edge, legendSwatch, legendArrow, palette } = c
  const { line: LINE, muted: MUTED } = palette

  text(60, 80, 'justinnegron.dev — system architecture', { size: 34, weight: 700 })
  text(
    60,
    112,
    'C4 container view · Vue 3 single-page app on CloudFront + S3 · Rails 8.1 API on Lightsail behind the same distribution · AWS us-east-1, managed with Terraform · October 2026',
    { size: 16, fill: MUTED },
  )

  raw(`<rect x="60" y="200" width="260" height="295" rx="12" fill="${palette.legendFill}" stroke="${palette.legendStroke}" stroke-width="1.5"/>`)
  text(76, 228, 'Legend', { size: 15, weight: 700, fill: LINE })
  let ly = 252
  for (const kind of ['person', 'app', 'service', 'data', 'aws', 'delivery']) {
    legendSwatch(76, ly, kind, KIND_LABELS[kind])
    ly += 28
  }
  legendArrow(76, ly, 'Runtime request / data flow')
  legendArrow(76, ly + 28, 'Deploy & operations', { dashed: true })

  node({ x: 60, y: 532, w: 260, h: 140, kind: 'person', name: 'Visitor', pill: 'Person · any browser', desc: 'Reads the portfolio, submits the contact form.' })
  node({ x: 60, y: 712, w: 260, h: 140, kind: 'person', name: 'Justin (admin)', pill: 'Person · browser', desc: 'Signs in at /admin to edit projects, experience and blog posts, and to upload images.' })

  boundary({ x: 420, y: 200, w: 460, h: 760, title: 'Edge', sub: 'Amazon CloudFront · Route 53 · ACM' })
  node({ x: 450, y: 250, w: 400, h: 150, kind: 'aws', name: 'assets.justinnegron.dev', pill: 'Amazon CloudFront', desc: 'Serves project and blog images from the assets bucket through an origin access control. Immutable caching: 30-day default, 1-year maximum.' })
  node({ x: 450, y: 440, w: 400, h: 360, kind: 'aws', name: 'justinnegron.dev', pill: 'Amazon CloudFront', descSize: 16, desc: 'Default behavior: the single-page app from the site bucket via origin access control, with 403/404 rewritten to index.html for client-side routing. /api/* and /health: proxied to the Lightsail origin over HTTPS with caching disabled and an X-CloudFront-Secret header the API verifies. A CloudFront Function redirects www to the apex. HTTP/2 and HTTP/3, edges in North America and Europe.' })
  node({ x: 450, y: 825, w: 400, h: 120, kind: 'aws', name: 'DNS & certificates', pill: 'Route 53 · ACM', desc: 'A/AAAA records for apex, www, assets and origin. One ACM certificate (apex + wildcard).' })

  boundary({ x: 940, y: 200, w: 1000, h: 760, title: 'AWS · us-east-1', sub: 'Every resource here is declared in infra/ (Terraform, remote state in S3)' })
  node({ x: 970, y: 250, w: 280, h: 150, kind: 'data', name: 'Assets bucket', pill: 'Amazon S3 · private · versioned', desc: 'Project and blog images. Browser uploads go straight here via presigned PUT URLs from the API.' })
  node({ x: 1290, y: 250, w: 280, h: 150, kind: 'app', name: 'Site bucket', pill: 'Amazon S3 · private · versioned', desc: 'The Vue 3 + TypeScript build: index.html plus hashed JS and CSS. Readable only through CloudFront.' })

  boundary({ x: 970, y: 440, w: 630, h: 355, title: 'Lightsail · justinnegron-app · 443 public, SSH from one IP', sub: 'Ubuntu 24.04 · static IP · Docker Compose' })
  node({ x: 995, y: 507, w: 130, h: 190, kind: 'service', name: 'Caddy 2', pill: 'Reverse proxy', descSize: 13, desc: "Let's Encrypt TLS. Proxies to web:3000, keeps X-Forwarded-For." })
  node({ x: 1180, y: 507, w: 205, h: 190, kind: 'service', name: 'Rails 8.1 API', pill: 'Ruby 3.4 · Puma', descSize: 13.5, desc: 'JSON API at /api/v1 (Alba). JWT admin auth, Rack::Attack limits, CloudFront-secret check. Solid Queue in-process.' })
  node({ x: 1440, y: 507, w: 150, h: 190, kind: 'data', name: 'Postgres 17', pill: 'Database', nameSize: 17, descSize: 13, desc: 'Content, contacts, page views, Solid Queue jobs. Docker volume.' })
  note({ x: 995, y: 715, w: 295, h: 62, title: 'deploy.sh', body: '.env from SSM · docker pull from ECR · db:migrate · compose up --wait' })
  note({ x: 1310, y: 715, w: 265, h: 62, title: 'Backup timer · daily 08:30 UTC', body: 'pg_dump of the database → backups bucket' })

  node({ x: 1660, y: 250, w: 250, h: 150, kind: 'aws', name: 'Transactional email', pill: 'Amazon SES v2', desc: 'Contact-form notifications to Justin from notifications@justinnegron.dev. DKIM, SPF and DMARC set up.' })
  node({ x: 1660, y: 440, w: 250, h: 150, kind: 'aws', name: 'Secrets & config', pill: 'SSM Parameter Store', desc: 'DB password, SECRET_KEY_BASE, JWT and CloudFront secrets, mail settings.' })
  node({ x: 1660, y: 630, w: 250, h: 135, kind: 'aws', name: 'Container registry', pill: 'Amazon ECR', desc: 'justinnegron-api images tagged by git SHA. CVE scan on push, last 5 kept.' })
  node({ x: 1660, y: 805, w: 250, h: 120, kind: 'data', name: 'Backups bucket', pill: 'Amazon S3 · AES-256 · versioned', desc: 'Daily database dumps, 35-day retention.' })

  boundary({ x: 60, y: 1010, w: 1880, h: 225, title: 'Delivery & operations', sub: 'Tests run in CI on every push · deploys are run from the workstation with the scripts below' })
  node({ x: 90, y: 1065, w: 240, h: 150, kind: 'person', name: 'Justin (developer)', pill: 'Person · workstation', descSize: 13.5, desc: 'Pushes to GitHub; runs Terraform and the deploy scripts locally.' })
  node({ x: 370, y: 1065, w: 230, h: 150, kind: 'delivery', name: 'Source repository', pill: 'GitHub · public', descSize: 13.5, desc: 'backend/ (Rails), frontend/ (Vue), infra/ (Terraform), deploy/ (host files), scripts/.' })
  node({ x: 640, y: 1065, w: 260, h: 150, kind: 'delivery', name: 'CI pipeline', pill: 'CircleCI', descSize: 13.5, desc: 'Every push: RSpec and Brakeman for the API; ESLint, Vitest and a production build for the SPA. Deploys stay manual.' })
  node({ x: 950, y: 1065, w: 260, h: 150, kind: 'delivery', name: 'Infrastructure as code', pill: 'Terraform', descSize: 13.5, desc: 'Declares every AWS resource shown here; remote state in S3.' })
  node({ x: 1260, y: 1065, w: 300, h: 150, kind: 'delivery', name: 'deploy-frontend.sh', pill: 'Script', descSize: 13.5, desc: 'npm run build → aws s3 sync to the site bucket → CloudFront invalidation.' })
  node({ x: 1610, y: 1065, w: 300, h: 150, kind: 'delivery', name: 'deploy-backend.sh', pill: 'Script', descSize: 13.5, desc: 'docker build (linux/amd64) → push to ECR → rsync deploy/ → ssh deploy.sh <tag>. Re-run with TAG=<sha> to roll back.' })

  edge([[320, 602], [450, 602]], { label: ['HTTPS', 'SPA + /api/v1'], at: [385, 575] })
  edge([[320, 782], [450, 782]], { label: ['HTTPS · /admin', 'JWT bearer'], at: [385, 755] })
  edge([[320, 552], [385, 552], [385, 325], [450, 325]], { label: 'images', at: [392, 424], anchor: 'start' })
  edge([[850, 325], [970, 325]], { label: 'OAC · images', at: [910, 312] })
  edge([[850, 480], [900, 480], [900, 425], [1430, 425], [1430, 400]], { label: 'OAC (SigV4) · SPA files', at: [1165, 416] })
  edge([[850, 602], [995, 602]], { label: ['/api/* · /health', 'HTTPS + secret header'], at: [922, 575] })
  edge([[1125, 602], [1180, 602]], { label: 'HTTP', at: [1152, 594] })
  edge([[1385, 602], [1440, 602]], { label: 'SQL', at: [1412, 594] })
  edge([[1380, 507], [1380, 497], [1630, 497], [1630, 325], [1660, 325]], { label: ['SES v2 · SendEmail', '(Solid Queue job)'], at: [1622, 418], anchor: 'end' })

  edge([[1660, 520], [1600, 520]], { label: 'to .env', at: [1656, 508], anchor: 'end', dashed: true })
  edge([[1660, 680], [1600, 680]], { label: 'docker pull', at: [1656, 668], anchor: 'end', dashed: true })
  edge([[1575, 746], [1630, 746], [1630, 865], [1660, 865]], { label: 'pg_dump · daily', at: [1622, 810], anchor: 'end', dashed: true })
  edge([[330, 1140], [370, 1140]], { label: 'git push', at: [350, 1128], dashed: true })
  edge([[600, 1140], [640, 1140]], { label: 'webhook', at: [620, 1128], dashed: true })
  edge([[1080, 1065], [1080, 960]], { label: 'terraform apply', at: [1092, 1012], anchor: 'start', dashed: true })
  edge([[1410, 1065], [1410, 960]], { label: 's3 sync + invalidation', at: [1422, 1012], anchor: 'start', dashed: true })
  edge([[1760, 1065], [1760, 960]], { label: 'docker push · ssh deploy.sh', at: [1772, 1012], anchor: 'start', dashed: true })

  text(60, 1266, 'Source: infra/architecture/render.mjs → system-architecture.svg · github.com/justin-negron/dotmewebsite-ror', { size: 12.5, fill: palette.footer })
  return c
}
