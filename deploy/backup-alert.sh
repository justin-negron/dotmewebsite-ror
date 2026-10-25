#!/usr/bin/env bash
# Mails CONTACT_NOTIFY_TO that the nightly backup failed. Runs as the OnFailure=
# unit of justinnegron-backup.service; test by hand with:
#   sudo systemctl start justinnegron-backup-alert.service
set -euo pipefail

APP_DIR=/opt/app
export AWS_SHARED_CREDENTIALS_FILE="$APP_DIR/aws-credentials"
export AWS_REGION=us-east-1
cd "$APP_DIR"

TO="$(grep '^CONTACT_NOTIFY_TO=' .env | cut -d= -f2-)"
# The IAM policy only allows ses:SendEmail from MAILER_FROM (app_iam.tf, ssm.tf)
FROM="$(grep '^MAILER_FROM=' .env | cut -d= -f2-)"
SUBJECT="justinnegron.dev backup failed"
BODY="The database backup on $(hostname) failed at $(date -u '+%Y-%m-%d %H:%M:%S UTC').
Logs: journalctl -u justinnegron-backup.service"

aws sesv2 send-email \
  --from-email-address "$FROM" \
  --destination "$(jq -n --arg to "$TO" '{ToAddresses: [$to]}')" \
  --content "$(jq -n --arg s "$SUBJECT" --arg b "$BODY" '{Simple: {Subject: {Data: $s}, Body: {Text: {Data: $b}}}}')" \
  --query MessageId --output text
