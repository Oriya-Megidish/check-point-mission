output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ARN of the Target Group"
  value       = aws_lb_target_group.this.arn
}

output "listener_http_arn" {
  value       = length(aws_lb_listener.http) > 0 ? aws_lb_listener.http[0].arn : null
  description = "ARN של ה-HTTP listener"
}

output "listener_https_arn" {
  value       = length(aws_lb_listener.https) > 0 ? aws_lb_listener.https[0].arn : null
  description = "ARN של ה-HTTPS listener"
}