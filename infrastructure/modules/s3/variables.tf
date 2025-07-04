﻿variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the KMS key used for SSE-KMS encryption"
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "Whether to allow deletion of non empty bucket"
}

variable "admin_role_arn" {
  description = "ARN of the admin IAM role with full access to the bucket"
  type        = string
}

variable "role_permissions" {
  description = "Map of IAM Role ARN to list of permissions (read, write)"
  type        = map(list(string))
}

