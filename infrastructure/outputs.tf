output "alb_url" {
  description = "The DNS URL of the ALB"
  value = "http://${module.my_alb.alb_dns_name}"
  }﻿
