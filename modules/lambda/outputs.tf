output "lambda_info" {
  value = {
    for k, v in module.lambda : k => {
      lambda_function_arn        = v.lambda_function_arn,
      lambda_function_invoke_arn = v.lambda_function_invoke_arn,
      lambda_function_name       = v.lambda_function_name,
      lambda_function_url        = v.lambda_function_url,
      lambda_security_group      = module.lambda_sg[k].security_group_id,
      lambda_function_alias_name = {
        "${var.stage_name}" = module.stage_alias[k].lambda_alias_name,
        "test"              = module.test_alias[k].lambda_alias_name
      }
      lambda_function_alias_arn = {
        "${var.stage_name}" = module.stage_alias[k].lambda_alias_arn,
        "test"              = module.test_alias[k].lambda_alias_arn
      }
      lambda_function_alias_invoke_arn = {
        "${var.stage_name}" = module.stage_alias[k].lambda_alias_invoke_arn,
        "test"              = module.test_alias[k].lambda_alias_invoke_arn
      }
    }
  }
}