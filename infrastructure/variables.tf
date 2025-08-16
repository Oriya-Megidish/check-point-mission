variable "account_id" {
  description = "Account id"
  type = string
  }

variable "aws_region" {
  description = "AWS region"
  type = string
  }

variable "kms_admin_role_arn" {
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
