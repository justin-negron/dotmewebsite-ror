# =============================================================================
# DNS & SSL — Route 53 + ACM
# =============================================================================
# Uses your EXISTING hosted zone (already in Route 53).
# Creates a wildcard ACM certificate validated via DNS.

# --- Existing Hosted Zone (data source — read-only, not managed by Terraform)
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# --- ACM Certificate (*.justinnegron.dev + justinnegron.dev)
# Must be in us-east-1 for CloudFront — our provider is already us-east-1.
resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  tags = {
    Name        = "${var.domain_name}-cert"
    Environment = var.environment
    Project     = "justinnegron-dev"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# --- DNS records for ACM validation
# ACM gives us CNAME records to prove we own the domain.
# Terraform creates them in Route 53 automatically.
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# --- Wait for certificate validation to complete
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# --- DNS: apex domain → CloudFront (site)
resource "aws_route53_record" "site_a" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "site_aaaa" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

# --- DNS: www → CloudFront (site) — redirects handled by CloudFront function
resource "aws_route53_record" "www_a" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_aaaa" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

# --- DNS: assets subdomain → CloudFront (assets)
resource "aws_route53_record" "assets_a" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "assets.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.assets.domain_name
    zone_id                = aws_cloudfront_distribution.assets.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "assets_aaaa" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "assets.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.assets.domain_name
    zone_id                = aws_cloudfront_distribution.assets.hosted_zone_id
    evaluate_target_health = false
  }
}
