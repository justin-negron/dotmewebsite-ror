#!/bin/bash
set -euo pipefail
exec > /var/log/user-data.log 2>&1

echo "==> Installing Docker..."
dnf update -y
dnf install -y docker jq
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Install docker-compose plugin
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

echo "==> Creating app directory..."
mkdir -p /opt/app
chown ec2-user:ec2-user /opt/app

echo "==> Authenticating to ECR..."
aws ecr get-login-password --region ${aws_region} | \
  docker login --username AWS --password-stdin ${account_id}.dkr.ecr.${aws_region}.amazonaws.com

echo "==> Fetching secrets..."
aws secretsmanager get-secret-value \
  --region ${aws_region} \
  --secret-id ${secret_arn} \
  --query 'SecretString' \
  --output text | jq -r 'to_entries[] | "\(.key)=\(.value)"' > /opt/app/.env
chmod 600 /opt/app/.env
chown ec2-user:ec2-user /opt/app/.env

echo "==> Writing docker-compose.prod.yml..."
cat > /opt/app/docker-compose.prod.yml << COMPOSE
services:
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3

  web:
    image: ${ecr_repo}:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    env_file: .env
    depends_on:
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 40s

  sidekiq:
    image: ${ecr_repo}:latest
    restart: unless-stopped
    command: bundle exec sidekiq
    env_file: .env
    depends_on:
      redis:
        condition: service_healthy

volumes:
  redis_data:
COMPOSE
chown ec2-user:ec2-user /opt/app/docker-compose.prod.yml

echo "==> Pulling images..."
docker compose -f /opt/app/docker-compose.prod.yml pull || echo "Image not pushed yet — will pull on first deploy"

echo "==> Starting services..."
docker compose -f /opt/app/docker-compose.prod.yml up -d || echo "Services will start on first deploy"

echo "==> Writing deploy helper script..."
cat > /opt/app/deploy.sh << DEPLOYSCRIPT
#!/bin/bash
set -euo pipefail

echo "==> Authenticating to ECR..."
aws ecr get-login-password --region ${aws_region} | \\
  docker login --username AWS --password-stdin ${account_id}.dkr.ecr.${aws_region}.amazonaws.com

echo "==> Refreshing secrets..."
aws secretsmanager get-secret-value \\
  --region ${aws_region} \\
  --secret-id ${secret_arn} \\
  --query 'SecretString' \\
  --output text | jq -r 'to_entries[] | "\\(.key)=\\(.value)"' > /opt/app/.env
chmod 600 /opt/app/.env

echo "==> Pulling latest image..."
docker compose -f /opt/app/docker-compose.prod.yml pull

echo "==> Restarting services..."
docker compose -f /opt/app/docker-compose.prod.yml up -d --remove-orphans

echo "==> Cleaning up old images..."
docker image prune -f

echo "==> Done!"
DEPLOYSCRIPT
chmod +x /opt/app/deploy.sh
chown ec2-user:ec2-user /opt/app/deploy.sh

echo "==> User data complete!"
