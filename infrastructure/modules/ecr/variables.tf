variable "repository_name" {
  description = "Name of the ECR repository"
  type = string
}

variable "image_tag_mutability" {
  description = "Image tag mutability setting (MUTABLE or IMMUTABLE)"
  type = string
  default = "MUTABLE"
}