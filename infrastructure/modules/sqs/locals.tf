locals {
  send_actions = [
    "sqs:SendMessage"
  ]

  receive_actions = [
    "sqs:ReceiveMessage",
    "sqs:GetQueueAttributes",
    "sqs:GetQueueUrl"
  ]

  delete_actions = [
    "sqs:DeleteMessage"
  ]


  role_statements = [
    for role_arn, permissions in var.role_permissions : {
      Effect = "Allow"
      Action = concat(
        contains(permissions, "send") ? local.send_actions : [],
        contains(permissions, "receive") ? local.receive_actions : [],
        contains(permissions, "delete") ? local.delete_actions : []
      )
      Resource  = aws_sqs_queue.main.arn
      Principal = {
        AWS = role_arn
      }
    }
  ]

}
