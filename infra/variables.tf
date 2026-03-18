variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Root domain name (e.g., justinnegron.dev)"
  type        = string
}

variable "site_bucket_name" {
  description = "S3 bucket name for the frontend SPA files"
  type        = string
}

variable "assets_bucket_name" {
  description = "S3 bucket name for blog image uploads"
  type        = string
}

variable "environment" {
  description = "Environment tag (production, staging)"
  type        = string
  default     = "production"
}
