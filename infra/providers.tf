terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Local state for now — migrate to S3 backend when adding CI/CD deploys
  # backend "s3" {
  #   bucket = "justinnegron-terraform-state"
  #   key    = "frontend/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# Primary provider — us-east-1 is required for CloudFront + ACM certificates
provider "aws" {
  region = var.aws_region
}
