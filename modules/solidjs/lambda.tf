data "aws_lambda_function" "existing_lambda" {
  count         = var.image_uri == "" ? 1 : 0
  function_name = "${local.name}-server"
}

module "server" {
  source                            = "terraform-aws-modules/lambda/aws"
  version                           = "~> 6.0.1"
  function_name                     = "${local.name}-server"
  description                       = "SolidJS Server Function"
  runtime                           = "nodejs18.x"
  memory_size                       = 512
  timeout                           = 15 # 30
  cloudwatch_logs_retention_in_days = 3
  create_package                    = false
  ignore_source_code_hash           = true
  create_lambda_function_url        = true
  cors                              = var.cors
  environment_variables = merge({
    LAMBDA_CONFIG_PROJECT_NAME = "${module.context.id}-backend"
    LAMBDA_CONFIG_AWS_REGION   = data.aws_region.current.name
    HOME                       = "/tmp"
  }, var.environment_variables)
  package_type             = "Image"
  image_uri                = var.image_uri == "" ? data.aws_lambda_function.existing_lambda[0].image_uri : var.image_uri
  attach_policy_statements = length(var.policy_statements) > 0 ? true : false
  policy_statements        = var.policy_statements
  attach_policies          = length(var.policies) > 0 ? true : false
  policies                 = var.policies
  number_of_policies       = length(var.policies)
  tags                     = local.tags
}

resource "aws_cloudwatch_event_rule" "cron" {
  name                = "${local.name}-cron"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda" {
  target_id = "lambda"
  arn       = module.server.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.cron.name
}

resource "aws_lambda_permission" "eventbridge_invoke" {
  statement_id  = "AllowExecutionFromEventbridge"
  action        = "lambda:InvokeFunction"
  function_name = module.server.lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron.arn
}