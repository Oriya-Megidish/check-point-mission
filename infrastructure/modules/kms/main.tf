resource "aws_kms_key" "this" {
  description             = var.description
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      local.admin_statement,
      local.s3_statement,
      local.sqs_statement
      local.extra_users_statements
    )
  })
}

resource "aws_kms_alias" "alias" {
  name          = var.key_alias
  target_key_id = aws_kms_key.this.key_id
}
