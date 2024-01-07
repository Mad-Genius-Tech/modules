output "user_pool" {
  value = {
    for k, v in aws_cognito_user_pool.pool : k => {
      id   = v.id
      arn  = v.arn
      name = v.name
    }
  }
}

output "client_id" {
  value = {
    for k, v in aws_cognito_user_pool_client.client : k => v.id
  }
}