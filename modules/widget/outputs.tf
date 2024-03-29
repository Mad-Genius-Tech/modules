output "lambda_info" {
  value = {
    for k, v in module.lambda : k => {
      lambda_function_arn        = v.lambda_function_arn,
      lambda_function_invoke_arn = v.lambda_function_invoke_arn,
      lambda_function_name       = v.lambda_function_name,
      lambda_security_group      = module.lambda_sg[k].security_group_id
    }
  }
}