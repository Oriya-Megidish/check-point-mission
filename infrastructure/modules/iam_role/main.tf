data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = [var.assume_role_service]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "role_policy" {
  count = length(var.actions) > 0 && length(var.resources) > 0 ? 1 : 0
  statement {
    effect    = "Allow"
    actions   = local.actions
    resources = var.resources
  }
}

resource "aws_iam_policy" "this" {
  count = length(var.actions) > 0 && length(var.resources) > 0 ? 1 : 0
  name   = "${var.role_name}-policy"
  policy = data.aws_iam_policy_document.role_policy.json
}

resource "aws_iam_role_policy_attachment" "this" {
  count = length(var.actions) > 0 && length(var.resources) > 0 ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}
