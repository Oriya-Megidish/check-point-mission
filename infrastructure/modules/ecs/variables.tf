variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "task_family" {
  description = "Name of the ECS task family"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution IAM role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task IAM role"
  type        = string
}

variable "container_name" {
  description = "Name of the container in the task definition"
  type        = string
}

variable "container_image" {
  description = "Docker image URI for the container"
  type        = string
}

variable "container_port" {
  description = "Port number on which the container listens"
  type        = number
}

variable "cpu" {
  description = "CPU units for the task"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory (MB) for the task"
  type        = number
  default     = 512
}

variable "log_group_name" {
  description = "CloudWatch Log Group name for container logs"
  type        = string
}

variable "log_stream_prefix" {
  description = "CloudWatch log stream prefix for container logs"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the existing ALB target group to attach the ECS service"
  type        = string
  default     = ""  
} 

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ECS service networking"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with ECS service"
  type = list(string)
}

variable "desired_count" {
  description = "Desired number of tasks"
  type = number
  default = 1
}

variable "assign_public_ip" {
  description = "Assign public IP to tasks"
  type = bool
  default = false
}

variable "container_env_vars" {
  description = "Map of environment variables"
  type        = map(string)
  default     = {}
}
