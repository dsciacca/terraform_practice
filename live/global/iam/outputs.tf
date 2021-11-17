output "all_arns" {
  value = aws_iam_user.example.*.arn
}

output "neo_arn" {
  value = aws_iam_user.example.0.arn
}

output "trinity_arn" {
  value = aws_iam_user.example.1.arn
}

output "morpheus_arn" {
  value = aws_iam_user.example.2.arn
}