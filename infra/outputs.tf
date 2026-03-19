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

# --- Backend (EC2) ---

output "ec2_public_ip" {
  description = "Elastic IP of the EC2 app server"
  value       = aws_eip.app.public_ip
}

output "ec2_ssh_command" {
  description = "SSH command to connect to EC2"
  value       = "ssh ec2-user@${aws_eip.app.public_ip}"
}

# --- Database ---

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint (host:port)"
  value       = aws_db_instance.main.endpoint
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.main.db_name
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

# --- Secrets ---

output "secrets_arn" {
  description = "Secrets Manager ARN (for deploy scripts)"
  value       = aws_secretsmanager_secret.app.arn
}
