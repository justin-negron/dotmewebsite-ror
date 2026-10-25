# =============================================================================
# Frontend SPA Hosting — S3 + CloudFront
# =============================================================================
# Private S3 bucket → CloudFront OAC → justinnegron.dev
# SPA routing: the viewer-request function serves /index.html for any path whose
# last segment has no dot. It runs only on the S3 behavior, so /api/* errors reach
# the browser unchanged, and a missing file returns S3's 403.

# --- Shared secret CloudFront sends to the API origin (checked by CloudfrontSecretMiddleware)
resource "random_password" "cloudfront_secret" {
  length  = 48
  special = false
}

# --- AWS Managed Cache Policy: CachingDisabled (for API proxy)
data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

# --- S3 Bucket (private — no public access)
resource "aws_s3_bucket" "site" {
  bucket = var.site_bucket_name

  tags = {
    Name = "Frontend SPA"
  }
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    id     = "expire-noncurrent-30-days"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
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
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.site.arn, "${aws_s3_bucket.site.arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      }
    ]
  })
}

# --- CloudFront Cache Policy (optimized for SPA)
# TTLs follow the Cache-Control headers scripts/deploy-frontend.sh sets on each object.
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

# --- Response headers for the site and the API proxy
# connect-src lists both S3 hostnames because admin image uploads PUT straight to a
# presigned S3 URL, and the SDK picks the global or regional form by its config.
resource "aws_cloudfront_response_headers_policy" "site" {
  name    = "justinnegron-site-security-headers"
  comment = "HSTS, nosniff, frame and referrer policy, report-only CSP"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }

  custom_headers_config {
    items {
      header   = "Permissions-Policy"
      value    = "camera=(), microphone=(), geolocation=()"
      override = true
    }

    items {
      header = "Content-Security-Policy-Report-Only"
      value = join("; ", [
        "default-src 'self'",
        # Hash of the inline theme script in frontend/index.html; update it when that script changes.
        "script-src 'self' 'sha256-v3SasoOBk/RnLiB827NX4pDRt7O84UqywJPqqe1S29o='",
        "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
        "font-src 'self' https://fonts.gstatic.com",
        "img-src 'self' data: blob: https://assets.${var.domain_name}",
        "connect-src 'self' https://${aws_s3_bucket.assets.bucket_domain_name} https://${aws_s3_bucket.assets.bucket_regional_domain_name}",
        # frame-ancestors is ignored in report-only mode; add it back when the
        # header becomes Content-Security-Policy. X-Frame-Options DENY covers framing now.
        "base-uri 'self'",
        "form-action 'self'",
        "object-src 'none'",
      ])
      override = true
    }
  }
}

# --- CloudFront Function: www → apex redirect, then SPA routing
# Name and resource address stay "www_redirect" so the function ARN does not change.
resource "aws_cloudfront_function" "www_redirect" {
  name    = "www-redirect"
  runtime = "cloudfront-js-2.0"
  comment = "Redirect www to apex; serve index.html for extensionless paths"
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
      var lastSegment = request.uri.split('/').pop();
      if (lastSegment.indexOf('.') === -1) {
        request.uri = '/index.html';
      }
      return request;
    }
  EOF
}

# --- CloudFront Origin Request Policy for API
# Forwards whitelisted headers, all cookies, and query strings to the API origin.
# Required for auth tokens, session cookies, and API query parameters.
resource "aws_cloudfront_origin_request_policy" "api" {
  name    = "api-origin-request-policy"
  comment = "Forward all cookies, query strings, and headers to API origin"

  cookies_config {
    cookie_behavior = "all"
  }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = [
        "Authorization",
        "Content-Type",
        "Accept",
        "Origin",
        "X-Requested-With",
        "Access-Control-Request-Method",
        "Access-Control-Request-Headers",
        "User-Agent",
      ]
    }
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}

# --- CloudFront Distribution (main site + API proxy)

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "justinnegron.dev frontend SPA + API proxy"
  default_root_object = "index.html"
  aliases             = [var.domain_name, "www.${var.domain_name}"]
  price_class         = "PriceClass_100" # US, Canada, Europe — cheapest tier
  http_version        = "http2and3"

  # Origin 1: S3 for SPA static files
  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-site"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  # Origin 2: Lightsail instance (Caddy → Rails) for API requests
  origin {
    domain_name = aws_route53_record.origin.fqdn
    origin_id   = "lightsail-api"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only" # Caddy terminates TLS on the instance
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-CloudFront-Secret"
      value = random_password.cloudfront_secret.result
    }
  }

  # Default behavior — serves SPA assets from S3
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-site"
    cache_policy_id        = aws_cloudfront_cache_policy.site.id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    response_headers_policy_id = aws_cloudfront_response_headers_policy.site.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.www_redirect.arn
    }
  }

  # API behavior — forwards /api/* to the Lightsail origin, no caching
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "lightsail-api"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # No caching for API responses
    cache_policy_id            = data.aws_cloudfront_cache_policy.disabled.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.api.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.site.id
  }

  # Health check behavior — forwards /health to the Lightsail origin
  ordered_cache_behavior {
    path_pattern           = "/health"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "lightsail-api"
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id            = data.aws_cloudfront_cache_policy.disabled.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.api.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.site.id
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
    Name = "Frontend SPA CDN"
  }
}
