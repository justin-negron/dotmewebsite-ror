# =============================================================================
# ECR — Docker Image Registry
# =============================================================================
# Private registry for the Rails API Docker image.
# Lifecycle policy keeps the last 10 images to control storage costs.

resource "aws_ecr_repository" "api" {
  name                 = "justinnegron-api"
  image_tag_mutability = "MUTABLE" # Allows :latest tag updates
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true # Scans for CVEs on every push
  }

  tags = {
    Name        = "justinnegron-api"
    Environment = var.environment
    Project     = "justinnegron-dev"
  }
}

resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
