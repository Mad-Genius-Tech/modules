locals {
  default_settings = {
    "handler"                           = "handler.lambda_handler"
    "runtime"                           = "python3.10"
    "timeout"                           = 20
    "memory_size"                       = 1024
    "ephemeral_storage_size"            = 1024
    "create_async_event_config"         = false
    "maximum_retry_attempts"            = 1
    "maximum_event_age_in_seconds"      = 21600
    "architectures"                     = ["x86_64"]
    "cloudwatch_logs_retention_in_days" = 3
    "environment_variables"             = {}
    "provisioned_concurrent_executions" = -1
    "policies"                          = ["arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole"]
    "policy_statements"                 = {}
    "create_lambda_function_url"        = true
    "keep_warm"                         = true
    "keep_warm_expression"              = "rate(5 minutes)"
    "secret_vars"                       = {}
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
      }
    )
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "imgproxy" {
  source                            = "terraform-aws-modules/lambda/aws"
  version                           = "~> 6.0.1"
  function_name                     = "${module.context.id}-imgproxy"
  description                       = "${module.context.id} imgproxy"
  create_package                    = false
  memory_size                       = local.merged_default_settings.memory_size
  ephemeral_storage_size            = local.merged_default_settings.ephemeral_storage_size
  timeout                           = local.merged_default_settings.timeout
  cloudwatch_logs_retention_in_days = local.merged_default_settings.cloudwatch_logs_retention_in_days
  create_async_event_config         = local.merged_default_settings.create_async_event_config
  maximum_retry_attempts            = local.merged_default_settings.maximum_retry_attempts
  maximum_event_age_in_seconds      = local.merged_default_settings.maximum_event_age_in_seconds
  create_lambda_function_url        = local.merged_default_settings.create_lambda_function_url
  cors                              = var.cors
  attach_policy                     = true
  policy                            = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  attach_policy_jsons               = true
  policy_jsons = [
    <<-EOT
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:DescribeImages",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability"
          ],
          "Resource": ["*"]
        }
      ]
    }
    EOT
  ]
  environment_variables = merge(
    var.environment_variables,
    {
      LAMBDA_CONFIG_PROJECT_NAME = "${module.context.id}-imgproxy"
      LAMBDA_CONFIG_AWS_REGION   = data.aws_region.current.name
    },
    local.merged_default_settings.environment_variables
  )
  package_type  = "Image"
  image_uri     = var.image_uri
  architectures = local.merged_default_settings.architectures
  tags          = local.tags
}

resource "aws_cloudwatch_event_rule" "cron" {
  count               = local.merged_default_settings.keep_warm ? 1 : 0
  name                = "${module.context.id}-imgproxy-keepwarm"
  description         = "Sends event to lambda ${module.context.id}-imgproxy based on cronjob"
  schedule_expression = local.merged_default_settings.keep_warm_expression
  tags                = local.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  count     = local.merged_default_settings.keep_warm ? 1 : 0
  target_id = "${module.context.id}-imgproxy"
  rule      = aws_cloudwatch_event_rule.cron[0].name
  arn       = module.imgproxy.lambda_function_arn
}

resource "aws_lambda_permission" "cloudwatch" {
  count         = local.merged_default_settings.keep_warm ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.imgproxy.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron[0].arn
}