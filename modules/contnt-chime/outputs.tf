
output "chime_app_instance" {
  value = jsondecode(aws_lambda_invocation.chime_app_instance.result)
}

output "chime_app_admin" {
  value = jsondecode(aws_lambda_invocation.chime_app_admin.result)
}

output "cognito_signin_hook_arn" {
  value = module.cognito_signin_hook.lambda_function_arn
} 