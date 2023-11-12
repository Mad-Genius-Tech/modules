
output "iam_role_arn" {
  value = {
    for k, v in aws_iam_role.iam_role : k => v.arn
  }
}