locals {
  s3_bucket_name = "${var.owner}-hen-s3-bucket-1"
  sqs_queue_name = "${var.owner}-sqs-queue"
  cluster_name = "${var.owner}-cluster"
  parameter_path = "/${var.owner}/token"
  rest_repo_name = "rest_service"
  rest_version = "latest"
  sql_listener_repo_name = "sql_listener"
  sql_listener_version = "latest"
}
