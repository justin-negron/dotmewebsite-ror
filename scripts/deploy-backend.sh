#!/bin/bash
set -euo pipefail

# Deploy backend: build Docker image, push to ECR, redeploy on EC2
# Usage: ./scripts/deploy-backend.sh

# Load env vars from root .env if present
if [ -f "$(dirname "$0")/../.env" ]; then
  set -a; source "$(dirname "$0")/../.env"; set +a
fi

ECR_REPO="${ECR_REPO:?Set ECR_REPO (e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com/my-api)}"
EC2_HOST="${EC2_HOST:?Set EC2_HOST (e.g. ec2-user@1.2.3.4)}"
AWS_REGION="${AWS_REGION:-us-east-1}"

echo "==> Building Docker image..."
docker build -t "${ECR_REPO}:latest" ./backend

echo "==> Authenticating to ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | \
  docker login --username AWS --password-stdin "${ECR_REPO%%/*}"

echo "==> Pushing image to ECR..."
docker push "${ECR_REPO}:latest"

echo "==> Deploying on EC2..."
echo "Run this command to complete the deploy:"
echo "  ssh ${EC2_HOST} \"sudo /opt/app/deploy.sh\""
echo ""
echo "Then verify:"
echo "  ssh ${EC2_HOST} \"curl -s http://localhost:3000/health\""
