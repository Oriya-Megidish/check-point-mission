resource "aws_sqs_queue" "dlq" {
  name                      = var.dlq_name
  kms_master_key_id         = var.kms_key_arn
  message_retention_seconds = var.message_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
}

resource "aws_sqs_queue" "main" {
  name                      = var.queue_name
  kms_master_key_id         = var.kms_key_arn
  message_retention_seconds = var.message_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}

data "aws_iam_policy_document" "queue_policy" {
  dynamic "statement" {
    for_each = local.combined_statements
    content {
      effect    = statement.value.Effect
      actions   = statement.value.Action
      resources = [statement.value.Resource]

      principals {
        type        = "AWS"
        identifiers = [statement.value.Principal.AWS]
        }
    }
  }
}

resource "aws_sqs_queue_policy" "this" {
  queue_url  = aws_sqs_queue.main.id
  policy = data.aws_iam_policy_document.queue_policy.json
}
