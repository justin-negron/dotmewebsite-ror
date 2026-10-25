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
# Hashed assets go first and are never deleted, so a new index.html never points at a
# missing chunk and a tab still on the old index.html can lazy-load its old chunks.
aws s3 sync dist/assets/ "s3://${S3_BUCKET}/assets/" --cache-control "public, max-age=31536000, immutable"
aws s3 sync dist/ "s3://${S3_BUCKET}/" --exclude "assets/*" --delete --cache-control "public, max-age=0, s-maxage=86400, must-revalidate"

echo "==> Invalidating CloudFront cache..."
aws cloudfront create-invalidation \
  --distribution-id "${CF_DISTRIBUTION}" \
  --paths "/*" \
  --query 'Invalidation.Id' \
  --output text

echo "==> Done! Site will update within ~60 seconds."
