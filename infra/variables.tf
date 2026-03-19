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

# --- EC2 / SSH ---

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
}

variable "ssh_allowed_ip" {
  description = "IP address allowed to SSH into EC2 (your public IP)"
  type        = string
}

# --- Database ---

variable "db_username" {
  description = "RDS PostgreSQL master username"
  type        = string
  default     = "portfolio"
}

# --- Application AWS credentials (for S3 presigned uploads) ---

variable "app_aws_access_key_id" {
  description = "AWS access key for the Rails app (S3 uploads)"
  type        = string
  sensitive   = true
}

variable "app_aws_secret_access_key" {
  description = "AWS secret key for the Rails app (S3 uploads)"
  type        = string
  sensitive   = true
}

# --- SMTP (email) ---

variable "smtp_address" {
  description = "SMTP server address"
  type        = string
  default     = ""
}

variable "smtp_port" {
  description = "SMTP server port"
  type        = string
  default     = "587"
}

variable "smtp_username" {
  description = "SMTP username"
  type        = string
  default     = ""
  sensitive   = true
}

variable "smtp_password" {
  description = "SMTP password"
  type        = string
  default     = ""
  sensitive   = true
}
