#!/usr/bin/env bash
# Replaces the production database with a pg_dump (-Fc) backup, migrates,
# restarts, and prints row counts. Accepts a local file or an S3 URI:
#   scripts/restore-db.sh ~/backups/portfolio.dump
#   scripts/restore-db.sh s3://justinnegron-backups-<account>/db/daily/portfolio-<stamp>.dump
# Before it drops anything, it checks the dump with pg_restore -l in the origin's db
# container and takes a manual backup there, and it stops if either fails. The check
# runs remotely because Postgres 17 dumps need a pg_restore 17, which a laptop may lack.
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

echo "==> Checking $(basename "$SOURCE")"
if ! ssh "${SSH_OPTS[@]}" "$REMOTE" 'cd /opt/app && docker compose exec -T db pg_restore -l > /dev/null' < "$DUMP"; then
  echo "The dump check failed (error above). Either $SOURCE is not a readable pg_dump -Fc archive or the origin is unreachable. Production was not touched." >&2
  exit 1
fi

echo "==> Taking a safety backup on the origin"
if ! ssh "${SSH_OPTS[@]}" "$REMOTE" '/opt/app/backup-db.sh manual'; then
  echo "The safety backup failed, so the restore stopped. Production was not touched." >&2
  exit 1
fi

echo "==> Recreating database"
ssh "${SSH_OPTS[@]}" "$REMOTE" 'cd /opt/app && docker compose stop web && docker compose exec -T db sh -c \
  "dropdb -U portfolio --if-exists portfolio_production && createdb -U portfolio portfolio_production"'

echo "==> Restoring $(basename "$SOURCE")"
ssh "${SSH_OPTS[@]}" "$REMOTE" 'cd /opt/app && docker compose exec -T db pg_restore -U portfolio -d portfolio_production --no-owner --no-acl --exit-on-error' < "$DUMP"

echo "==> Migrating and starting"
ssh "${SSH_OPTS[@]}" "$REMOTE" 'cd /opt/app && docker compose run --rm --no-deps web bin/rails db:migrate && docker compose up -d --wait --wait-timeout 180'

echo "==> Row counts"
ssh "${SSH_OPTS[@]}" "$REMOTE" 'cd /opt/app && docker compose exec -T db psql -U portfolio -d portfolio_production -At -f -' < "$ROOT/scripts/row-counts.sql"
