variable "queue_name" {
  description = "Name of the main SQS queue"
  type        = string
}

variable "dlq_name" {
  description = "Name of the Dead Letter Queue (DLQ)"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key to use for encryption"
  type        = string
}

variable "max_receive_count" {
  description = "Number of times a message can be received before sent to DLQ"
  type        = number
  default     = 5
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout for the queue in seconds"
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "Message retention period in seconds"
  type        = number
  default     = 1209600
}

variable "admin_role_arn" {
  type        = string
  description = "ARN of the admin IAM role with full permissions on the queue"
}

variable "role_permissions" {
  type = map(list(string))
  description = "Map of IAM role ARNs to list of permissions. Possible permissions: \"send\", \"receive\", \"delete\""
  default     = {}
}
