locals {
  read_actions = [
    "s3:GetObject",
    "s3:ListBucket"
  ]

  write_actions = [
    "s3:PutObject",
    "s3:DeleteObject"
  ]

  admin_statement = {
    Effect    = "Allow"
    Action    = ["s3:*"]
    Resource  = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]
    Principal = {
      AWS = var.admin_role_arn
    }
  }

  roles_statements = [
    for role_arn, permissions in var.role_permissions : {
      Effect    = "Allow"
      Action    = concat(
        contains(permissions, "write") ? local.write_actions : [],
        contains(permissions, "read") ? local.read_actions : []
      )
      Resource  = [
        aws_s3_bucket.this.arn,
        "${aws_s3_bucket.this.arn}/*"
      ],
      Principal = {
        AWS = role_arn
        }
    }
]

  combined_statements = concat(
    [local.admin_statement],
    local.roles_statements
  )
}