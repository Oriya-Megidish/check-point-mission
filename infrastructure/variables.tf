variable "account_id" {
  description = "Account id"
  type = string
}

variable "aws_region" {
  description = "AWS region"
  type = string
}

variable "admin_role_arn" {
  description = "ARN of admin iam role"
  type = string
}

variable "token_parameter" {
  description = "The token rest service compare to"
  type = string
}

variable "owner" {
  description = "Owner of the resources"
  type = string
}