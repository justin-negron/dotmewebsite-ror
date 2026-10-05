# =============================================================================
# IAM user for the Lightsail instance (Lightsail can't use instance roles)
# =============================================================================
# Least privilege: upload blog images, write/read DB backups, pull the API image,
# read its own SSM parameters, and send mail from the site domain.

resource "aws_iam_user" "app" {
  name = "justinnegron-app"

  tags = {
    Environment = var.environment
    Project     = "justinnegron-dev"
  }
}

resource "aws_iam_access_key" "app" {
  user = aws_iam_user.app.name
}

locals {
  ssm_prefix = "/justinnegron/prod"
}

resource "aws_iam_user_policy" "app" {
  name = "justinnegron-app"
  user = aws_iam_user.app.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "UploadBlogImages"
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.assets.arn}/blog-images/*"
      },
      {
        Sid      = "DatabaseBackups"
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "${aws_s3_bucket.backups.arn}/db/*"
      },
      {
        Sid      = "ListBackups"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.backups.arn
      },
      {
        Sid      = "EcrLogin"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "EcrPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = aws_ecr_repository.api.arn
      },
      {
        Sid    = "ReadAppConfig"
        Effect = "Allow"
        Action = "ssm:GetParametersByPath"
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_prefix}",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_prefix}/*"
        ]
      },
      {
        Sid       = "DecryptAppConfig"
        Effect    = "Allow"
        Action    = "kms:Decrypt"
        Resource  = "*"
        Condition = { StringEquals = { "kms:ViaService" = "ssm.${var.aws_region}.amazonaws.com" } }
      },
      {
        Sid       = "SendMail"
        Effect    = "Allow"
        Action    = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource  = "*"
        Condition = { StringEquals = { "ses:FromAddress" = local.mailer_from } }
      }
    ]
  })
}
