# CLAUDE.md

Guidance for Claude Code in this repository. The global rules in `~/.claude/rules/` still apply; this file adds what is specific to justinnegron.dev and says which installed skills and agents to reach for.

## What this is

Justin Negron's portfolio site, live at https://justinnegron.dev. One repo, four parts:

| Path | What lives there |
|---|---|
| `backend/` | Rails 8.1 API-only app. Ruby 3.4.8, PostgreSQL 17, Solid Queue, SES mail, Alba serializers, JWT admin auth, RSpec. |
| `frontend/` | Vue 3.5 + TypeScript + Vite 7 + Tailwind CSS 4 single-page app. Pinia, Vue Router, Vitest. |
| `infra/` | Terraform for AWS: S3 + CloudFront for the site and the assets CDN, Lightsail origin, ECR, SES, SSM parameters, S3 backups, Route 53. `infra/architecture/` is the architecture diagram as code. |
| `deploy/` | What runs on the Lightsail origin: Docker Compose (Caddy, Rails, Postgres), `deploy.sh`, `backup-db.sh`, systemd timer. |
| `scripts/` | Operator scripts run from a laptop: build/push/deploy the API, deploy the frontend, restore the database. |
| `.circleci/` | CI runs the test suites, rubocop, eslint, Prettier, Brakeman, bundler-audit, npm audit and Terraform fmt/validate. CI never deploys. |
| `docs/` | Gitignored. Local notes only; absent on a fresh clone. Anything that must survive goes in the README or next to the code. |

The repo is public. Treat every tracked file as published.

## Commands

Backend, from `backend/`. Always `bin/rails`, never bare `rails` (rbenv on WSL2).

```bash
bin/rails s -p 3000                                # API server
bundle exec rspec                                  # full suite, SimpleCov report in coverage/
bundle exec rspec spec/models/project_spec.rb:12   # one example
bin/rubocop                                        # rubocop-rails-omakase
bin/brakeman --quiet --no-pager                    # static security scan, keep it at 0 warnings
bin/bundler-audit                                  # gem CVE check
bin/ci                                             # setup + rubocop + bundler-audit + brakeman (config/ci.rb)
bin/rails db:migrate && bin/rails db:seed
bin/rails runner 'Project.delete_all' && bin/rails db:seed   # reload project rows after editing db/seeds.rb
```

Frontend, from `frontend/`:

```bash
npm run dev -- --port 5173 --strictPort   # Vite; /api is proxied to :3000
npm run typecheck                         # vue-tsc
npm run lint:check && npm run format:check
npx vitest run                            # unit tests (jsdom); add a path to run one file
npm run build                             # typecheck + production build
```

Infra, deploy and diagrams, from the repo root:

```bash
terraform -chdir=infra plan               # apply only when Justin says so
scripts/deploy-backend.sh                 # build, push to ECR, deploy on the origin
TAG=<sha12> scripts/deploy-backend.sh     # redeploy an existing image (rollback)
scripts/deploy-frontend.sh                # build, S3 sync, CloudFront invalidation
node infra/architecture/render.mjs        # regenerate the architecture SVGs (light and dark)
```

Verification before any commit: `bundle exec rspec` and `bin/brakeman` in the backend, then `npm run typecheck`, `npm run lint:check`, `npx vitest run` and `npm run build` in the frontend. Report the numbers. CircleCI fails on a Brakeman warning, a bundler-audit advisory, a high npm advisory or a rubocop offense, and validates the Terraform.

## Architecture in one screen

Request path: browser, then CloudFront, then either S3 (site files) or `/api/*` to Caddy on Lightsail, then Puma/Rails, then Postgres on the same box. Images come from `assets.justinnegron.dev`, a private bucket behind CloudFront with an immutable cache. The full picture is `infra/architecture/system-architecture.svg`.

Backend
- Every endpoint is under `/api/v1/` and inherits `Api::V1::BaseController`, which renders `{ success, data, meta }` or `{ success: false, message, errors }`. Keep that envelope.
- Serialization is Alba in `app/resources/`. `to_h` returns string keys.
- Public routes: projects, experiences, blog posts by slug, contact create, analytics track. Admin routes need a JWT (`Authenticatable` concern, `JwtService`) and cover CRUD, publish/unpublish, S3 presigned uploads and the dashboard.
- Jobs run in Solid Queue inside Puma. No Redis, no Sidekiq.
- Per-action rate limits use Rails `rate_limit` through the `throttle` helper in the base controller (keyed on the routed action); `rack-attack` keeps only the global cap. `CloudfrontSecretMiddleware` rejects requests that did not come through CloudFront, and Caddy on the origin drops them even earlier.
- Page views store a keyed, daily-salted visitor hash, never the IP, and are purged after `PAGE_VIEW_RETENTION_DAYS` (default 90).
- `db/seeds.rb` is the source of truth for project and experience content. Seeds match rows by title and never modify an existing row.

Frontend
- `<script setup lang="ts">` everywhere. Path aliases (`@/`, `@components/`, `@stores/`, ...) are declared in both `vite.config.js` and `tsconfig.app.json`.
- Data flows from `services/*.ts` (typed Axios) to Pinia stores to components. `composables/useApi.ts` wraps loading and error state.
- Tailwind 4 is CSS-first. Tokens, `@utility` classes and the `dark` variant live in `src/assets/styles/main.css`. There is no `tailwind.config.js`.
- Dark mode is a `.dark` class on `<html>` managed by `composables/useTheme.ts`. In scoped styles write `:is(.dark *) .foo`, not `dark:`. Four color skins are CSS variables set by `useAppearance.ts`.
- Project media: `media_urls` is an ordered list of CDN URLs. A URL ending in `#light-only` or `#dark-only` shows in that theme only (`utils/themedMedia.ts`).
- The blog is off the public nav, but its routes, views and admin CRUD stay. Do not remove them.
- `frontend/` carries a husky + lint-staged config, but it is not wired to this repo (`core.hooksPath` is unset), so lint and format checks run only by hand and in CI.

Infra and deploy
- Terraform state is remote in S3. `infra/terraform.tfvars` is gitignored.
- Production config is rendered from SSM Parameter Store by `deploy/deploy.sh`. No production `.env` exists in the repo.
- A systemd timer runs `backup-db.sh` nightly to S3; `scripts/restore-db.sh` restores from a dump or an S3 URI.
- The assets CDN caches for a year. Never overwrite an object key; upload under a new name.

## Rules specific to this repo

- No secrets in tracked files. `.env*`, `master.key` and `terraform.tfvars` stay ignored. Brakeman stays at zero warnings.
- Commits are conventional (`feat:`, `fix:`, `chore:`, ...) with no attribution footer. On this machine, push with `git -c credential.helper='!gh auth git-credential' push <remote-url> <branch>`.
- Branch from `main`, open a PR, let CircleCI pass. Deploys, Terraform apply and anything that touches the production box happen only on Justin's explicit go-ahead.
- Preview before commit. Justin reviews UI and copy changes at http://localhost:5173 before anything is committed. After editing `db/seeds.rb`, reseed the dev database; the preview shows rows, not the file.
- The content is Justin's. Site copy is casual, plain English, short sentences; run `anthropic-skills:humanizer` or `pstack:unslop` over new copy. Never add employers, clients, contracts, personal details or numbers he has not given in the conversation. No hire-me or open-to-work wording. Project images are real artifacts only. The Discord bot's paper acknowledges Justin; it is not his publication. The detailed checklist is `docs/CONTENT.md` (local only; ask if it is missing).
- Images never go in git. Upload to the assets bucket and reference the CDN URL.
- Tests travel with behavior: backend changes get specs under `spec/models`, `spec/requests` or `spec/resources`; frontend logic gets a Vitest spec in a sibling `__tests__/`. Backend line coverage is above 99 percent and CI enforces a floor (`CI=1 bundle exec rspec`). Frontend coverage is enforced by the thresholds in `vitest.config.js`.

## Skills and agents: what to use when

Load the skill before writing code in that area. Agents run through the Agent tool. Names with a prefix come from plugins (`ecc:`, `pstack:`, `anthropic-skills:`); the rest are installed at user level.

Shaping the work
- `pstack:poteto-mode` for anything touching more than one file or making a design choice; it routes to `pstack:architect`, `pstack:tdd`, `pstack:how` and `pstack:why`. The `planner` agent for multi-phase features.
- `ecc:search-first` before adding a dependency or writing a utility that may exist.
- `grilling` to stress-test a plan; `codebase-design` and `domain-modeling` when the question is where a module seam belongs.

Backend (Rails)
- Skills: `ecc:rails-patterns` (Rails 8 and the Solid stack), `rails-testing` (RSpec, factories, request specs), `api-design` (envelope, status codes, pagination), `ecc:postgres-patterns`, `ecc:database-migrations` (reversible, zero-downtime).
- Agents: `tdd-guide` to drive red-green-refactor; `ecc:ruby-reviewer` on every Ruby diff; `database-reviewer` on migrations and query changes; `security-reviewer` on anything in auth, uploads, contacts, rack-attack or CORS.

Frontend (Vue, TypeScript, Tailwind)
- Skills: `vue-best-practices` for any `.vue` work, `vue-pinia-best-practices` for stores, `vue-testing-best-practices` and `vitest` for specs, `vue-debug-guides` for reactivity bugs and runtime warnings, `vuejs-typescript-best-practices`, `pstack:typescript-best-practices`, `ecc:vite-patterns` for config and the proxy.
- Styling: `tailwindcss-mobile-first` (v4), `tailwind-css-patterns`, `tailwindcss-animations`, `ecc:make-interfaces-feel-better` for polish passes, `frontend-design` when designing something new, `ecc:accessibility` for keyboard, ARIA and contrast (the lightbox, the terminal, the admin forms).
- Agents: `ecc:vue-reviewer` and `ecc:typescript-reviewer` on every frontend diff; `ecc:a11y-architect` for new interactive components; `ecc:performance-optimizer` when bundle size or render performance regresses; `build-error-resolver` when vue-tsc or Vite fails.

Infra, deploy and AWS
- Skills: `terraform-style-guide` for `infra/*.tf`; `aws-iam` for `app_iam.tf` and bucket policies; `securing-s3-buckets` when touching the site, assets or backup buckets; `aws-billing-and-cost-management` for the monthly bill review; `ecc:docker-patterns` for `backend/Dockerfile` and `deploy/compose.yaml`; `ecc:deployment-patterns` and `ci-cd-best-practices` for `.circleci/` and the deploy scripts; `pstack:fix-ci` when CircleCI is red.
- Diagrams: `infra/architecture/*.mjs` are the source. Use `artifact-diagramming` for layout and legibility rules when changing them.

Quality gates before a PR
- `code-reviewer` on the diff, plus the language reviewers above. `ecc:silent-failure-hunter` on error-handling changes. `ecc:pr-test-analyzer` to check that the tests cover behavior rather than implementation.
- `pstack:thermo-nuclear-review` for a security and correctness audit of the whole branch before merging anything that touches auth, uploads or infra. `pstack:thermo-nuclear-code-quality-review` when a file is getting long.
- `verification-loop` or `/verify` to run the full checklist. `ecc:security-scan` or `security-review` before commits touching inputs or secrets.
- `ecc:conventional-commit-review` or the `ecc:commit-reviewer` agent for the message; `pstack:make-pr-easy-to-review` and `ecc:pr` for the pull request.

Live site health
- `audit-website` (squirrelscan, configured by `squirrel.toml` at the root) for a crawl covering SEO, performance and broken links; `ecc:seo` and the `ecc:seo-specialist` agent for meta tags and structured data; `performance` for load-time work; `ecc:browser-qa` for post-deploy smoke checks.

Copy and docs
- `anthropic-skills:humanizer` and `pstack:unslop` on any user-facing text. `pstack:technical-writing` for README and runbook changes. Record real decisions in the README; `docs/adr/` would be gitignored.

Debugging
- `diagnosing-bugs` for anything broken with no known cause. `pstack:blast-radius` before shipping a small change that is hard to trust.

Not relevant here, skip them: React, Next.js, Nuxt, Django, Laravel, Spring, Kotlin, Swift, Go, Rust, Redis, Sidekiq, healthcare, trading, networking and homelab skills.

## Known gaps

- No end-to-end tests yet. When they arrive, `e2e-testing` and the `e2e-runner` agent apply. Playwright's Chromium does not run on this WSL box without system libraries.
- CI tests but does not deploy. Deploys are the two scripts in `scripts/`, run by Justin.
- The About section has no photos yet.
