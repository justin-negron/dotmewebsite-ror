#!/usr/bin/env bash
# Deploys an API image tag on the Lightsail origin. Runs on the instance as `ubuntu`:
#   /opt/app/deploy.sh <image-tag>
# Renders .env from SSM, pulls the image, migrates, restarts, and waits for health.
# If any step after .env changes fails, restores the previous .env and restarts web.
# Migrations must stay backward-compatible so the previous image runs on the new schema.
set -euo pipefail

TAG="${1:?usage: deploy.sh <image-tag>}"
APP_DIR="${APP_DIR:-/opt/app}"
SSM_PATH=/justinnegron/prod/
export AWS_SHARED_CREDENTIALS_FILE="$APP_DIR/aws-credentials"
export AWS_REGION=us-east-1
cd "$APP_DIR"

rollback() {
  [ -f .env.prev ] || return 0
  mv .env.prev .env
  docker compose up -d --wait --wait-timeout 180 web || echo "==> Rollback: web did not become healthy; check docker compose ps" >&2
  local image
  image="$(grep '^APP_IMAGE=' .env)"
  echo "==> Deploy of $TAG failed; rolled back to ${image##*:}" >&2
}

echo "==> Rendering .env from SSM ($SSM_PATH)"
umask 077
aws ssm get-parameters-by-path --path "$SSM_PATH" --with-decryption --output json \
  | jq -r --arg p "$SSM_PATH" '.Parameters[] | "\(.Name | ltrimstr($p))=\(.Value)"' > .env.new
REPO="$(grep '^ECR_REPOSITORY_URL=' .env.new | cut -d= -f2-)"
echo "APP_IMAGE=${REPO}:${TAG}" >> .env.new
rm -f .env.prev
if [ -f .env ]; then cp .env .env.prev; fi
trap rollback ERR
mv .env.new .env

echo "==> Pulling ${REPO}:${TAG}"
aws ecr get-login-password | docker login --username AWS --password-stdin "${REPO%%/*}" >/dev/null
docker compose pull --quiet web

# compose up recreates caddy whenever its service definition changed, and a
# restart reloads the file, so a bad Caddyfile must be caught before either.
CADDYFILE_CHANGED=0
if ! sha256sum --check --status .caddyfile.sha256 2>/dev/null; then
  echo "==> Caddyfile changed; validating"
  docker compose run --rm --no-deps caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
  CADDYFILE_CHANGED=1
fi

echo "==> Migrating"
docker compose up -d --wait db
docker compose run --rm --no-deps web bin/rails db:migrate

# Checks the origin through the local Caddy: the real secret must reach /health
# and a request without it must be refused. The secret goes to curl on stdin so
# it never appears in a process list or log.
smoke_test() {
  local secret code attempt
  secret="$(grep '^CLOUDFRONT_SECRET=' .env | tail -n 1 | cut -d= -f2- | tr -d '\r' | sed -E 's/^"(.*)"$/\1/')"
  if [ -z "$secret" ]; then
    echo "==> Smoke test: CLOUDFRONT_SECRET missing from .env" >&2
    return 1
  fi
  for attempt in 1 2 3 4 5; do
    code="$(printf 'header = "X-CloudFront-Secret: %s"\n' "$secret" \
      | curl -s -o /dev/null -w '%{http_code}' --max-time 10 \
          --resolve origin.justinnegron.dev:443:127.0.0.1 -K - https://origin.justinnegron.dev/health || true)"
    [ "$code" = 000 ] || break
    sleep 2
  done
  if [ "$code" != 200 ]; then
    echo "==> Smoke test: /health with the secret returned '$code', expected 200" >&2
    return 1
  fi
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 \
    --resolve origin.justinnegron.dev:443:127.0.0.1 https://origin.justinnegron.dev/health || true)"
  if [ "$code" != 403 ]; then
    echo "==> Smoke test: /health without the secret returned '$code', expected 403" >&2
    return 1
  fi
}

# Restores the last Caddyfile that passed the smoke test. The app deploy itself
# is left in place; only the proxy config is reverted.
caddy_rollback() {
  if [ ! -f Caddyfile.good ]; then
    echo "==> Caddy smoke test failed and Caddyfile.good does not exist; fix Caddyfile by hand" >&2
    return 1
  fi
  cp Caddyfile.good Caddyfile
  if docker compose restart caddy && docker compose up -d --wait --wait-timeout 60 caddy && smoke_test; then
    echo "==> Caddy smoke test failed; restored the previous Caddyfile" >&2
  else
    echo "==> Caddy smoke test failed and the restored Caddyfile is also unhealthy; fix Caddy by hand" >&2
    return 1
  fi
}

# Restart Caddy onto the new Caddyfile and prove it serves.
# Chained with && because set -e is suspended inside an `if` condition.
caddy_apply() {
  docker compose restart caddy && docker compose up -d --wait --wait-timeout 60 caddy && smoke_test
}

echo "==> Starting"
docker compose up -d --remove-orphans --wait --wait-timeout 180
trap - ERR
# The stack is healthy, so the rollback copy of the secrets is no longer needed.
rm -f .env.prev
[ -f DEPLOYED_TAG ] && cp DEPLOYED_TAG PREVIOUS_TAG
echo "$TAG" > DEPLOYED_TAG

# A single-file bind mount keeps the old inode after rsync replaces the file, and
# the Caddyfile sets `admin off`, so only a restart loads a changed Caddyfile.
if [ "$CADDYFILE_CHANGED" = 1 ]; then
  echo "==> Restarting caddy"
  if ! caddy_apply; then
    caddy_rollback || true
    exit 1
  fi
  sha256sum Caddyfile > .caddyfile.sha256
  cp Caddyfile Caddyfile.good
fi

docker image prune -af --filter "until=168h" >/dev/null
echo "==> Deployed $TAG"
