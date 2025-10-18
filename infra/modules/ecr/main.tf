variable "name" { type = string }

resource "aws_ecr_repository" "repo" {
  name                 = var.name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration { encryption_type = "AES256" }
  tags = { Name = var.name }
}

output "repository_url" { value = aws_ecr_repository.repo.repository_url }
output "repository_id" { value = aws_ecr_repository.repo.id }

