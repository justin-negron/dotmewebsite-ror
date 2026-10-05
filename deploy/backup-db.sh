#!/usr/bin/env bash
# Logical backup of the production database to S3. Runs nightly via
# justinnegron-backup.timer; run by hand with `manual` before risky changes:
#   /opt/app/backup-db.sh manual
set -euo pipefail

APP_DIR=/opt/app
export AWS_SHARED_CREDENTIALS_FILE="$APP_DIR/aws-credentials"
export AWS_REGION=us-east-1
cd "$APP_DIR"

BUCKET="$(grep '^BACKUP_BUCKET=' .env | cut -d= -f2-)"
if [ "${1:-}" = manual ]; then
  PREFIX=manual
elif [ "$(date -u +%d)" = 01 ]; then
  PREFIX=monthly
else
  PREFIX=daily
fi
KEY="db/${PREFIX}/portfolio-$(date -u +%Y%m%dT%H%M%SZ).dump"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

docker compose exec -T db pg_dump -U portfolio -d portfolio_production -Fc > "$TMP"
# Fails if the archive is truncated or unreadable
docker compose exec -T db pg_restore -l < "$TMP" > /dev/null

aws s3 cp "$TMP" "s3://${BUCKET}/${KEY}" --only-show-errors
echo "backup uploaded: s3://${BUCKET}/${KEY} ($(stat -c %s "$TMP") bytes)"
