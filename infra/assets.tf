# =============================================================================
# Blog Image Assets — S3 + CloudFront
# =============================================================================
# Private S3 bucket → CloudFront OAC → assets.justinnegron.dev
# Presigned URL uploads go directly to S3 (PUT), reads go through CloudFront (GET).
# CORS configured to allow PUT from the frontend origin.

# --- S3 Bucket (private)
resource "aws_s3_bucket" "assets" {
  bucket = var.assets_bucket_name

  tags = {
    Name        = "Blog Image Assets"
    Environment = var.environment
    Project     = "justinnegron-dev"
  }
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- CORS (allows presigned URL PUT uploads from frontend)
# Presigned URLs are PUT requests directly to S3, not through CloudFront.
# Without CORS, the browser blocks the upload from your frontend origin.
resource "aws_s3_bucket_cors_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT"]
    allowed_origins = [
      "https://${var.domain_name}",
      "http://localhost:5173", # Vite dev server
    ]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

# --- CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "assets" {
  name                              = "${var.assets_bucket_name}-oac"
  description                       = "OAC for blog image assets bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --- S3 Bucket Policy (CloudFront OAC read access)
resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontOAC"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.assets.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.assets.arn
          }
        }
      }
    ]
  })
}

# --- CloudFront Cache Policy (immutable assets — long cache)
# Blog images never change once uploaded (UUID filenames), so cache aggressively.
resource "aws_cloudfront_cache_policy" "assets" {
  name        = "${var.assets_bucket_name}-cache-policy"
  comment     = "Aggressive cache for immutable blog images"
  default_ttl = 2592000  # 30 days
  max_ttl     = 31536000 # 1 year
  min_ttl     = 86400    # 1 day minimum

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

# --- CloudFront Distribution (assets)
resource "aws_cloudfront_distribution" "assets" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "assets.justinnegron.dev — blog images"
  aliases         = ["assets.${var.domain_name}"]
  price_class     = "PriceClass_100"
  http_version    = "http2and3"

  origin {
    domain_name              = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_id                = "s3-assets"
    origin_access_control_id = aws_cloudfront_origin_access_control.assets.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-assets"
    cache_policy_id        = aws_cloudfront_cache_policy.assets.id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
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
    Name        = "Blog Image Assets CDN"
    Environment = var.environment
    Project     = "justinnegron-dev"
  }
}
