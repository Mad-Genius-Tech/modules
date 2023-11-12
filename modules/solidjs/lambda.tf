
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
  environment_variables = {
    LAMBDA_CONFIG_PROJECT_NAME = "${module.context.id}-backend"
    LAMBDA_CONFIG_AWS_REGION   = data.aws_region.current.name
    HOME                       = "/tmp"
  }
  package_type = "Image"
  image_uri    = var.image_uri
  tags         = local.tags
}

resource "aws_cloudwatch_event_rule" "cron" {
  name                = "${local.name}-cron"
  schedule_expression = "rate(5 minutes)"
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