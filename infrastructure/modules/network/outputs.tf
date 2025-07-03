output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
  }

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
  }

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
  }

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.this.id
  }

output "private_route_table_id" {
  description = "The ID of the private route table"
  value = aws_route_table.private.id
}