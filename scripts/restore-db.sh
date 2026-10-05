#!/usr/bin/env bash
# Replaces the production database with a pg_dump (-Fc) backup, migrates,
# restarts, and prints row counts. Accepts a local file or an S3 URI:
#   scripts/restore-db.sh ~/backups/portfolio.dump
#   scripts/restore-db.sh s3://justinnegron-backups-<account>/db/daily/portfolio-<stamp>.dump
# Take a fresh backup first (ssh ubuntu@origin.justinnegron.dev /opt/app/backup-db.sh manual).
set -euo pipefail

SOURCE="${1:?usage: restore-db.sh <file.dump | s3://bucket/key>}"
ROOT="$(git rev-parse --show-toplevel)"
DUMP="$SOURCE"
if [[ "$SOURCE" == s3://* ]]; then
  DUMP="$(mktemp)"
  trap 'rm -f "$DUMP"' EXIT
  aws s3 cp "$SOURCE" "$DUMP" --only-show-errors
fi
REMOTE="ubuntu@${ORIGIN_HOST:-origin.justinnegron.dev}"
SSH_KEY="${ORIGIN_SSH_KEY:-$HOME/.ssh/justinnegron_deploy}"
SSH_OPTS=(-o StrictHostKeyChecking=accept-new)
[ -f "$SSH_KEY" ] && SSH_OPTS+=(-i "$SSH_KEY" -o IdentitiesOnly=yes)

echo "==> Recreating database"
ssh "${SSH_OPTS[@]}" "$REMOTE" 'cd /opt/app && docker compose stop web && docker compose exec -T db sh -c \
  "dropdb -U portfolio --if-exists portfolio_production && createdb -U portfolio portfolio_production"'

echo "==> Restoring $(basename "$SOURCE")"
ssh "${SSH_OPTS[@]}" "$REMOTE" 'cd /opt/app && docker compose exec -T db pg_restore -U portfolio -d portfolio_production --no-owner --no-acl --exit-on-error' < "$DUMP"

echo "==> Migrating and starting"
ssh "${SSH_OPTS[@]}" "$REMOTE" 'cd /opt/app && docker compose run --rm --no-deps web bin/rails db:migrate && docker compose up -d --wait --wait-timeout 180'

echo "==> Row counts"
ssh "${SSH_OPTS[@]}" "$REMOTE" 'cd /opt/app && docker compose exec -T db psql -U portfolio -d portfolio_production -At -f -' < "$ROOT/scripts/row-counts.sql"
