output "apigateway_account_arn" {
  value = join("", aws_iam_role.apigateway_cloudwatch_logs[*].arn)
}
