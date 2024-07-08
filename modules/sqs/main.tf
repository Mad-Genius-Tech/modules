
locals {
  default_settings = {
    fifo_queue                    = false
    use_name_prefix               = false
    create_queue_policy           = false
    create_dlq                    = true
    create_dlq_queue_policy       = false
    dlq_message_retention_seconds = null
    redrive_policy                = {}
    visibility_timeout_seconds    = 30
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {

      }
    )
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  sqs_map = {
    for k, v in var.sqs : k => {
      "identifier"                    = "${module.context.id}-${k}"
      "create"                        = coalesce(lookup(v, "create", null), true)
      "fifo_queue"                    = try(coalesce(lookup(v, "fifo_queue", null), local.merged_default_settings.fifo_queue), local.merged_default_settings.fifo_queue)
      "create_queue_policy"           = try(coalesce(lookup(v, "create_queue_policy", null), local.merged_default_settings.create_queue_policy), local.merged_default_settings.create_queue_policy)
      "visibility_timeout_seconds"    = try(coalesce(lookup(v, "visibility_timeout_seconds", null), local.merged_default_settings.visibility_timeout_seconds), local.merged_default_settings.visibility_timeout_seconds)
      "create_dlq"                    = try(coalesce(lookup(v, "create_dlq", null), local.merged_default_settings.create_dlq), local.merged_default_settings.create_dlq)
      "create_dlq_queue_policy"       = try(coalesce(lookup(v, "create_dlq_queue_policy", null), local.merged_default_settings.create_dlq_queue_policy), local.merged_default_settings.create_dlq_queue_policy)
      "dlq_message_retention_seconds" = try(coalesce(lookup(v, "dlq_message_retention_seconds", null), local.merged_default_settings.dlq_message_retention_seconds), local.merged_default_settings.dlq_message_retention_seconds)
      "redrive_policy"                = try(coalesce(lookup(v, "redrive_policy", null), local.merged_default_settings.redrive_policy), local.merged_default_settings.redrive_policy)

    } if coalesce(lookup(v, "create", null), true)
  }
}

module "sqs" {
  source                        = "terraform-aws-modules/sqs/aws"
  version                       = "~> 4.1.1"
  for_each                      = local.sqs_map
  name                          = each.value.identifier
  fifo_queue                    = each.value.fifo_queue
  visibility_timeout_seconds    = each.value.visibility_timeout_seconds
  create_queue_policy           = each.value.create_queue_policy
  create_dlq                    = each.value.create_dlq
  create_dlq_queue_policy       = each.value.create_dlq_queue_policy
  dlq_message_retention_seconds = each.value.dlq_message_retention_seconds
  redrive_policy                = each.value.redrive_policy
  tags                          = local.tags
}

module "dlq_alarm" {
  source              = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version             = "~> 5.4.0"
  for_each            = local.sqs_map
  create_metric_alarm = var.sns_topic_arn != "" ? true : false
  alarm_name          = module.sqs[each.key].dead_letter_queue_name
  alarm_description   = "Items are on the ${module.sqs[each.key].dead_letter_queue_name} queue"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 300
  statistic           = "Average"
  treat_missing_data  = "notBreaching"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  dimensions = {
    "QueueName" : module.sqs[each.key].dead_letter_queue_name
  }
  alarm_actions = [var.sns_topic_arn]
  tags          = local.tags
}