variable "name" {
  description = "The name of the load balancer"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security group IDs for the ALB"
  type        = list(string)
}

variable "internal" {
  description = "If true, ALB will be internal"
  type        = bool
  default     = false
}

variable "listener_http" {
  description = "Enable HTTP listener on port 80"
  type        = bool
  default     = true
}

variable "listener_https" {
  description = "Enable HTTPS listener on port 443"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of ACM certificate for HTTPS"
  type        = string
  default     = ""
}

variable "target_group_port" {
  description = "Port on which target group receives traffic"
  type        = number
  default     = 5000
}

variable "target_group_protocol" {
  description = "Protocol used by target group"
  type        = string
  default     = "HTTP"
}

variable "target_group_target_type" {
  description = "Type of target: instance, ip or lambda"
  type        = string
  default     = "ip"
}

variable "target_group_health_check_path" {
  description = "Health check path"
  type        = string
}
