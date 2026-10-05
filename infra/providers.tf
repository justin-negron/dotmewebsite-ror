terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Bucket is created by ./bootstrap-state.sh (versioned, encrypted, TLS-only).
  backend "s3" {
    bucket       = "justinnegron-tfstate-712835875088"
    key          = "justinnegron-dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

# Primary provider — us-east-1 is required for CloudFront + ACM certificates
provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
