variable "key_alias" {
  type = string
}

variable "description" {
  type = string
}

variable "kms_admin_role_arn" {
  type = string
}

variable "bucket_name" {
  type = string
  default = null
}

variable "sqs_queue_arn" {
  type = string
  default = null
}
variable "extra_key_users" {
  type = list(string)
  default = []
}
