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
  description = "Your public IPv4 address, without a prefix; lightsail.tf opens SSH to it as a /32"
  type        = string

  validation {
    condition     = can(cidrnetmask("${var.ssh_allowed_ip}/32"))
    error_message = "ssh_allowed_ip must be one IPv4 address such as 203.0.113.7, with no /32 suffix."
  }
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

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.contact_notify_to))
    error_message = "contact_notify_to must be an email address such as name@example.com."
  }
}
