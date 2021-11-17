provider "aws" {
  region = "us-east-1"
}

data "aws_iam_policy_document" "ec2_read_only" {
  statement {
    effect = "Allow"
    actions = ["ec2:Describe*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_read_only" {
  policy = data.aws_iam_policy_document.ec2_read_only.json
  name = "ec2-read-only"
}

resource "aws_iam_user" "example" {
  count = length(var.user_names)
  name = element(var.user_names, count.index)
}

resource "aws_iam_policy_attachment" "ec2_access" {
  name = "ec2-access-for-iam-users"
  count = length(var.user_names)
  policy_arn = aws_iam_policy.ec2_read_only.arn
  user = element(aws_iam_user.example.*.name, count.index)
}