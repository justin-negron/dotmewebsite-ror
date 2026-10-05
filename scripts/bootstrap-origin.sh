#!/usr/bin/env bash
# One-time (idempotent) setup of the Lightsail origin, run from your machine:
#   scripts/bootstrap-origin.sh
# Installs Docker/AWS CLI/swap/auto-updates, copies deploy/ to /opt/app, writes the
# instance IAM credentials (from Terraform, never printed), and enables nightly backups.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
HOST="${ORIGIN_HOST:-origin.justinnegron.dev}"
REMOTE="ubuntu@${HOST}"
SSH_KEY="${ORIGIN_SSH_KEY:-$HOME/.ssh/justinnegron_deploy}"
SSH_OPTS=(-o StrictHostKeyChecking=accept-new)
[ -f "$SSH_KEY" ] && SSH_OPTS+=(-i "$SSH_KEY" -o IdentitiesOnly=yes)

echo "==> Host setup on $HOST"
ssh "${SSH_OPTS[@]}" "$REMOTE" 'sudo bash -s' < "$ROOT/deploy/host-setup.sh"

echo "==> Copying deploy files"
rsync -a -e "ssh ${SSH_OPTS[*]}" --exclude host-setup.sh "$ROOT/deploy/" "$REMOTE:/opt/app/"

echo "==> Installing authorized SSH keys from deploy/authorized_keys"
ssh "${SSH_OPTS[@]}" "$REMOTE" 'install -m 600 /opt/app/authorized_keys ~/.ssh/authorized_keys'

echo "==> Writing instance AWS credentials"
(
  cd "$ROOT/infra"
  printf '[default]\naws_access_key_id = %s\naws_secret_access_key = %s\n' \
    "$(terraform output -raw app_aws_access_key_id)" \
    "$(terraform output -raw app_aws_secret_access_key)"
) | ssh "${SSH_OPTS[@]}" "$REMOTE" 'umask 077 && cat > /opt/app/aws-credentials'

echo "==> Enabling nightly backup timer"
ssh "${SSH_OPTS[@]}" "$REMOTE" 'sudo install -m 644 /opt/app/systemd/justinnegron-backup.* /etc/systemd/system/ \
  && sudo systemctl daemon-reload && sudo systemctl enable --now justinnegron-backup.timer'

echo "==> Done. Next: scripts/deploy-backend.sh"
