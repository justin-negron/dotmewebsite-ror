# =============================================================================
# App configuration — SSM Parameter Store (/justinnegron/prod/*)
# =============================================================================
# deploy/deploy.sh renders these into /opt/app/.env on every deploy.
# Standard SecureString parameters are free (unlike Secrets Manager).

resource "random_password" "lightsail_db" {
  length  = 32
  special = false
}

resource "random_password" "lightsail_secret_key_base" {
  length  = 128
  special = false
}

resource "random_password" "lightsail_jwt_secret" {
  length  = 64
  special = false
}

locals {
  mailer_from = "notifications@${var.domain_name}"

  app_config = {
    RAILS_ENV           = "production"
    RAILS_LOG_TO_STDOUT = "true"
    DB_PASSWORD         = random_password.lightsail_db.result
    SECRET_KEY_BASE     = random_password.lightsail_secret_key_base.result
    JWT_SECRET          = random_password.lightsail_jwt_secret.result
    # Shared with the legacy EC2 origin until teardown so CloudFront can switch either way
    CLOUDFRONT_SECRET     = random_password.cloudfront_secret.result
    FRONTEND_URL          = "https://${var.domain_name}"
    AWS_REGION            = var.aws_region
    AWS_ACCESS_KEY_ID     = aws_iam_access_key.app.id
    AWS_SECRET_ACCESS_KEY = aws_iam_access_key.app.secret
    AWS_S3_BUCKET         = aws_s3_bucket.assets.bucket
    ASSETS_HOST           = "assets.${var.domain_name}"
    MAILER_FROM           = local.mailer_from
    CONTACT_NOTIFY_TO     = var.contact_notify_to
    BACKUP_BUCKET         = aws_s3_bucket.backups.bucket
    ECR_REPOSITORY_URL    = aws_ecr_repository.api.repository_url
  }

  # for_each keys must not be sensitive, so list them explicitly
  app_config_keys = [
    "RAILS_ENV", "RAILS_LOG_TO_STDOUT", "DB_PASSWORD", "SECRET_KEY_BASE", "JWT_SECRET",
    "CLOUDFRONT_SECRET", "FRONTEND_URL", "AWS_REGION", "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY", "AWS_S3_BUCKET", "ASSETS_HOST", "MAILER_FROM",
    "CONTACT_NOTIFY_TO", "BACKUP_BUCKET", "ECR_REPOSITORY_URL",
  ]
}

resource "aws_ssm_parameter" "app" {
  for_each = toset(local.app_config_keys)

  name  = "${local.ssm_prefix}/${each.key}"
  type  = "SecureString"
  value = local.app_config[each.key]

  tags = {
    Environment = var.environment
    Project     = "justinnegron-dev"
  }
}
