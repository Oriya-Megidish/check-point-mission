locals {
  container_definitions = jsonencode([
    {
      name  = var.container_name,
      image = var.container_image,

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ],

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = var.log_group_name,
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = var.log_stream_prefix
          }
        }
    }
   ])
}
