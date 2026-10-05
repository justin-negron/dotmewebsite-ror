#!/usr/bin/env bash
# Host setup for the Lightsail origin (Ubuntu 24.04). Idempotent; runs as root.
# Invoked by scripts/bootstrap-origin.sh.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "==> Docker (official repository)"
if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list
fi
apt-get update -q
apt-get install -y -q docker-ce docker-ce-cli containerd.io docker-compose-plugin jq rsync unattended-upgrades
usermod -aG docker ubuntu

DAEMON_JSON='{ "log-driver": "json-file", "log-opts": { "max-size": "10m", "max-file": "3" } }'
if [ "$(cat /etc/docker/daemon.json 2>/dev/null)" != "$DAEMON_JSON" ]; then
  echo "$DAEMON_JSON" > /etc/docker/daemon.json
  systemctl restart docker
fi
systemctl enable --now docker

echo "==> AWS CLI"
snap list aws-cli >/dev/null 2>&1 || snap install aws-cli --classic

echo "==> 2 GB swap"
if ! swapon --show | grep -q /swapfile; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
fi
grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
sysctl -q -p /etc/sysctl.d/99-swappiness.conf

echo "==> Automatic security updates (Ubuntu + Docker), reboot at 09:30 UTC if required"
cat > /etc/apt/apt.conf.d/52justinnegron-upgrades <<'EOF'
Unattended-Upgrade::Origins-Pattern:: "origin=Docker";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "09:30";
EOF
systemctl enable --now unattended-upgrades

echo "==> App directory"
install -d -o ubuntu -g ubuntu -m 750 /opt/app
