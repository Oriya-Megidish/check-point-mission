resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = var.security_groups
}

resource "aws_lb_target_group" "this" {
  name        = "${var.name}-tg"
  port        = var.target_group_port
  protocol    = var.target_group_protocol
  target_type = var.target_group_target_type
  vpc_id      = var.vpc_id

  health_check {
    path                = var.target_group_health_check_path
    protocol            = var.target_group_protocol
    matcher             = "200"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }
}

resource "aws_lb_listener" "http" {
  count            = var.listener_http ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port             = 80
  protocol         = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_listener" "https" {
  count            = var.listener_https && var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port             = 443
  protocol         = "HTTPS"
  ssl_policy       = "ELBSecurityPolicy-2016-08"
  certificate_arn  = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
    }
}
