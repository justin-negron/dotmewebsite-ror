# =============================================================================
# Outputs — useful values after terraform apply
# =============================================================================

output "site_bucket_name" {
  description = "S3 bucket for frontend SPA files"
  value       = aws_s3_bucket.site.id
}

output "site_bucket_arn" {
  description = "ARN of the site bucket (needed for CI/CD deploy permissions)"
  value       = aws_s3_bucket.site.arn
}

output "assets_bucket_name" {
  description = "S3 bucket for blog image uploads"
  value       = aws_s3_bucket.assets.id
}

output "assets_bucket_arn" {
  description = "ARN of the assets bucket"
  value       = aws_s3_bucket.assets.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for the site (needed for cache invalidation on deploy)"
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_distribution_domain" {
  description = "CloudFront domain for the site"
  value       = aws_cloudfront_distribution.site.domain_name
}

output "assets_distribution_id" {
  description = "CloudFront distribution ID for assets"
  value       = aws_cloudfront_distribution.assets.id
}

output "assets_distribution_domain" {
  description = "CloudFront domain for assets"
  value       = aws_cloudfront_distribution.assets.domain_name
}

output "certificate_arn" {
  description = "ACM certificate ARN (wildcard + apex)"
  value       = aws_acm_certificate.main.arn
}

output "site_url" {
  description = "Your live site URL"
  value       = "https://${var.domain_name}"
}

output "assets_url" {
  description = "Blog image assets URL"
  value       = "https://assets.${var.domain_name}"
}

output "nameservers" {
  description = "Route 53 nameservers — must match your domain registrar"
  value       = data.aws_route53_zone.main.name_servers
}
