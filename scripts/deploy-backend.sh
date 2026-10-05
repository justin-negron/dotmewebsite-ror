#!/usr/bin/env bash
# Builds the API image, pushes it to ECR, syncs deploy/ to the origin, and deploys.
#   scripts/deploy-backend.sh                # build and deploy HEAD
#   TAG=<git-sha> scripts/deploy-backend.sh  # redeploy an existing image (rollback)
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
HOST="${ORIGIN_HOST:-origin.justinnegron.dev}"
SSH_KEY="${ORIGIN_SSH_KEY:-$HOME/.ssh/justinnegron_deploy}"
SSH_OPTS=(-o StrictHostKeyChecking=accept-new)
[ -f "$SSH_KEY" ] && SSH_OPTS+=(-i "$SSH_KEY" -o IdentitiesOnly=yes)
REGION="${AWS_REGION:-us-east-1}"
REPO="${ECR_REPO:-$(aws ecr describe-repositories --region "$REGION" --repository-names justinnegron-api \
  --query 'repositories[0].repositoryUri' --output text)}"

if [ -z "${TAG:-}" ]; then
  if [ -n "$(git -C "$ROOT" status --porcelain -- backend deploy)" ] && [ "${ALLOW_DIRTY:-}" != 1 ]; then
    echo "backend/ or deploy/ has uncommitted changes; commit them or set ALLOW_DIRTY=1" >&2
    exit 1
  fi
  TAG="$(git -C "$ROOT" rev-parse --short=12 HEAD)"

  echo "==> Building $REPO:$TAG"
  docker build --platform linux/amd64 -t "$REPO:$TAG" "$ROOT/backend"
  aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "${REPO%%/*}"
  docker push --quiet "$REPO:$TAG"
fi

echo "==> Syncing deploy files to $HOST"
rsync -a -e "ssh ${SSH_OPTS[*]}" --exclude host-setup.sh "$ROOT/deploy/" "ubuntu@$HOST:/opt/app/"

echo "==> Deploying $TAG"
ssh "${SSH_OPTS[@]}" "ubuntu@$HOST" "/opt/app/deploy.sh $TAG"
