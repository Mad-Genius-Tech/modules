locals {
  default_settings = {
    "handler"                           = "handler.lambda_handler"
    "runtime"                           = "nodejs18.x"
    "timeout"                           = 300
    "memory_size"                       = 512
    "ephemeral_storage_size"            = 512
    "create_async_event_config"         = false
    "maximum_retry_attempts"            = 2
    "maximum_event_age_in_seconds"      = 21600
    "architectures"                     = ["x86_64"]
    "cloudwatch_logs_retention_in_days" = 7
    "environment_variables"             = {}
    "provisioned_concurrent_executions" = -1
    "layers"                            = []
    "policies"                          = []
    "policy_statements"                 = {}
    "keep_warm"                         = true
    "keep_warm_expression"              = "rate(15 minutes)"
    "secret_vars"                       = {}
    "create_lambda_function_url"        = false
    "cors" = {
      allow_origins     = null
      allow_methods     = null
      allow_headers     = null
      expose_headers    = null
      max_age_seconds   = null
      allow_credentials = null
    }
    "http_method" = "GET"
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        "provisioned_concurrent_executions" = -1
        "cloudwatch_logs_retention_in_days" = 30
        "keep_warm_expression"              = "rate(4 minutes)"
      }
    )
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  lambda_map = {
    for k, v in var.lambda : k => {
      "create"                            = coalesce(lookup(v, "create", null), true)
      "identifier"                        = "${module.context.id}-${k}"
      "description"                       = coalesce(lookup(v, "description", null), "Lambda ${module.context.id}-${k}")
      "project_name"                      = coalesce(lookup(v, "project_name", null), "${module.context.id}-${k}")
      "handler"                           = coalesce(lookup(v, "handler", null), local.merged_default_settings.handler)
      "runtime"                           = coalesce(lookup(v, "runtime", null), local.merged_default_settings.runtime)
      "timeout"                           = coalesce(lookup(v, "timeout", null), local.merged_default_settings.timeout)
      "memory_size"                       = coalesce(lookup(v, "memory_size", null), local.merged_default_settings.memory_size)
      "ephemeral_storage_size"            = coalesce(lookup(v, "ephemeral_storage_size", null), local.merged_default_settings.ephemeral_storage_size)
      "create_async_event_config"         = coalesce(lookup(v, "create_async_event_config", null), local.merged_default_settings.create_async_event_config)
      "maximum_retry_attempts"            = try(coalesce(lookup(v, "maximum_retry_attempts", null), local.merged_default_settings.maximum_retry_attempts), local.merged_default_settings.maximum_retry_attempts)
      "maximum_event_age_in_seconds"      = coalesce(lookup(v, "maximum_event_age_in_seconds", null), local.merged_default_settings.maximum_event_age_in_seconds)
      "environment_variables"             = merge(coalesce(lookup(v, "environment_variables", null), local.merged_default_settings.environment_variables), local.merged_default_settings.environment_variables)
      "policy_statements"                 = merge(coalesce(lookup(v, "policy_statements", null), local.merged_default_settings.policy_statements), local.merged_default_settings.policy_statements)
      "policies"                          = distinct(compact(concat(coalesce(lookup(v, "policies", null), local.merged_default_settings.policies), local.merged_default_settings.policies)))
      "architectures"                     = coalesce(lookup(v, "architectures", null), local.merged_default_settings.architectures)
      "keep_warm"                         = coalesce(lookup(v, "keep_warm_expression", null), local.merged_default_settings.keep_warm)
      "keep_warm_expression"              = coalesce(lookup(v, "keep_warm_expression", null), local.merged_default_settings.keep_warm_expression)
      "cloudwatch_logs_retention_in_days" = coalesce(lookup(v, "cloudwatch_logs_retention_in_days", null), local.merged_default_settings.cloudwatch_logs_retention_in_days)
      "secret_vars"                       = coalesce(lookup(v, "secret_vars", null), local.merged_default_settings.secret_vars)
      "layers"                            = distinct(compact(concat(coalesce(lookup(v, "layers", null), local.merged_default_settings.layers), local.merged_default_settings.layers)))
      "cloudwatch_logs_retention_in_days" = coalesce(lookup(v, "cloudwatch_logs_retention_in_days", null), local.merged_default_settings.cloudwatch_logs_retention_in_days)
      "provisioned_concurrent_executions" = coalesce(lookup(v, "provisioned_concurrent_executions", null), local.merged_default_settings.provisioned_concurrent_executions)
      "keep_warm"                         = coalesce(lookup(v, "keep_warm", null), local.merged_default_settings.keep_warm)
      "create_lambda_function_url"        = coalesce(lookup(v, "create_lambda_function_url", null), local.merged_default_settings.create_lambda_function_url)
      "keep_warm_expression"              = coalesce(lookup(v, "keep_warm_expression", null), local.merged_default_settings.keep_warm_expression)
      "cors"                              = coalesce(lookup(v, "cors", null), local.merged_default_settings.cors)
      "apigateway_path"                   = coalesce(lookup(v, "apigateway_path", null), k)
      "http_method"                       = coalesce(lookup(v, "http_method", null), local.merged_default_settings.http_method)
    } if coalesce(lookup(v, "create", null), true) == true
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  secret_vars_map = merge([
    for k, v in local.lambda_map : {
      for var in keys(v.secret_vars) : "${k}|${var}" => v.secret_vars[var]
    } if length(v.secret_vars) > 0
  ]...)
}

data "aws_secretsmanager_secret" "secret" {
  for_each = local.secret_vars_map
  name     = each.value.secret_path
}

data "aws_secretsmanager_secret_version" "secret" {
  for_each  = local.secret_vars_map
  secret_id = data.aws_secretsmanager_secret.secret[each.key].id
}

locals {
  secret_vars_env = {
    for k, v in local.lambda_map : k => {
      for k1, v1 in v.secret_vars : k1 =>
      jsondecode(nonsensitive(data.aws_secretsmanager_secret_version.secret["${k}|${k1}"].secret_string))[v1.property]
    } if length(v.secret_vars) > 0
  }
}

module "s3_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "~> 3.15.0"
  create_bucket = var.lambda_bucket_name == "" ? false : true
  bucket        = var.lambda_bucket_name
  force_destroy = false
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning = {
    status = "Enabled"
  }
  tags = local.tags
}

resource "aws_s3_object" "s3_object" {
  count  = var.lambda_bucket_name == "" ? 0 : 1
  bucket = module.s3_bucket.s3_bucket_id
  key    = "placeholder.zip"
  source = "${path.module}/placeholder.zip"

  lifecycle {
    ignore_changes = [
      key,
      source,
      etag
    ]
  }
}

module "lambda" {
  for_each                          = local.lambda_map
  source                            = "terraform-aws-modules/lambda/aws"
  version                           = "~> 6.0.0"
  function_name                     = each.value.identifier
  description                       = "Lambda ${each.value.identifier}"
  handler                           = each.value.handler
  layers                            = each.value.layers
  runtime                           = each.value.runtime
  memory_size                       = each.value.memory_size
  ephemeral_storage_size            = each.value.ephemeral_storage_size
  timeout                           = each.value.timeout
  cloudwatch_logs_retention_in_days = each.value.cloudwatch_logs_retention_in_days
  create_async_event_config         = each.value.create_async_event_config
  maximum_retry_attempts            = each.value.maximum_retry_attempts
  maximum_event_age_in_seconds      = each.value.maximum_event_age_in_seconds
  architectures                     = each.value.architectures
  create_package                    = false
  create_lambda_function_url        = each.value.create_lambda_function_url
  cors                              = each.value.cors
  s3_existing_package = var.lambda_bucket_name == "" ? null : {
    bucket = module.s3_bucket.s3_bucket_id
    key    = aws_s3_object.s3_object[0].id
  }
  environment_variables = merge(
    each.value.environment_variables,
    {
      LAMBDA_CONFIG_S3_BUCKET    = var.lambda_bucket_name
      LAMBDA_CONFIG_PROJECT_NAME = each.value.project_name
      LAMBDA_CONFIG_AWS_REGION   = data.aws_region.current.name
    },
    lookup(local.secret_vars_env, each.key, {})
  )
  vpc_subnet_ids           = var.vpc_id == "" ? null : var.subnet_ids
  vpc_security_group_ids   = var.vpc_id == "" ? [] : [module.lambda_sg[each.key].security_group_id]
  attach_network_policy    = var.vpc_id == "" ? false : true
  attach_policy_statements = length(each.value.policy_statements) > 0 ? true : false
  policy_statements        = each.value.policy_statements
  attach_policies          = length(each.value.policies) > 0 ? true : false
  policies                 = each.value.policies
  number_of_policies       = length(each.value.policies)
  ignore_source_code_hash  = true
  attach_policy_json       = true
  policy_json              = <<-EOT
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                  "s3:PutObject",
                  "s3:GetObject"
                ],
                "Resource": ["arn:aws:s3:::${var.lambda_bucket_name}/*"]

            }
        ]
    }
  EOT
  tags                     = local.tags
}

module "lambda_sg" {
  for_each    = local.lambda_map
  source      = "terraform-aws-modules/security-group/aws"
  version     = "~> 5.1.0"
  create      = var.vpc_id == "" ? false : true
  name        = "${each.value.identifier}-sg"
  description = "Lambda ${each.value.identifier} Security group"
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

resource "aws_cloudwatch_event_rule" "cron" {
  for_each            = { for k, v in local.lambda_map : k => v if v.keep_warm == true }
  name                = "${each.value.identifier}-handler.keep_warm_callback"
  description         = "Sends event to lambda ${each.value.identifier} based on cronjob"
  schedule_expression = each.value.keep_warm_expression
  tags                = local.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  for_each  = { for k, v in local.lambda_map : k => v if v.keep_warm == true }
  target_id = each.value.identifier
  rule      = aws_cloudwatch_event_rule.cron[each.key].name
  arn       = module.lambda[each.key].lambda_function_arn

  input_transformer {
    input_paths = {
      "account" : "$.account",
      "detail" : "$.detail",
      "detail-type" : "$.detail-type",
      "id" : "$.id",
      "region" : "$.region",
      "resources" : "$.resources",
      "source" : "$.source",
      "time" : "$.time",
      "version" : "$.version"
    }
    input_template = <<EOF
{"time": <time>, "detail-type": <detail-type>, "source": <source>,"account": <account>, "region": <region>,"detail": <detail>, "version": <version>,"resources": <resources>,"id": <id>,"kwargs": {}}
EOF
  }
}

resource "aws_lambda_permission" "cloudwatch" {
  for_each      = { for k, v in local.lambda_map : k => v if v.keep_warm == true }
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda[each.key].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron[each.key].arn
}
