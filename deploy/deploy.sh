#!/usr/bin/env bash
# Deploys an API image tag on the Lightsail origin. Runs on the instance as `ubuntu`:
#   /opt/app/deploy.sh <image-tag>
# Renders .env from SSM, pulls the image, migrates, restarts, and waits for health.
set -euo pipefail

TAG="${1:?usage: deploy.sh <image-tag>}"
APP_DIR=/opt/app
SSM_PATH=/justinnegron/prod/
export AWS_SHARED_CREDENTIALS_FILE="$APP_DIR/aws-credentials"
export AWS_REGION=us-east-1
cd "$APP_DIR"

echo "==> Rendering .env from SSM ($SSM_PATH)"
umask 077
aws ssm get-parameters-by-path --path "$SSM_PATH" --with-decryption --output json \
  | jq -r --arg p "$SSM_PATH" '.Parameters[] | "\(.Name | ltrimstr($p))=\(.Value)"' > .env.new
REPO="$(grep '^ECR_REPOSITORY_URL=' .env.new | cut -d= -f2-)"
echo "APP_IMAGE=${REPO}:${TAG}" >> .env.new
mv .env.new .env

echo "==> Pulling ${REPO}:${TAG}"
aws ecr get-login-password | docker login --username AWS --password-stdin "${REPO%%/*}" >/dev/null
docker compose pull --quiet web

echo "==> Migrating"
docker compose up -d --wait db
docker compose run --rm --no-deps web bin/rails db:migrate

echo "==> Starting"
docker compose up -d --remove-orphans --wait --wait-timeout 180

[ -f DEPLOYED_TAG ] && cp DEPLOYED_TAG PREVIOUS_TAG
echo "$TAG" > DEPLOYED_TAG
docker image prune -af --filter "until=168h" >/dev/null
echo "==> Deployed $TAG"
