locals {
  permission_map = {
    s3_read = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    s3_write = [
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    sqs_send = [
      "sqs:SendMessage"
    ]
    sqs_receive = [
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl"
    ]
    sqs_delete = [
      "sqs:DeleteMessage"
    ]
    ecr_pull = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]

    cloudwatch_write = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]

    ssm_get = [
      "ssm:GetParameter"
      ]
    kms_decrypt = [
      "kms:Decrypt"
]
    kms_encrypt = [
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
]
    }

  actions = concat(
    contains(var.permissions, "s3_read")    ? local.permission_map.s3_read    : [],
    contains(var.permissions, "s3_write")   ? local.permission_map.s3_write   : [],
    contains(var.permissions, "sqs_send")   ? local.permission_map.sqs_send   : [],
    contains(var.permissions, "sqs_receive")? local.permission_map.sqs_receive: [],
    contains(var.permissions, "sqs_delete") ? local.permission_map.sqs_delete : [],
    contains(var.permissions, "ecr_pull")   ? local.permission_map.ecr_pull   : [],
    contains(var.permissions, "cloudwatch_write") ? local.permission_map.cloudwatch_write : [],
    contains(var.permissions, "ssm_get")    ? local.permission_map.ssm_get : []
  )

}
