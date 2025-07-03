resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  }

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
      }
    }

}

data "aws_iam_policy_document" "bucket_policy" {
  dynamic "statement" {
    for_each = local.combined_statements
    content {
      effect = statement.value.Effect

      actions = statement.value.Action

      resources = statement.value.Resource

      principals {
        type        = "AWS"
        identifiers = [statement.value.Principal.AWS]
        }
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}
