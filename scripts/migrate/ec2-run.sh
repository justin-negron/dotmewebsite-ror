#!/usr/bin/env bash
# Runs a command on the legacy EC2 host via EC2 Instance Connect (temporary key, valid 60 s).
# stdin/stdout pass through, so it can stream dumps:
#   scripts/migrate/ec2-run.sh "docker run --rm --env-file /opt/app/.env postgres:17-alpine sh -c 'pg_dump -Fc \"\$DATABASE_URL\"'" > db.dump
# Remove after the legacy stack is torn down.
set -euo pipefail

INSTANCE_ID="${EC2_INSTANCE_ID:-i-0f6f2236988758f20}"
OS_USER="ec2-user"
CMD="${1:?usage: ec2-run.sh '<remote command>'}"

KEYDIR="$(mktemp -d)"
trap 'rm -rf "$KEYDIR"' EXIT
ssh-keygen -t ed25519 -f "$KEYDIR/key" -N "" -q -C "eic-temp"

read -r AZ HOST < <(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].[Placement.AvailabilityZone,PublicIpAddress]' --output text)

aws ec2-instance-connect send-ssh-public-key --instance-id "$INSTANCE_ID" \
  --instance-os-user "$OS_USER" --availability-zone "$AZ" \
  --ssh-public-key "file://$KEYDIR/key.pub" >/dev/null

ssh -i "$KEYDIR/key" -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=10 \
  -o StrictHostKeyChecking=accept-new "$OS_USER@$HOST" "$CMD"
