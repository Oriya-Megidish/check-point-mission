locals {
  admin_statement = [
    {
      Sid      = "AllowAdminAccess"
      Effect   = "Allow"
      Principal = {
        AWS = var.kms_admin_role_arn
      }
      Action   = "kms:*"
      Resource = "*"
    }
  ]

  s3_statement = var.bucket_name != null ? [
    {
      Sid      = "AllowS3ToUseKey"
      Effect   = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
      Action   = [
        "kms:GenerateDataKey*",
        "kms:Decrypt"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "kms:EncryptionContext:aws:s3:arn" = "arn:aws:s3:::${var.bucket_name}"
        }
      }
    }
  ] : []

  sqs_statement = var.sqs_queue_arn != null ? [
    {
      Sid      = "AllowSQSUseKey"
      Effect   = "Allow"
      Principal = {
        Service = "sqs.amazonaws.com"
      }
      Action   = [
        "kms:GenerateDataKey*",
        "kms:Decrypt"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "kms:EncryptionContext:aws:sqs:arn" = var.sqs_queue_arn
        }
      }
    }
  ] : []
}
