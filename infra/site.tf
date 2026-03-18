# =============================================================================
# Frontend SPA Hosting — S3 + CloudFront
# =============================================================================
# Private S3 bucket → CloudFront OAC → justinnegron.dev
# SPA routing: all 404/403 errors return /index.html (Vue Router handles paths)

# --- S3 Bucket (private — no public access)
resource "aws_s3_bucket" "site" {
  bucket = var.site_bucket_name

  tags = {
    Name        = "Frontend SPA"
    Environment = var.environment
    Project     = "justinnegron-dev"
  }
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- CloudFront Origin Access Control (modern replacement for OAI)
# This is how CloudFront authenticates to your private S3 bucket.
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.site_bucket_name}-oac"
  description                       = "OAC for frontend SPA bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --- S3 Bucket Policy (allows CloudFront OAC to read objects)
resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontOAC"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.site.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.site.arn
          }
        }
      }
    ]
  })
}

# --- CloudFront Cache Policy (optimized for SPA)
# HTML: no cache (always get latest deploy). JS/CSS: long cache (hashed filenames).
resource "aws_cloudfront_cache_policy" "site" {
  name        = "${var.site_bucket_name}-cache-policy"
  comment     = "SPA cache policy — cache by query strings and encoding"
  default_ttl = 86400    # 1 day
  max_ttl     = 31536000 # 1 year
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

# --- CloudFront Function: www → apex redirect
# Redirects www.justinnegron.dev → justinnegron.dev (SEO best practice)
resource "aws_cloudfront_function" "www_redirect" {
  name    = "www-redirect"
  runtime = "cloudfront-js-2.0"
  comment = "Redirect www to apex domain"
  publish = true

  code = <<-EOF
    function handler(event) {
      var request = event.request;
      var host = request.headers.host.value;
      if (host.startsWith('www.')) {
        var newUrl = 'https://${var.domain_name}' + request.uri;
        if (request.querystring && Object.keys(request.querystring).length > 0) {
          var qs = Object.entries(request.querystring)
            .map(function(e) { return e[0] + '=' + e[1].value; })
            .join('&');
          newUrl += '?' + qs;
        }
        return {
          statusCode: 301,
          statusDescription: 'Moved Permanently',
          headers: { location: { value: newUrl } }
        };
      }
      return request;
    }
  EOF
}

# --- CloudFront Distribution (main site)
resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "justinnegron.dev frontend SPA"
  default_root_object = "index.html"
  aliases             = [var.domain_name, "www.${var.domain_name}"]
  price_class         = "PriceClass_100" # US, Canada, Europe — cheapest tier
  http_version        = "http2and3"

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-site"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  # Default behavior — serves all SPA assets
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-site"
    cache_policy_id        = aws_cloudfront_cache_policy.site.id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.www_redirect.arn
    }
  }

  # SPA routing — return index.html for paths that don't match S3 objects.
  # Vue Router handles client-side routing from there.
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.main.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name        = "Frontend SPA CDN"
    Environment = var.environment
    Project     = "justinnegron-dev"
  }
}
