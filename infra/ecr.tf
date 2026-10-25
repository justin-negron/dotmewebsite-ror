# =============================================================================
# ECR — Docker Image Registry
# =============================================================================
# Private registry for the Rails API Docker image.
# Lifecycle policy keeps the last 5 images to control storage costs.

resource "aws_ecr_repository" "api" {
  name = "justinnegron-api"
  # A git sha tag always means the same image; a redeploy of a pushed sha uses TAG=<sha>.
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true # Scans for CVEs on every push
  }

  tags = {
    Name = "justinnegron-api"
  }
}

resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
