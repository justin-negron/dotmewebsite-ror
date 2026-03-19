#!/bin/bash
set -euo pipefail

# Deploy frontend: build Vue app, sync to S3, invalidate CloudFront
# Usage: ./scripts/deploy-frontend.sh

# Load env vars from root .env if present
if [ -f "$(dirname "$0")/../.env" ]; then
  set -a; source "$(dirname "$0")/../.env"; set +a
fi

S3_BUCKET="${S3_BUCKET:?Set S3_BUCKET (e.g. my-site-bucket)}"
CF_DISTRIBUTION="${CF_DISTRIBUTION:?Set CF_DISTRIBUTION (e.g. E1A2B3C4D5)}"

echo "==> Building frontend..."
cd frontend
npm run build

echo "==> Syncing to S3..."
aws s3 sync dist/ "s3://${S3_BUCKET}" --delete

echo "==> Invalidating CloudFront cache..."
aws cloudfront create-invalidation \
  --distribution-id "${CF_DISTRIBUTION}" \
  --paths "/*" \
  --query 'Invalidation.Id' \
  --output text

echo "==> Done! Site will update within ~60 seconds."
