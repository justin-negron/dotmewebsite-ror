# =============================================================================
# Secrets Manager — Application Secrets
# =============================================================================
# Single JSON secret containing all environment variables for the Rails app.
# EC2 user data script fetches this on boot and writes it to /opt/app/.env.

resource "random_password" "secret_key_base" {
  length  = 128
  special = false
}

resource "random_password" "jwt_secret" {
  length  = 64
  special = false
}

resource "random_password" "cloudfront_secret" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret" "app" {
  name        = "justinnegron/production/app"
  description = "Rails application environment variables"

  tags = {
    Environment = var.environment
    Project     = "justinnegron-dev"
  }
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id

  secret_string = jsonencode({
    DATABASE_URL       = "postgres://${var.db_username}:${random_password.db_password.result}@${aws_db_instance.main.endpoint}/portfolio_production"
    REDIS_URL          = "redis://redis:6379/0"
    SECRET_KEY_BASE    = random_password.secret_key_base.result
    JWT_SECRET         = random_password.jwt_secret.result
    RAILS_ENV          = "production"
    RAILS_LOG_TO_STDOUT = "1"
    AWS_ACCESS_KEY_ID     = var.app_aws_access_key_id
    AWS_SECRET_ACCESS_KEY = var.app_aws_secret_access_key
    AWS_REGION            = var.aws_region
    AWS_S3_BUCKET         = var.assets_bucket_name
    FRONTEND_URL          = "https://${var.domain_name}"
    CLOUDFRONT_SECRET     = random_password.cloudfront_secret.result
    SMTP_ADDRESS          = var.smtp_address
    SMTP_PORT             = var.smtp_port
    SMTP_USERNAME         = var.smtp_username
    SMTP_PASSWORD         = var.smtp_password
    SMTP_DOMAIN           = var.domain_name
    MAILER_FROM           = "noreply@${var.domain_name}"
  })
}
