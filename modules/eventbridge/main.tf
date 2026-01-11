
locals {
  default_settings = {
    create_bus          = false
    bus_name            = "default"
    input               = {}
    schedule_expression = ""
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  # events_map = {
  #   for k, v in var.events : k => {
  #     "identifier"          = "${module.context.id}-${k}"
  #     "create_bus"          = try(coalesce(lookup(v, "create_bus", null), local.merged_default_settings.create_bus), local.merged_default_settings.create_bus)
  #     "lambda_function"     = v.lambda_function
  #     "lambda_input"        = try(coalesce(lookup(v, "input", null), local.merged_default_settings.input), local.merged_default_settings.input)
  #     "schedule_expression" = try(coalesce(lookup(v, "schedule_expression", null), local.merged_default_settings.schedule_expression), local.merged_default_settings.schedule_expression)
  #   } if coalesce(lookup(v, "create", null), true)
  # }

  # events = {
  #   "no1" = {
  #     lambda_function     = "my-function-1"
  #     schedule_expression = "rate(5 minutes)"
  #   }
  # }

  eventbus_map = {
    for k, v in var.eventbus : k => {
      "identifier" = "${module.context.id}-${k}"
      "bus_name"   = try(coalesce(lookup(v, "bus_name", null), local.merged_default_settings.bus_name), local.merged_default_settings.bus_name)
    } if coalesce(lookup(v, "create", null), true)
  }
}


# data "aws_lambda_function" "function" {
#   for_each      = local.events_map
#   function_name = each.value.lambda_function
# }

module "eventbus" {
  source     = "terraform-aws-modules/eventbridge/aws"
  version    = "~> 3.13.0"
  for_each   = local.eventbus_map
  create_bus = true
  bus_name   = each.value.bus_name

  # rules = {
  #   crons = {
  #     description         = "Trigger for a Lambda"
  #     schedule_expression = "rate(5 minutes)"
  #   }
  # }

  # targets = {
  #   crons = [
  #     {
  #       name  = "${each.value.identifier}-cron"
  #       arn   = "${data.aws_lambda_function.function[each.key].arn}:${stage_name}"
  #       input = jsonencode(each.value.lambda_input)
  #     }
  #   ]
  # }

  tags = local.tags
}


# module "eventbridge" {
#   source  = "terraform-aws-modules/eventbridge/aws"
#   version = ">=2.3.0, <3.0.0"

#   create     = local.producer.to_create
#   create_bus = false

#   rules = {
#     crons = {
#       description         = "Kafka producer lambda schedule"
#       schedule_expression = local.producer.schedule_rate
#     }
#   }

#   targets = {
#     crons = [for i in range(local.producer.concurrency) : {
#       name = "lambda-target-${i}"
#       arn  = module.kafka_producer.lambda_function_arn
#     }]
#   }

#   depends_on = [
#     module.kafka_producer
#   ]

#   tags = local.tags
# }
