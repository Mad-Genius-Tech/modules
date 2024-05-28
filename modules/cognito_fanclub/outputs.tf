output "user_pool" {
  value = {
    for k, v in aws_cognito_user_pool.user_pool : k => {
      id   = v.id
      arn  = v.arn
      name = v.name
    }
  }
}

output "identity_pool" {
  value = {
    for k, v in aws_cognito_identity_pool.identity_pool : k => {
      id  = v.id
      arn = v.arn
    }
  }
}

output "client_id" {
  value = {
    for k, v in aws_cognito_user_pool_client.client : k => v.id
  }
}

output "client_secret" {
  value = {
    for k, v in aws_cognito_user_pool_client.client : k => v.client_secret
  }
  sensitive = true
}

output "authenticated_role" {
  value = {
    for k, v in aws_iam_role.auth_iam_role : k => {
      name = v.name
      arn  = v.arn
    }
  }
}

output "guest_role" {
  value = {
    for k, v in aws_iam_role.guest_iam_role : k => {
      name = v.name
      arn  = v.arn
    }
  }
}