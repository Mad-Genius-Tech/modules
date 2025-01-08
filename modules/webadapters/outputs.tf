output "lambda_info" {
  value = {
    for k, v in module.webadapter : k => {
      lambda_function_arn        = v.lambda_function_arn,
      lambda_function_invoke_arn = v.lambda_function_invoke_arn,
      lambda_function_name       = v.lambda_function_name,
    }
  }
}

# output "lambda_map" {
#   value = local.lambda_map
# }