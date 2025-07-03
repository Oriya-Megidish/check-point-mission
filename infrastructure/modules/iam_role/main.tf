data "aws_iam_policy_document" "role_policy" {
  count = length(var.resources) > 0 ? 1 : 0
  statement {
    effect    = "Allow"
    actions   = local.actions
    resources = var.resources
  }
}

resource "aws_iam_policy" "this" {
  count = length(var.resources) > 0 ? 1 : 0
  name   = "${var.role_name}-policy"
  policy = data.aws_iam_policy_document.role_policy[0].json
}

resource "aws_iam_role_policy_attachment" "this" {
  count = length(var.resources) > 0 ? 1 : 0
  role       = var.role_name
  policy_arn = aws_iam_policy.this[0].arn
}
