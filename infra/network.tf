# =============================================================================
# Networking — VPC, Subnets, Security Groups
# =============================================================================
# EC2 in public subnets (receives CloudFront traffic).
# RDS in private subnets (only reachable from EC2 security group).
# No NAT gateway — saves ~$32/month. RDS doesn't need internet access.

# --- CloudFront managed prefix list (auto-updated by AWS)
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# --- VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "justinnegron-vpc"
    Environment = var.environment
    Project     = "justinnegron-dev"
  }
}

# --- Internet Gateway (for public subnets)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "justinnegron-igw"
    Environment = var.environment
  }
}

# --- Public Subnets (EC2 lives here)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "justinnegron-public-a"
    Environment = var.environment
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "justinnegron-public-b"
    Environment = var.environment
  }
}

# --- Private Subnets (RDS lives here — requires 2 AZs for DB subnet group)
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name        = "justinnegron-private-a"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name        = "justinnegron-private-b"
    Environment = var.environment
  }
}

# --- Route Table (public subnets → internet gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "justinnegron-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# --- Security Group: EC2
resource "aws_security_group" "ec2" {
  name        = "justinnegron-ec2-sg"
  description = "Allow HTTP from anywhere (CloudFront) and SSH from admin IP"
  vpc_id      = aws_vpc.main.id

  # Puma on port 3000 — CloudFront forwards here.
  # Restricted to CloudFront IP ranges via AWS-managed prefix list.
  # Additional layer: X-CloudFront-Secret header verified by Rails middleware.
  ingress {
    description     = "HTTP from CloudFront"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  # SSH restricted to admin IP only
  ingress {
    description = "SSH from admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.ssh_allowed_ip}/32"]
  }

  # All outbound (ECR pulls, RDS connections, internet)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "justinnegron-ec2-sg"
    Environment = var.environment
  }
}

# --- Security Group: RDS
resource "aws_security_group" "rds" {
  name        = "justinnegron-rds-sg"
  description = "Allow PostgreSQL from EC2 security group only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  tags = {
    Name        = "justinnegron-rds-sg"
    Environment = var.environment
  }
}
