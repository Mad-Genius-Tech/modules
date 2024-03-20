locals {
  default_settings = {
    "handler"                           = "handler.lambda_handler"
    "runtime"                           = "python3.11"
    "timeout"                           = 10
    "memory_size"                       = 1024
    "ephemeral_storage_size"            = 1024
    "create_async_event_config"         = false
    "maximum_retry_attempts"            = 2
    "maximum_event_age_in_seconds"      = 21600
    "architectures"                     = ["x86_64"]
    "cloudwatch_logs_retention_in_days" = 3
    "environment_variables"             = {}
    "reserved_concurrent_executions"    = -1
    "provisioned_concurrent_executions" = -1
    "policies"                          = [""]
    "policy_statements"                 = {}
    "create_lambda_function_url"        = true
    "keep_warm"                         = true
    "keep_warm_expression"              = "rate(5 minutes)"
    "secret_vars"                       = {}
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        "provisioned_concurrent_executions" = -1
      }
    )
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


data "aws_lambda_function" "lambda_function" {
  count         = var.image_uri == "" ? 1 : 0
  function_name = module.context.id
}

module "webadapter" {
  source                            = "terraform-aws-modules/lambda/aws"
  version                           = "~> 7.2.1"
  function_name                     = module.context.id
  description                       = "${module.context.id} webadapter"
  create_package                    = false
  memory_size                       = local.merged_default_settings.memory_size
  ephemeral_storage_size            = local.merged_default_settings.ephemeral_storage_size
  timeout                           = local.merged_default_settings.timeout
  cloudwatch_logs_retention_in_days = local.merged_default_settings.cloudwatch_logs_retention_in_days
  reserved_concurrent_executions    = local.merged_default_settings.reserved_concurrent_executions
  provisioned_concurrent_executions = local.merged_default_settings.provisioned_concurrent_executions
  create_async_event_config         = local.merged_default_settings.create_async_event_config
  maximum_retry_attempts            = local.merged_default_settings.maximum_retry_attempts
  maximum_event_age_in_seconds      = local.merged_default_settings.maximum_event_age_in_seconds
  create_lambda_function_url        = local.merged_default_settings.create_lambda_function_url
  cors                              = var.cors
  vpc_subnet_ids                    = var.vpc_id == "" ? null : var.subnet_ids
  vpc_security_group_ids            = var.vpc_id == "" ? [] : [module.lambda_sg.security_group_id]
  attach_network_policy             = var.vpc_id == "" ? false : true
  #attach_policy                     = true
  #policy                            = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  attach_policy_statements          = length(var.policy_statements) > 0 ? true : false
  policy_statements                 = var.policy_statements
  attach_policy_json                = true
  policy_json                       = <<-EOT
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
  environment_variables = merge(
    var.environment_variables,
    {
      LAMBDA_CONFIG_PROJECT_NAME = "${module.context.id}-webadapter"
      LAMBDA_CONFIG_AWS_REGION   = data.aws_region.current.name
    },
    local.merged_default_settings.environment_variables,
    local.secret_vars_env,
  )
  package_type  = "Image"
  image_uri     = var.image_uri == "" ? data.aws_lambda_function.lambda_function[0].image_uri : var.image_uri
  architectures = local.merged_default_settings.architectures
  tags          = local.tags
}

module "lambda_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "~> 5.1.0"
  create      = var.vpc_id == "" ? false : true
  name        = "${module.context.id}-sg"
  description = "Lambda ${module.context.id} Security group"
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  vpc_id = var.vpc_id
}

module "stage_alias" {
  source           = "terraform-aws-modules/lambda/aws//modules/alias"
  version          = "~> 6.0.0"
  refresh_alias    = false
  name             = var.stage_name
  function_name    = module.webadapter.lambda_function_name
  function_version = module.webadapter.lambda_function_version
}

module "test_alias" {
  source           = "terraform-aws-modules/lambda/aws//modules/alias"
  version          = "~> 6.0.0"
  refresh_alias    = false
  name             = "test"
  function_name    = module.webadapter.lambda_function_name
  function_version = module.webadapter.lambda_function_version
}

resource "aws_cloudwatch_event_rule" "cron" {
  count               = local.merged_default_settings.keep_warm ? 1 : 0
  name                = "${module.context.id}-keepwarm"
  description         = "Sends event to lambda ${module.context.id} based on cronjob"
  schedule_expression = local.merged_default_settings.keep_warm_expression
  tags                = local.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  count     = local.merged_default_settings.keep_warm ? 1 : 0
  target_id = module.context.id
  rule      = aws_cloudwatch_event_rule.cron[0].name
  arn       = module.webadapter.lambda_function_arn
}

resource "aws_lambda_permission" "cloudwatch" {
  count         = local.merged_default_settings.keep_warm ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.webadapter.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron[0].arn
}

data "aws_secretsmanager_secret" "secret" {
  for_each = var.secret_vars
  name     = each.value.secret_path
}

data "aws_secretsmanager_secret_version" "secret" {
  for_each  = var.secret_vars
  secret_id = data.aws_secretsmanager_secret.secret[each.key].id
}

locals {
  secret_vars_env = {
    for k, v in var.secret_vars : k =>
    jsondecode(nonsensitive(data.aws_secretsmanager_secret_version.secret[k].secret_string))[v.property] if length(var.secret_vars) > 0
  }
}