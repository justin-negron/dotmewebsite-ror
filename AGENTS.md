# AGENTS.md

Instructions for anyone, human or agent, working in this repository. `CLAUDE.md` includes this file, so Claude Code reads it too; the global rules in `~/.claude/rules/` still apply there. This file adds what is specific to justinnegron.dev, says how work is verified, and says which installed skills and agents to reach for.

## What this is

Justin Negron's portfolio site, live at https://justinnegron.dev. One repo, four parts plus tooling:

| Path | What lives there |
|---|---|
| `backend/` | Rails 8.1 API-only app. Ruby 3.4.8, PostgreSQL 17, Solid Queue, SES mail, Alba serializers, JWT admin auth, RSpec. |
| `frontend/` | Vue 3.5 + TypeScript + Vite 7 + Tailwind CSS 4 single-page app. Pinia, Vue Router, Vitest. |
| `infra/` | Terraform for AWS: S3 + CloudFront for the site and the assets CDN, Lightsail origin, ECR, SES, SSM parameters, S3 backups, Route 53. `infra/architecture/` is the architecture diagram as code. |
| `deploy/` | What runs on the Lightsail origin: Docker Compose (Caddy, Rails, Postgres), `deploy.sh`, `backup-db.sh`, systemd timer. |
| `scripts/` | Operator scripts Justin runs from a laptop: build/push/deploy the API, deploy the frontend, restore the database. |
| `bin/` | `bin/check` runs everything CI runs. `bin/setup-worktree` makes a fresh worktree usable. |
| `.circleci/` | CI runs vue-tsc, the test suites, rubocop, eslint, Prettier, Brakeman, bundler-audit, npm audit, the Vite build and Terraform fmt/init/validate. CI never deploys. |
| `.claude/` | `settings.json` holds the Claude Code permissions for this repo. `settings.local.json` is per machine and gitignored. |
| `docs/` | Gitignored. Local notes only; absent on a fresh clone. Anything that must survive goes in the README or next to the code. |

The repo is public. Treat every tracked file as published.

## Rules for builders

- Work only in the worktree you were given, on the branch it was created with. Never push, merge, rebase or switch branches. Justin pushes and opens the PR.
- If the brief is unclear or seems wrong, stop and ask instead of guessing.
- Verification means `bin/check`. Run it, fix what it reports, run it again until it passes, then commit. Never disable, skip or loosen a test, lint rule, coverage floor or security check to get there.
- A `bin/check` failure that was already there and is outside your brief is not yours to fix. Leave it alone and list it in your summary: the step and the first lines of the error.
- Tests travel with behavior. Add or update specs for what you change (see "Rules specific to this repo").
- Never read or edit `.env` files and never print their contents, in any tool or shell command. `backend/.env.example` is the one exception. `bin/setup-worktree` copies the test credentials into place without showing them, and `.claude/settings.json` denies these reads for Claude Code.
- No new gems, npm packages or tools unless the brief asks for them.
- Terraform is for `fmt -check`, `init -backend=false` and `validate` only, which is what `bin/check` runs. Never `plan`, `apply` or anything that needs AWS credentials.
- Never run the deploy scripts or anything that touches the production box. Those are Justin's.
- Don't edit `.circleci/` or `.github/` unless the brief says so. If CI should change, say so in your summary.
- Commits are conventional (`feat:`, `fix:`, `chore:`, `docs:`, ...) with no attribution footer. Several focused commits beat one.
- When the work is done, stop and write a short summary: what changed, how you tested it with each `bin/check` step's result, what you were unsure about, and anything out of scope you noticed.

## Setup and verification

A fresh worktree has no gitignored files, so it has no gems, no `node_modules` and no database credentials. Run this once from anywhere:

```bash
bin/setup-worktree
```

It copies `backend/.env.test.local` from the main checkout if this worktree has none (never overwriting, never printing it, never touching any other env file), runs `bundle install` in `backend/` and `npm ci` in `frontend/`. Safe to re-run. If the main checkout has no `.env.test.local` it prints a note and carries on; backend tests then need database credentials by hand (see `backend/.env.example` for the variable names).

Then verify with:

```bash
bin/check
```

It runs every step of `.circleci/config.yml`, keeps going after a failure, prints one pass/fail line per step and exits non-zero if any step failed. It installs nothing: a missing tool is a failed step. It sets `CI=1` (CircleCI sets `CI=true`; `backend/spec/spec_helper.rb` turns on the coverage floor when `CI` is set) and `RAILS_ENV=test`, like the CI executor. Running it leaves `git status --short` empty.

| Step | Directory | Command |
|---|---|---|
| backend: load test schema | `backend/` | `bin/rails db:schema:load` |
| backend: rspec | `backend/` | `bundle exec rspec` (coverage floor: 99% lines, 90% branches) |
| backend: rubocop | `backend/` | `bin/rubocop` |
| backend: bundler-audit | `backend/` | `bundle exec bundler-audit check --update` |
| backend: brakeman | `backend/` | `bundle exec brakeman --no-pager -q --exit-on-warn --exit-on-error` |
| frontend: vue-tsc | `frontend/` | `npx --no -- vue-tsc --build --force` |
| frontend: eslint | `frontend/` | `npx --no -- eslint .` |
| frontend: prettier | `frontend/` | `npx --no -- prettier --check src/` |
| frontend: vitest | `frontend/` | `npx --no -- vitest run --passWithNoTests` |
| frontend: npm audit | `frontend/` | `npm audit --audit-level=high --omit=dev` |
| frontend: vite build | `frontend/` | `npx --no -- vite build` |
| infra: terraform fmt | `infra/` | `terraform fmt -check -recursive` |
| infra: terraform init | `infra/` | `terraform init -backend=false -input=false` |
| infra: terraform validate | `infra/` | `terraform validate` |

Notes on the steps:
- `npx --no -- <tool>` runs the binary installed in `node_modules` and fails if it is missing, where plain `npx` would download it. The `--` stops npm from reading the tool's flags (such as `--check`) as its own. With packages installed it runs the same tool and flags CI runs.
- The test database is `portfolio_test` on the local Postgres, shared by every worktree on the machine. `db:schema:load` resets its tables, which is also what CI does on a fresh database.
- `bundler-audit --update` refreshes the advisory database and `npm audit` and `terraform init` reach the network. None of them change tracked files.
- CI runs Node 22; `frontend/package.json` `engines` accepts Node 22, 24 and 26 lines. `npm ci` warns on a Node outside those ranges but still installs.

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
npm run test:coverage                     # vitest with coverage; the only command that checks the thresholds in vitest.config.js
npm run build                             # typecheck + production build
```

Diagrams, from the repo root (safe for builders):

```bash
node infra/architecture/render.mjs        # regenerate the architecture SVGs (light and dark)
```

Infra and deploy, from the repo root. Justin's commands only; builders never run these:

```bash
terraform -chdir=infra plan               # apply only when Justin says so
scripts/deploy-backend.sh                 # build, push to ECR, deploy on the origin
TAG=<sha12> scripts/deploy-backend.sh     # redeploy an existing image (rollback)
scripts/deploy-frontend.sh                # build, S3 sync, CloudFront invalidation
```

Verification before any commit is `bin/check`. Report each step's result. CircleCI fails on a Brakeman warning, a bundler-audit advisory, a high npm advisory or a rubocop offense, and validates the Terraform; so does `bin/check`.

## Architecture in one screen

Request path: browser, then CloudFront, then either S3 (site files) or `/api/*` to Caddy on Lightsail, then Puma/Rails, then Postgres on the same box. Images come from `assets.justinnegron.dev`, a private bucket behind CloudFront with an immutable cache. The full picture is `infra/architecture/system-architecture.svg`.

Backend
- Every endpoint is under `/api/v1/` and inherits `Api::V1::BaseController`, which renders `{ success, data, meta }` or `{ success: false, message, errors }`. Keep that envelope.
- Serialization is Alba in `app/resources/`. `to_h` returns string keys.
- Public routes: projects, experiences, blog posts by slug, contact create, analytics track. Admin routes need a JWT (`Authenticatable` concern, `JwtService`) and cover CRUD, publish/unpublish, S3 presigned uploads and the dashboard.
- Jobs run in Solid Queue inside Puma (`SOLID_QUEUE_IN_PUMA` in `config/puma.rb`). No Redis, no Sidekiq.
- Per-action rate limits use Rails `rate_limit` through the `throttle` helper in the base controller (keyed on the routed action); `rack-attack` keeps only the global cap. `CloudfrontSecretMiddleware` rejects requests that did not come through CloudFront, and Caddy on the origin drops them even earlier.
- Page views store a keyed, daily-salted visitor hash, never the IP, and are purged after `PAGE_VIEW_RETENTION_DAYS` (default 90) by the recurring job in `config/recurring.yml`.
- `db/seeds.rb` is the source of truth for project and experience content. Seeds match projects by title and experiences by company plus start date, and never modify an existing row.

Frontend
- `<script setup lang="ts">` everywhere. Path aliases (`@/`, `@components/`, `@stores/`, ...) are declared in both `vite.config.js` and `tsconfig.app.json`.
- Data flows from `services/*.ts` (typed Axios) to Pinia stores to components. Each store keeps its own `loading` and `error` refs; there is no shared `useApi` composable.
- Tailwind 4 is CSS-first. Tokens, `@utility` classes and the `dark` variant live in `src/assets/styles/main.css`. There is no `tailwind.config.js`.
- Dark mode is a `.dark` class on `<html>` managed by `composables/useTheme.ts`. In scoped styles write `:is(.dark *) .foo`, not `dark:`. Four color skins are CSS variables set by `useAppearance.ts`.
- Project media: `media_urls` is an ordered list of CDN URLs. A URL ending in `#light-only` or `#dark-only` shows in that theme only (`utils/themedMedia.ts`).
- The blog is off the public nav, but its routes, views and admin CRUD stay. Do not remove them.
- `frontend/` carries a husky + lint-staged config, but it is not wired to this repo (`core.hooksPath` is unset), so lint and format checks run only by hand, in `bin/check` and in CI. `bin/setup-worktree` runs `npm ci` with `HUSKY=0` so it stays that way.

Infra and deploy
- Terraform state is remote in S3. `infra/terraform.tfvars` is gitignored.
- Production config is rendered from SSM Parameter Store by `deploy/deploy.sh`. No production `.env` exists in the repo.
- A systemd timer runs `backup-db.sh` nightly to S3; `scripts/restore-db.sh` restores from a dump or an S3 URI.
- The assets CDN caches for a year. Never overwrite an object key; upload under a new name.

## Rules specific to this repo

- No secrets in tracked files. `.env*`, `master.key` and `terraform.tfvars` stay ignored. Brakeman stays at zero warnings.
- Commits are conventional (`feat:`, `fix:`, `chore:`, ...) with no attribution footer. Builders never push. Justin pushes from his machine with `git -c credential.helper='!gh auth git-credential' push <remote-url> <branch>`.
- Justin branches from `main`, opens the PR and lets CircleCI pass. Builders stay on the branch their worktree was created with and leave branching, pushing and the PR to him. Deploys, Terraform apply and anything that touches the production box happen only on Justin's explicit go-ahead, and he runs them.
- Preview before commit. Justin reviews UI and copy changes at http://localhost:5173 before anything is committed. After editing `db/seeds.rb`, reseed the dev database; the preview shows rows, not the file.
- The content is Justin's. Site copy is casual, plain English, short sentences; run `anthropic-skills:humanizer` or `pstack:unslop` over new copy. Never add employers, clients, contracts, personal details or numbers he has not given in the conversation. No hire-me or open-to-work wording. Project images are real artifacts only. The Discord bot's paper acknowledges Justin; it is not his publication. The detailed checklist is `docs/CONTENT.md` (local only; ask if it is missing).
- Images never go in git. Upload to the assets bucket and reference the CDN URL.
- Tests travel with behavior: backend changes get specs under `spec/models`, `spec/requests` or `spec/resources`; frontend logic gets a Vitest spec in a sibling `__tests__/`. The backend coverage floor is 99 percent of lines and 90 percent of branches, enforced whenever `CI` is set (CircleCI sets it, `bin/check` sets `CI=1`). Frontend coverage thresholds live in `vitest.config.js`, but only `npm run test:coverage` checks them; CI and `bin/check` run vitest without coverage.

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
- `bin/check` is the checklist; `verification-loop` or `/verify` wrap it. `ecc:security-scan` or `security-review` before commits touching inputs or secrets.
- `ecc:conventional-commit-review` or the `ecc:commit-reviewer` agent for the message; `pstack:make-pr-easy-to-review` and `ecc:pr` for the pull request Justin opens.

Live site health
- `audit-website` (squirrelscan, configured by `squirrel.toml` at the root) for a crawl covering SEO, performance and broken links; `ecc:seo` and the `ecc:seo-specialist` agent for meta tags and structured data; `performance` for load-time work; `ecc:browser-qa` for post-deploy smoke checks.

Copy and docs
- `anthropic-skills:humanizer` and `pstack:unslop` on any user-facing text. `pstack:technical-writing` for README and runbook changes. Record real decisions in the README; `docs/adr/` would be gitignored.

Debugging
- `diagnosing-bugs` for anything broken with no known cause. `pstack:blast-radius` before shipping a small change that is hard to trust.

Not relevant here, skip them: React, Next.js, Nuxt, Django, Laravel, Spring, Kotlin, Swift, Go, Rust, Redis, Sidekiq, healthcare, trading, networking and homelab skills.

## Known gaps

- No end-to-end tests yet. When they arrive, `e2e-testing` and the `e2e-runner` agent apply. Playwright's Chromium does not run on Justin's WSL box without system libraries.
- CI tests but does not deploy. Deploys are the two scripts in `scripts/`, run by Justin.
- The About section has no photos yet.
- The README is out of date (it still says Rails 7). This file and the code are the source of truth until it is rewritten.
