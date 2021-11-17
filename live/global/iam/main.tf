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

data "aws_iam_policy_document" "cloudwatch_read_only" {
  statement {
    effect = "Allow"
    actions = ["cloudwatch:Describe*", "cloudwatch:Get*", "cloudwatch:List*"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "cloudwatch_full_access" {
  statement {
    effect = "Allow"
    actions = ["cloudwatch:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_read_only" {
  policy = data.aws_iam_policy_document.ec2_read_only.json
  name = "ec2-read-only"
}

resource "aws_iam_policy" "cloudwatch_read_only" {
  policy = data.aws_iam_policy_document.cloudwatch_read_only.json
  name = "cloudwatch-read-only"
}

resource "aws_iam_policy" "cloudwatch_full_access" {
  policy = data.aws_iam_policy_document.cloudwatch_full_access.json
  name = "cloudwatch-full-access"
}

resource "aws_iam_user" "example" {
  count = length(var.user_names)
  name = element(var.user_names, count.index)
}

resource "aws_iam_policy_attachment" "ec2_access" {
  name = "ec2-access"
  count = length(var.user_names)
  policy_arn = aws_iam_policy.ec2_read_only.arn
  users = [element(aws_iam_user.example.*.name, count.index)]
}

resource "aws_iam_policy_attachment" "neo_cloudwatch_full_access" {
  name = "neo-cloudwatch-full-access"
  count = var.give_neo_cloudwatch_full_access
  policy_arn = aws_iam_policy.cloudwatch_full_access.arn
  users = [aws_iam_user.example.0.name]
}

resource "aws_iam_policy_attachment" "neo_cloudwatch_read_only" {
  name = "neo-cloudwatch-read-only"
  count = 1 - var.give_neo_cloudwatch_full_access
  policy_arn = aws_iam_policy.cloudwatch_read_only.arn
  users = [aws_iam_user.example.0.name]
}