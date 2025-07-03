module "s3_kms" {
  source          = "./modules/kms"
  key_alias       = "alias/s3-key"
  description     = "KMS key for S3 encryption"
  bucket_name     = local.s3_bucket_name
  admin_role_arn  = var.admin_role_arn
}

module "sqs_kms" {
  source          = "./modules/kms"
  key_alias       = "alias/sqs-key"
  description     = "KMS key for SQS encryption"
  sqs_queue_arn   = "arn:aws:sqs:${var.aws_region}:${var.account_id}:${local.sqs_queue_name}"
  admin_role_arn  = var.admin_role_arn
}

resource "aws_ssm_parameter" "my_parameter" {
  name        = local.parameter_path      
  description = "Token for my application"
  type        = "SecureString"              
  value       = var.token_parameter
  }

module "rest_service_ecr_repository" {
  source              = "./modules/ecr"
  repository_name     = local.rest_repo_name
  image_tag_mutability = "MUTABLE"
}

module "sql_listener_ecr_repository" {
  source              = "./modules/ecr"
  repository_name     = local.sql_listener_repo_name
  image_tag_mutability = "MUTABLE"
}

module "ecs_sql_listener_task_role" {
  source             = "./modules/iam_role" 
  role_name          = "ecs-sql-listener-task-role"
  assume_role_service = "ecs-tasks.amazonaws.com"  

  permissions = [
    "s3_write",
    "sqs_delete",
    "sqs_receive",
    "kms_encrypt",
    "kms_decrypt"
  ]

  resources = [
    "arn:aws:s3:::${local.s3_bucket_name}",
    "arn:aws:sqs:${var.aws_region}:${var.account_id}:${local.sqs_queue_name}",
     module.sqs_kms.key_arn,
     module.s3_kms.key_arn
    ]
}

module "ecs_rest_service_task_role" {
  source             = "./modules/iam_role" 
  role_name          = "ecs-rest-service-task-role"
  assume_role_service = "ecs-tasks.amazonaws.com"  

  permissions = [
    "sqs_send",
    "ssm_get",
    "kms_encrypt"
  ]

  resources = [
    "arn:aws:sqs:${var.aws_region}:${var.account_id}:${local.sqs_queue_name}",
    "arn:aws:ssm:${var.aws_region}:${var.account_id}:parameter${local.parameter_path}",
     module.sqs_kms.key_arn
    ]
}

resource "aws_cloudwatch_log_group" "ecs_rest_log_group" {
  name              = "/ecs/rest-service"  
  retention_in_days  = 14
  }

resource "aws_cloudwatch_log_group" "ecs_sql_listener_log_group" {
  name              = "/ecs/sql-listener-service"   
  retention_in_days  = 14
  }

module "ecs_execution_role" {
  source             = "./modules/iam_role" 
  role_name          = "ecs-execution-role"
  assume_role_service = "ecs-tasks.amazonaws.com"  

  permissions = [
    "ecr_pull",
    "cloudwatch_write"
  ]

  resources = [
    "arn:aws:ecr:${var.aws_region}:${var.account_id}:repository/${module.rest_service_ecr_repository.repository_name}",
    "arn:aws:ecr:${var.aws_region}:${var.account_id}:repository/${module.sql_listener_ecr_repository.repository_name}",
    "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:${aws_cloudwatch_log_group.ecs_rest_log_group.name}:*",
    "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:${aws_cloudwatch_log_group.ecs_sql_listener_log_group.name}:*"

]
  depends_on = [
    module.rest_service_ecr_repository,
    module.sql_listener_ecr_repository
]
}

resource "aws_iam_role_policy" "extra_policy" {
  name = "${module.ecs_execution_role.role_name}-extra-policy"
  role = module.ecs_execution_role.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
            "ecr:GetAuthorizationToken",
        ]
        Resource = "*"
        }
    ]
  })
}


module "oriya_sqs_queue" {
  source = "./modules/sqs"  

  queue_name                = local.sqs_queue_name
  dlq_name                  = "${var.owner}-queue-dlq"
  kms_key_arn               = module.sqs_kms.key_arn

  admin_role_arn = var.admin_role_arn

  role_permissions = {
    (module.ecs_rest_service_task_role.role_arn) = ["send"]
    (module.ecs_sql_listener_task_role.role_arn) = ["receive", "delete"]
    }
}

# S3 for sqs listener service
module "oriya_s3_bucket" {
  source = "./modules/s3"

  bucket_name    = local.s3_bucket_name
  kms_key_arn     = module.s3_kms.key_arn
  admin_role_arn = var.admin_role_arn

  role_permissions = {
    (module.ecs_sql_listener_task_role.role_arn) = ["write"]
    }

  force_destroy = true
}

module "network" {
  source = "./modules/network"

  owner               = var.owner
  vpc_cidr            = "10.0.0.0/16"
  enable_nat_gateway  = false

  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
    ]

  private_subnet_cidrs = [
    "10.0.101.0/24",
    "10.0.102.0/24"
    ]
}

module "ecs_rest_task_sg" {
  source      = "./modules/security_group"
  name        = "${var.owner}-rest-service-ecs-task-sg"
  description = "ECS task security group"
  vpc_id      = module.network.vpc_id

  egress = [
  {
    description      = "Allow outbound traffic to ECS tasks on port 53"
    from_port        = 53
    to_port          = 53
    protocol         = "udp"
    cidr_blocks  = ["0.0.0.0/0"]
    },
  {
    description      = "Allow outbound traffic to ECS tasks on port 443"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
    }
  ]
}

module "ecs_sql_listener_task_sg" {
  source      = "./modules/security_group"
  name        = "${var.owner}-sql-listener-ecs-task-sg"
  description = "ECS task security group"
  vpc_id      = module.network.vpc_id

  egress = [
  {
    description      = "Allow outbound traffic to ECS tasks on port 53"
    from_port        = 53
    to_port          = 53
    protocol         = "udp"
    cidr_blocks  = ["0.0.0.0/0"]
    },
  {
    description      = "Allow outbound traffic to ECS tasks on port 443"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
    }
  ]
}

module "endpoints_sg" {
  source      = "./modules/security_group"
  name        = "${var.owner}-endpoints-sg"
  description = "Endpoints security group"
  vpc_id      = module.network.vpc_id

  ingress = [
  {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  {
    description      = "Allow traffic to ECS tasks on port 53"
    from_port        = 53
    to_port          = 53
    protocol         = "udp"
    cidr_blocks  = [ 
    
    "10.0.101.0/24",
    "10.0.102.0/24"
    ]
},
  {
    description      = "Allow outbound traffic to ECS tasks on port 53"
    from_port        = 53
    to_port          = 53
    protocol         = "tcp"
    cidr_blocks  = [ 
    
    "10.0.101.0/24",
    "10.0.102.0/24"
    ]
}
 ]
  egress = [
  {
    description      = "Allow outbound traffic to ECS tasks on port 53"
    from_port        = 53
    to_port          = 53
    protocol         = "udp"
    cidr_blocks  = [ 
    
    "10.0.101.0/24",
    "10.0.102.0/24"
    ]
}
]
}

module "elb_sg" {
  source      = "./modules/security_group"
  name        = "${var.owner}-elb-sg"
  description = "ELB security group"
  vpc_id      = module.network.vpc_id

  ingress = [
  {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ]

  egress = [
  {
    description      = "Allow outbound traffic to ECS tasks on port 5000"
    from_port        = 5000
    to_port          = 5000
    protocol         = "tcp"
    security_groups  = [module.ecs_rest_task_sg.security_group_id]
    }
  ]
}


resource "aws_security_group_rule" "ecs_from_elb_ingress" {
  type                     = "ingress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  security_group_id        = module.ecs_rest_task_sg.security_group_id
  source_security_group_id = module.elb_sg.security_group_id
  }

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id       = module.network.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids   = module.network.private_subnet_ids
  security_group_ids = [module.endpoints_sg.security_group_id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id       = module.network.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids   = module.network.private_subnet_ids
  security_group_ids = [module.endpoints_sg.security_group_id]
  private_dns_enabled = true
}

# Gateway endpoint for S3 (for ECS service)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.network.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [module.network.private_route_table_id]
}

# Interface endpoint for CloudWatch Logs
resource "aws_vpc_endpoint" "logs" {
  vpc_id            = module.network.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.network.private_subnet_ids
  security_group_ids = [module.endpoints_sg.security_group_id]
  private_dns_enabled = true
  }

# Interface endpoint for SSM
resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = module.network.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.network.private_subnet_ids
  security_group_ids = [module.endpoints_sg.security_group_id]
  private_dns_enabled = true
}

# Interface endpoint for KMS
resource "aws_vpc_endpoint" "kms" {
  vpc_id            = module.network.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.network.private_subnet_ids
  security_group_ids = [module.endpoints_sg.security_group_id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "sqs" {
  vpc_id       = module.network.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.sqs"
  vpc_endpoint_type = "Interface"
  subnet_ids   = module.network.private_subnet_ids
  security_group_ids = [module.endpoints_sg.security_group_id]
  private_dns_enabled = true
}

module "my_alb" {
  source = "./modules/elb"

  name                       = "${var.owner}-alb"
  internal                   = false
  subnet_ids                 = module.network.public_subnet_ids
  security_groups            = [module.elb_sg.security_group_id]

  target_group_port          = 5000
  target_group_protocol      = "HTTP"
  target_group_target_type   = "ip"
  vpc_id                     = module.network.vpc_id
  target_group_health_check_path = "/health"

  listener_http              = true
  listener_https             = false
  }

  resource "aws_ecs_cluster" "main" {
    name = local.cluster_name
}

  module "rest_ecs_service" {
  source = "./modules/ecs"

  cluster_name       = aws_ecs_cluster.main.name
  service_name       = "rest_ecs_service"
  task_family        = "${var.owner}-rest-service-task"
  execution_role_arn = module.ecs_execution_role.role_arn
  task_role_arn      = module.ecs_rest_service_task_role.role_arn
  container_name     = "rest-app"
  container_image    = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.rest_repo_name}:${local.rest_version}"
  container_port     = 5000
  cpu                = 256
  memory             = 512
  region             = var.aws_region
  log_group_name     = aws_cloudwatch_log_group.ecs_rest_log_group.name
  log_stream_prefix  = "rest-service"
  container_env_vars = {
    AWS_REGION = var.aws_region
    SQS_QUEUE_URL = module.oriya_sqs_queue.main_queue_url
    SSM_TOKEN_PARAM = aws_ssm_parameter.my_parameter.name
}
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.ecs_rest_task_sg.security_group_id]
  target_group_arn = module.my_alb.target_group_arn
  depends_on = [aws_ecs_cluster.main, aws_cloudwatch_log_group.ecs_rest_log_group]
}

  module "sql_listener_ecs_service" {
  source = "./modules/ecs"

  cluster_name       = aws_ecs_cluster.main.name
  service_name       = "sql_listener_ecs_service"
  task_family        = "${var.owner}-sql-listener-task"
  execution_role_arn = module.ecs_execution_role.role_arn
  task_role_arn      = module.ecs_sql_listener_task_role.role_arn
  container_name     = "sql-listener"
  container_image    = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.sql_listener_repo_name}:${local.sql_listener_version}"
  container_port     = 9000
  cpu                = 256
  memory             = 512
  region             = var.aws_region
  log_group_name     = aws_cloudwatch_log_group.ecs_sql_listener_log_group.name
  log_stream_prefix  = "sql-listener" 
  container_env_vars = {
    AWS_REGION = var.aws_region
    SQS_QUEUE_URL = module.oriya_sqs_queue.main_queue_url
    S3_BUCKET_NAME = local.s3_bucket_name
}
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.ecs_sql_listener_task_sg.security_group_id]
  depends_on = [aws_ecs_cluster.main, aws_cloudwatch_log_group.ecs_sql_listener_log_group]
}

