# =============================================================================
# RDS PostgreSQL — Managed Database
# =============================================================================
# Single-AZ db.t4g.micro in private subnets. Free tier eligible year 1.
# Automated backups with 7-day retention. Deletion protection enabled.

# --- Random password for the master DB user
resource "random_password" "db_password" {
  length  = 32
  special = false # Avoids URL-encoding issues in DATABASE_URL
}

# --- DB Subnet Group (private subnets only)
resource "aws_db_subnet_group" "main" {
  name       = "justinnegron-db-subnets"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name        = "justinnegron-db-subnets"
    Environment = var.environment
  }
}

# --- RDS Instance
resource "aws_db_instance" "main" {
  identifier     = "justinnegron-db"
  engine         = "postgres"
  engine_version = "15"
  instance_class = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 50 # Auto-scales storage up to 50 GB
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "portfolio_production"
  username = var.db_username
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = false # Single instance — portfolio site

  backup_retention_period = 7
  backup_window           = "04:00-05:00" # UTC — late night EST
  maintenance_window      = "sun:06:00-sun:07:00"

  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "justinnegron-db-final-${formatdate("YYYY-MM-DD", timestamp())}"

  # Performance Insights (free tier for db.t4g.micro)
  performance_insights_enabled = true

  tags = {
    Name        = "justinnegron-db"
    Environment = var.environment
    Project     = "justinnegron-dev"
  }

  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }
}
