module "lambda" {
  create                            = var.create && var.authentication_type == "federated-authentication" && var.enable_log && var.lambda_local_package != ""
  source                            = "terraform-aws-modules/lambda/aws"
  version                           = "~> 6.0.0"
  function_name                     = "AWSClientVPN-${local.service_name}"
  handler                           = "lambda_function.lambda_handler"
  runtime                           = "python3.12"
  memory_size                       = 128
  timeout                           = 10
  cloudwatch_logs_retention_in_days = var.logs_retention_in_days
  architectures                     = ["arm64"]
  create_package                    = false
  create_lambda_function_url        = false
  local_existing_package            = var.lambda_local_package != "" ? var.lambda_local_package : null
  environment_variables = merge(
    var.lambda_environment_variables, {
      "LAMBDA_ENV" = var.stage_name
    }
  )
  ignore_source_code_hash = var.lambda_ignore_source_code_hash
  tags                    = local.tags
}
