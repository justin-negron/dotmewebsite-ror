# =============================================================================
# EC2 — Application Server
# =============================================================================
# Single t4g.small running docker-compose: Rails (Puma) + Sidekiq + Redis.
# Elastic IP ensures CloudFront origin doesn't change on instance restart.
# User data script bootstraps Docker, pulls from ECR, starts services.

# --- SSH Key Pair
resource "aws_key_pair" "deploy" {
  key_name   = "justinnegron-deploy"
  public_key = var.ssh_public_key

  tags = {
    Environment = var.environment
    Project     = "justinnegron-dev"
  }
}

# --- IAM Role (allows EC2 to pull from ECR and read secrets)
resource "aws_iam_role" "ec2" {
  name = "justinnegron-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = "justinnegron-dev"
  }
}

resource "aws_iam_role_policy" "ec2_ecr" {
  name = "ecr-pull"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_secrets" {
  name = "secrets-read"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = aws_secretsmanager_secret.app.arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "justinnegron-ec2-profile"
  role = aws_iam_role.ec2.name
}

# --- Look up latest Amazon Linux 2023 ARM64 AMI
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# --- EC2 Instance
resource "aws_instance" "app" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.small"
  key_name               = aws_key_pair.deploy.key_name
  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id              = aws_subnet.public_a.id
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  # IMDSv2 required — prevents SSRF-based token theft
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/templates/user-data.sh", {
    aws_region    = var.aws_region
    ecr_repo      = aws_ecr_repository.api.repository_url
    secret_arn    = aws_secretsmanager_secret.app.arn
    account_id    = data.aws_caller_identity.current.account_id
  }))

  tags = {
    Name        = "justinnegron-app"
    Environment = var.environment
    Project     = "justinnegron-dev"
  }

  lifecycle {
    ignore_changes = [ami] # Don't recreate on AMI updates
  }
}

# --- Current AWS account ID (for ECR login URL)
data "aws_caller_identity" "current" {}

# --- Elastic IP (static IP for CloudFront origin)
resource "aws_eip" "app" {
  instance = aws_instance.app.id
  domain   = "vpc"

  tags = {
    Name        = "justinnegron-app-eip"
    Environment = var.environment
  }
}
