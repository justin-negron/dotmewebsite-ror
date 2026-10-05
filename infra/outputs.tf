# =============================================================================
# Outputs — useful values after terraform apply
# =============================================================================

# --- Frontend ---

output "site_bucket_name" {
  description = "S3 bucket for frontend SPA files"
  value       = aws_s3_bucket.site.id
}

output "site_bucket_arn" {
  description = "ARN of the site bucket (needed for CI/CD deploy permissions)"
  value       = aws_s3_bucket.site.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for the site (needed for cache invalidation on deploy)"
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_distribution_domain" {
  description = "CloudFront domain for the site"
  value       = aws_cloudfront_distribution.site.domain_name
}

output "site_url" {
  description = "Your live site URL"
  value       = "https://${var.domain_name}"
}

# --- Assets ---

output "assets_bucket_name" {
  description = "S3 bucket for blog image uploads"
  value       = aws_s3_bucket.assets.id
}

output "assets_bucket_arn" {
  description = "ARN of the assets bucket"
  value       = aws_s3_bucket.assets.arn
}

output "assets_distribution_id" {
  description = "CloudFront distribution ID for assets"
  value       = aws_cloudfront_distribution.assets.id
}

output "assets_url" {
  description = "Blog image assets URL"
  value       = "https://assets.${var.domain_name}"
}

# --- ECR ---

output "ecr_repository_url" {
  description = "ECR repository URL for Docker images"
  value       = aws_ecr_repository.api.repository_url
}

# --- DNS ---

output "certificate_arn" {
  description = "ACM certificate ARN (wildcard + apex)"
  value       = aws_acm_certificate.main.arn
}

output "nameservers" {
  description = "Route 53 nameservers — must match your domain registrar"
  value       = data.aws_route53_zone.main.name_servers
}

# --- Lightsail origin ---

output "origin_host" {
  description = "Origin hostname (SSH: ubuntu@<this>)"
  value       = aws_route53_record.origin.fqdn
}

output "origin_ip" {
  description = "Lightsail static IP"
  value       = aws_lightsail_static_ip.app.ip_address
}

output "backups_bucket" {
  description = "S3 bucket for database backups"
  value       = aws_s3_bucket.backups.bucket
}

output "app_aws_access_key_id" {
  description = "Access key ID for the instance's IAM user"
  value       = aws_iam_access_key.app.id
}

output "app_aws_secret_access_key" {
  description = "Secret for the instance's IAM user (read with: terraform output -raw)"
  value       = aws_iam_access_key.app.secret
  sensitive   = true
}
