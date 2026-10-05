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

# --- Lightsail origin ---

variable "ssh_allowed_ip" {
  description = "Your public IP; allowed to SSH to the Lightsail instance"
  type        = string
}

variable "lightsail_bundle_id" {
  description = "Lightsail plan. Changing it replaces the instance (and its local database)."
  type        = string
  default     = "micro_3_0"
}

variable "admin_ssh_public_key" {
  description = "SSH public key installed on the Lightsail instance"
  type        = string
}

variable "contact_notify_to" {
  description = "Address that receives contact form notifications (verified in SES)"
  type        = string
}
