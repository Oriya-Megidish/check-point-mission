locals {
  s3_bucket_name = "${var.owner}-hen-s3-bucket"
  sqs_queue_name = "${var.owner}-sqs-queue"
  cluster_name = "${var.owner}-cluster"
  parameter_path = "/${var.owner}/token"
  rest_service_repo_uri = "${var.account_id}.dkr.${var.aws_region}.amazonaws.com/rest_service"
  rest_version = "latest"
  sql_listener_repo_uri = "${var.account_id}.dkr.${var.aws_region}.amazonaws.com/sql_listener"
  sql_listener_version = "latest"
}

