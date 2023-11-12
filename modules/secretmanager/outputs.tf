output "secrets_info" {
  value = {
    for k, v in aws_secretsmanager_secret.secret : k => {
      id  = v.id
      arn = v.arn
    }
  }
}