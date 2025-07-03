resource "aws_ecs_task_definition" "this" {
  family                   = var.task_family
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  container_definitions    = local.container_definitions
}

resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = var.security_group_ids
    assign_public_ip = var.assign_public_ip
    }
  dynamic "load_balancer" {
  for_each = var.target_group_arn != "" ? [1] : []

  content {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
    }
}
  depends_on = [aws_ecs_task_definition.this]
}
