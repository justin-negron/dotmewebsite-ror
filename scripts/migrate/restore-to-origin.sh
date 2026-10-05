#!/usr/bin/env bash
# Replaces the origin database with a pg_dump (-Fc) file, migrates, restarts,
# and prints row counts.
#   scripts/migrate/restore-to-origin.sh <file.dump>
set -euo pipefail

DUMP="${1:?usage: restore-to-origin.sh <file.dump>}"
ROOT="$(git rev-parse --show-toplevel)"
REMOTE="ubuntu@${ORIGIN_HOST:-origin.justinnegron.dev}"
SSH_KEY="${ORIGIN_SSH_KEY:-$HOME/.ssh/justinnegron_deploy}"
SSH_OPTS=(-o StrictHostKeyChecking=accept-new)
[ -f "$SSH_KEY" ] && SSH_OPTS+=(-i "$SSH_KEY" -o IdentitiesOnly=yes)

echo "==> Recreating database"
ssh "${SSH_OPTS[@]}" "$REMOTE" 'cd /opt/app && docker compose stop web && docker compose exec -T db sh -c \
  "dropdb -U portfolio --if-exists portfolio_production && createdb -U portfolio portfolio_production"'

echo "==> Restoring $(basename "$DUMP")"
ssh "${SSH_OPTS[@]}" "$REMOTE" 'cd /opt/app && docker compose exec -T db pg_restore -U portfolio -d portfolio_production --no-owner --no-acl --exit-on-error' < "$DUMP"

echo "==> Migrating and starting"
ssh "${SSH_OPTS[@]}" "$REMOTE" 'cd /opt/app && docker compose run --rm --no-deps web bin/rails db:migrate && docker compose up -d --wait --wait-timeout 180'

echo "==> Row counts"
ssh "${SSH_OPTS[@]}" "$REMOTE" 'cd /opt/app && docker compose exec -T db psql -U portfolio -d portfolio_production -At -f -' < "$ROOT/scripts/migrate/row-counts.sql"
