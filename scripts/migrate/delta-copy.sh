#!/usr/bin/env bash
# Copies contacts and page_views created after a timestamp from one database to
# the other (rows get new ids; neither table has foreign keys).
#   scripts/migrate/delta-copy.sh to-origin 2026-10-05T12:00:00Z   # cutover stragglers
#   scripts/migrate/delta-copy.sh to-rds    2026-10-05T12:00:00Z   # rollback
# Remove after the legacy stack is torn down.
set -euo pipefail

DIRECTION="${1:?usage: delta-copy.sh to-origin|to-rds <since-ISO8601>}"
SINCE="${2:?usage: delta-copy.sh to-origin|to-rds <since-ISO8601>}"
[[ "$SINCE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]] || { echo "bad timestamp: $SINCE" >&2; exit 1; }

ROOT="$(git rev-parse --show-toplevel)"
SSH_KEY="${ORIGIN_SSH_KEY:-$HOME/.ssh/justinnegron_deploy}"
SSH_OPTS=(-o StrictHostKeyChecking=accept-new)
[ -f "$SSH_KEY" ] && SSH_OPTS+=(-i "$SSH_KEY" -o IdentitiesOnly=yes)
ORIGIN="ubuntu@${ORIGIN_HOST:-origin.justinnegron.dev}"
RDS_PSQL="docker run -i --rm --env-file /opt/app/.env postgres:17-alpine sh -c 'psql \"\$DATABASE_URL\" -v ON_ERROR_STOP=1 -At -f -'"
ORIGIN_PSQL="cd /opt/app && docker compose exec -T db psql -U portfolio -d portfolio_production -v ON_ERROR_STOP=1 -At -f -"

export_from() { # $1=source, stdin=SQL
  if [ "$1" = rds ]; then "$ROOT/scripts/migrate/ec2-run.sh" "$RDS_PSQL"; else ssh "${SSH_OPTS[@]}" "$ORIGIN" "$ORIGIN_PSQL"; fi
}
import_to() { # $1=target, stdin=SQL followed by CSV data
  if [ "$1" = rds ]; then "$ROOT/scripts/migrate/ec2-run.sh" "$RDS_PSQL"; else ssh "${SSH_OPTS[@]}" "$ORIGIN" "$ORIGIN_PSQL"; fi
}

case "$DIRECTION" in
  to-origin) SRC=rds; DST=origin ;;
  to-rds) SRC=origin; DST=rds ;;
  *) echo "direction must be to-origin or to-rds" >&2; exit 1 ;;
esac

for spec in "contacts:name,email,subject,message,status,created_at,updated_at" \
            "page_views:path,user_agent,ip_address,referrer,created_at,updated_at"; do
  table="${spec%%:*}"
  cols="${spec#*:}"
  csv="$(printf '\\copy (SELECT %s FROM %s WHERE created_at > %s ORDER BY id) TO STDOUT WITH CSV\n' \
    "$cols" "$table" "'$SINCE'" | export_from "$SRC")"
  count="$(printf '%s' "$csv" | grep -c '' || true)"
  if [ "$count" -eq 0 ]; then
    echo "$table: 0 rows to copy"
    continue
  fi
  { printf '\\copy %s(%s) FROM STDIN WITH CSV\n' "$table" "$cols"; printf '%s\n\\.\n' "$csv"; } | import_to "$DST" >/dev/null
  echo "$table: copied $count row(s) $SRC -> $DST"
done
