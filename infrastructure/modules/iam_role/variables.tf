variable "role_name" {
  description = "Name of the IAM role to create"
  type = string
}

variable "assume_role_service" {
  description = "The AWS service principal that can assume this role, e.g. ecs-tasks.amazonaws.com"
  type = string
}

variable "permissions" {
  description = "List of permission keys to assign to this role. Supported: s3_read, s3_write, sqs_send, sqs_receive, sqs_delete, ssm_get, ecr_pull, cloudwatch_write"
  type = list(string)
  default = []
}

variable "resources" {
  description = "List of resource ARNs to which the permissions apply"
  type = list(string)
  default = []
}
