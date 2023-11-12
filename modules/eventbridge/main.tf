
locals {
  default_settings = {
    create_bus          = false
    input               = {}
    schedule_expression = ""

  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  events_map = {
    for k, v in var.events : k => {
      "identifier"          = "${module.context.id}-${k}"
      "create_bus"          = try(coalesce(lookup(v, "create_bus", null), local.merged_default_settings.create_bus), local.merged_default_settings.create_bus)
      "lambda_function"     = v.lambda_function
      "lambda_input"        = try(coalesce(lookup(v, "input", null), local.merged_default_settings.input), local.merged_default_settings.input)
      "schedule_expression" = try(coalesce(lookup(v, "schedule_expression", null), local.merged_default_settings.schedule_expression), local.merged_default_settings.schedule_expression)
    } if coalesce(lookup(v, "create", null), true)
  }

  events = {
    "no1" = {
      lambda_function     = "my-function-1"
      schedule_expression = "rate(5 minutes)"
    }
  }
}


data "aws_lambda_function" "function" {
  for_each      = local.events_map
  function_name = each.value.lambda_function
}

module "eventbridge" {
  source     = "terraform-aws-modules/eventbridge/aws"
  version    = "~> 2.3.0"
  for_each   = local.events_map
  create_bus = each.value.create_bus

  rules = {
    crons = {
      description         = "Trigger for a Lambda"
      schedule_expression = "rate(5 minutes)"
    }
  }

  targets = {
    crons = [
      {
        name  = "${each.value.identifier}-cron"
        arn   = "${data.aws_lambda_function.function[each.key].arn}:${stage_name}"
        input = jsonencode(each.value.lambda_input)
      }
    ]
  }

  tags = local.tags
}