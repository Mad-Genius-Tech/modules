locals {
  default_settings = {
    "handler"                           = "index.handler"
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
    "local_existing_package"            = ""
    "ignore_source_code_hash"           = true
    "policies"                          = []
    "policy_statements"                 = {}
    "keep_warm"                         = false
    "keep_warm_expression"              = "rate(60 minutes)"
    "create_event_scheduler_role"       = false
    "sqs"                               = {}
    "secret_vars"                       = {}
    "cloudwatch_events"                 = {}
    "create_lambda_function_url"        = false
    "lambda_permission" = {
      "principal"  = ""
      "source_arn" = ""
    }
    "scaling_config" = [{}]
    "cors" = {
      allow_origins     = null
      allow_methods     = null
      allow_headers     = null
      expose_headers    = null
      max_age_seconds   = null
      allow_credentials = null
    }
    "lambda_permissions" = {}
    "eventbridge_rules"  = {}
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        "provisioned_concurrent_executions" = 2
        "cloudwatch_logs_retention_in_days" = 30
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
      "keep_warm"                         = coalesce(lookup(v, "keep_warm", null), local.merged_default_settings.keep_warm)
      "keep_warm_expression"              = coalesce(lookup(v, "keep_warm_expression", null), local.merged_default_settings.keep_warm_expression)
      "create_event_scheduler_role"       = coalesce(lookup(v, "create_event_scheduler_role", null), local.merged_default_settings.create_event_scheduler_role)
      "cloudwatch_logs_retention_in_days" = coalesce(lookup(v, "cloudwatch_logs_retention_in_days", null), local.merged_default_settings.cloudwatch_logs_retention_in_days)
      "stage_name"                        = coalesce(lookup(v, "stage_name", null), var.stage_name)
      "sqs"                               = coalesce(lookup(v, "sqs", null), local.merged_default_settings.sqs)
      "secret_vars"                       = coalesce(lookup(v, "secret_vars", null), local.merged_default_settings.secret_vars)
      "cloudwatch_events"                 = coalesce(lookup(v, "cloudwatch_events", null), local.merged_default_settings.cloudwatch_events)
      "layers"                            = distinct(compact(concat(coalesce(lookup(v, "layers", null), local.merged_default_settings.layers), local.merged_default_settings.layers)))
      "cloudwatch_logs_retention_in_days" = coalesce(lookup(v, "cloudwatch_logs_retention_in_days", null), local.merged_default_settings.cloudwatch_logs_retention_in_days)
      "provisioned_concurrent_executions" = coalesce(lookup(v, "provisioned_concurrent_executions", null), local.merged_default_settings.provisioned_concurrent_executions)
      "create_lambda_function_url"        = coalesce(lookup(v, "create_lambda_function_url", null), local.merged_default_settings.create_lambda_function_url)
      "cors"                              = coalesce(lookup(v, "cors", null), local.merged_default_settings.cors)
      "local_existing_package"            = try(coalesce(lookup(v, "local_existing_package", ""), local.merged_default_settings.local_existing_package), local.merged_default_settings.local_existing_package)
      "lambda_permissions"                = coalesce(lookup(v, "lambda_permissions", null), local.merged_default_settings.lambda_permissions)
      "eventbridge_rules"                 = coalesce(lookup(v, "eventbridge_rules", null), local.merged_default_settings.eventbridge_rules)
      "ignore_source_code_hash"           = coalesce(lookup(v, "ignore_source_code_hash", null), local.merged_default_settings.ignore_source_code_hash)
      "scaling_config"                    = coalesce(lookup(v, "scaling_config", null), local.merged_default_settings.scaling_config)
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
  local_existing_package            = each.value.local_existing_package == "" ? null : each.value.local_existing_package
  environment_variables = merge(
    each.value.environment_variables,
    {
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
  ignore_source_code_hash  = each.value.ignore_source_code_hash
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

resource "aws_cloudwatch_event_target" "cron" {
  for_each  = { for k, v in local.lambda_map : k => v if v.keep_warm == true }
  target_id = each.value.identifier
  rule      = aws_cloudwatch_event_rule.cron[each.key].name
  arn       = module.lambda[each.key].lambda_function_arn
}

resource "aws_lambda_permission" "cloudwatch" {
  for_each      = { for k, v in local.lambda_map : k => v if v.keep_warm == true }
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda[each.key].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron[each.key].arn
}

module "event_scheduler_role" {
  for_each          = { for k, v in local.lambda_map : k => v if v.create_event_scheduler_role }
  source            = "git::https://github.com/terraform-aws-modules/terraform-aws-iam//modules/iam-assumable-role?ref=v5.52.1"
  create_role       = true
  role_name         = "${each.value.identifier}-scheduler"
  role_requires_mfa = false
  trusted_role_actions = [
    "sts:AssumeRole"
  ]
  trusted_role_services = [
    "scheduler.amazonaws.com"
  ]
  inline_policy_statements = [
    {
      sid       = "LambdaInvoke"
      actions   = ["lambda:InvokeFunction"]
      effect    = "Allow"
      resources = ["arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${module.lambda[each.key].lambda_function_name}"]
    }
  ]
}

locals {
  lambda_permission_map = merge([
    for k, v in local.lambda_map : {
      for permission in keys(v.lambda_permissions) : "${k}|${permission}" => v.lambda_permissions[permission]
    } if length(v.lambda_permissions) > 0
  ]...)
  eventbridge_rule_map = merge([
    for k, v in local.lambda_map : {
      for rule in keys(v.eventbridge_rules) : "${k}|${rule}" => v.eventbridge_rules[rule]
    } if length(v.eventbridge_rules) > 0
  ]...)
}


resource "aws_lambda_permission" "lambda_permission" {
  for_each            = local.lambda_permission_map
  statement_id_prefix = "${local.lambda_map[split("|", each.key)[0]].identifier}-"
  action              = "lambda:InvokeFunction"
  function_name       = module.lambda[split("|", each.key)[0]].lambda_function_name
  principal           = each.value.principal
  source_arn          = each.value.source_arn
}

resource "aws_cloudwatch_event_rule" "event_rule" {
  for_each    = local.eventbridge_rule_map
  name        = each.value.name != null ? each.value.name : "${local.lambda_map[split("|", each.key)[0]].identifier}-${split("|", each.key)[1]}"
  description = each.value.description != null ? each.value.description : "Event rule for ${local.lambda_map[split("|", each.key)[0]].identifier}-${each.key}"
  event_pattern = jsonencode({
    "source" : each.value.source,
    "detail-type" : each.value.detail_type,
  })
}

resource "aws_cloudwatch_event_target" "lambda" {
  for_each  = local.eventbridge_rule_map
  target_id = "lambda"
  arn       = module.lambda[split("|", each.key)[0]].lambda_function_arn
  rule      = aws_cloudwatch_event_rule.event_rule[each.key].name
}

resource "aws_lambda_permission" "eventbridge_invoke" {
  for_each            = local.eventbridge_rule_map
  statement_id_prefix = "${local.lambda_map[split("|", each.key)[0]].identifier}-"
  action              = "lambda:InvokeFunction"
  function_name       = module.lambda[split("|", each.key)[0]].lambda_function_name
  principal           = "events.amazonaws.com"
  source_arn          = aws_cloudwatch_event_rule.event_rule[each.key].arn
}


locals {
  sqs_map = merge([
    for k, v in local.lambda_map : {
      for table_name in keys(v.sqs) : "${k}|${table_name}" => v.sqs[table_name]
    } if length(v.sqs) > 0
  ]...)
}

data "aws_sqs_queue" "queue" {
  for_each = local.sqs_map
  name     = each.value.queue_name
}

resource "aws_lambda_event_source_mapping" "sqs_map_events" {
  for_each         = local.sqs_map
  event_source_arn = data.aws_sqs_queue.queue[each.key].arn
  function_name    = module.lambda[split("|", each.key)[0]].lambda_function_name
  enabled          = coalesce(each.value.enabled, true)
  dynamic "scaling_config" {
    for_each = length(coalesce(each.value.scaling_config, [])) > 0 ? each.value.scaling_config : []
    content {
      maximum_concurrency = lookup(scaling_config.value, "maximum_concurrency", null)
    }
  }
  batch_size = coalesce(each.value.batch_size, 10)
  # filter_criteria {
  #   filter {
  #     pattern = jsonencode({
  #       body = {
  #         Temperature : [{ numeric : [">", 0, "<=", 100] }]
  #         Location : ["New York"]
  #       }
  #     })
  #   }
  # }
}

resource "aws_lambda_function_event_invoke_config" "sqs_stage_invoke_config" {
  for_each                     = { for k, v in local.lambda_map : k => v if v.create_async_event_config == true }
  function_name                = module.lambda[each.key].lambda_function_name
  maximum_event_age_in_seconds = each.value.maximum_event_age_in_seconds
  maximum_retry_attempts       = each.value.maximum_retry_attempts
}


resource "aws_cloudwatch_metric_alarm" "lambda_alarm" {
  for_each = { for k, v in local.lambda_map : k => v if v.create }
  alarm_name          = "${each.value.identifier}-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  dimensions = {
    FunctionName = module.lambda[each.key].lambda_function_name
  }
  alarm_description = "This metric monitors lambda errors for function: ${module.lambda[each.key].lambda_function_name}"
  # alarm_actions     = [var.alarm_topic_arn]
}