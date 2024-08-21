

locals {
  default_settings = {
    schedule_expression      = "rate(3 minutes)"
    take_screenshot          = true
    runtime_version          = "syn-python-selenium-3.0"
    handler                  = "canary.handler"
    timeout_in_seconds       = 15
    memory_in_mb             = 960
    success_retention_period = 2
    failure_retention_period = 14
    enable_notification      = true
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        schedule_expression = "rate(1 minute)"
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  canary_map = {
    for k, v in var.canary : k => {
      "identifier"               = "${module.context.id}-${k}"
      "create"                   = coalesce(lookup(v, "create", null), true)
      enable_notification        = coalesce(lookup(v, "enable_notification", null), local.merged_default_settings.enable_notification)
      "runtime_version"          = try(coalesce(lookup(v, "runtime_version", null), local.merged_default_settings.runtime_version), local.merged_default_settings.runtime_version)
      "handler"                  = try(coalesce(lookup(v, "handler", null), local.merged_default_settings.handler), local.merged_default_settings.handler)
      "url"                      = v.url
      "take_screenshot"          = try(coalesce(lookup(v, "take_screenshot", null), local.merged_default_settings.take_screenshot), local.merged_default_settings.take_screenshot)
      "schedule_expression"      = try(coalesce(lookup(v, "schedule_expression", null), local.merged_default_settings.schedule_expression), local.merged_default_settings.schedule_expression)
      "timeout_in_seconds"       = try(coalesce(lookup(v, "timeout_in_seconds", null), local.merged_default_settings.timeout_in_seconds), local.merged_default_settings.timeout_in_seconds)
      "memory_in_mb"             = try(coalesce(lookup(v, "memory_in_mb", null), local.merged_default_settings.memory_in_mb), local.merged_default_settings.memory_in_mb)
      "success_retention_period" = try(coalesce(lookup(v, "success_retention_period", null), local.merged_default_settings.success_retention_period), local.merged_default_settings.success_retention_period)
      "failure_retention_period" = try(coalesce(lookup(v, "failure_retention_period", null), local.merged_default_settings.failure_retention_period), local.merged_default_settings.failure_retention_period)
    } if coalesce(lookup(v, "create", null), true)
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "local_file" "canary_file" {
  filename = "${path.module}/scripts/canary.py"
}

data "archive_file" "canary_zip" {
  source {
    content  = data.local_file.canary_file.content
    filename = "python/canary.py"
  }
  type        = "zip"
  output_path = "canary-${data.local_file.canary_file.content_sha256}.zip"
}

resource "aws_synthetics_canary" "canary" {
  for_each                 = local.canary_map
  name                     = each.key
  artifact_s3_location     = "s3://${module.s3_bucket.s3_bucket_id}/canary/${each.key}"
  execution_role_arn       = aws_iam_role.iam_role.arn
  runtime_version          = each.value.runtime_version
  handler                  = each.value.handler
  zip_file                 = "canary-${data.local_file.canary_file.content_sha256}.zip"
  start_canary             = true
  success_retention_period = each.value.success_retention_period
  failure_retention_period = each.value.failure_retention_period
  schedule {
    expression          = each.value.schedule_expression
    duration_in_seconds = 0
  }
  run_config {
    timeout_in_seconds = each.value.timeout_in_seconds
    memory_in_mb       = each.value.memory_in_mb
    active_tracing     = false
    environment_variables = {
      "URL"             = each.value.url
      "TAKE_SCREENSHOT" = each.value.take_screenshot ? "true" : "false"
      "TIMEOUT"         = each.value.timeout_in_seconds
    }
  }
  depends_on = [
    data.archive_file.canary_zip,
  ]
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "canary_alarm" {
  for_each            = { for k,v in local.canary_map : k => v if v.enable_notification }
  alarm_name          = "${each.value.identifier}-alarm"
  comparison_operator = "LessThanThreshold"
  period              = "300"
  datapoints_to_alarm = "2"
  evaluation_periods  = "2"
  metric_name         = "SuccessPercent"
  namespace           = "CloudWatchSynthetics"
  statistic           = "Average"
  threshold           = "90"
  treat_missing_data  = "missing" # breaching/missing
  alarm_actions       = var.sns_topic_cloudwatch_alarm_arn == "" ? [] : [var.sns_topic_cloudwatch_alarm_arn]
  ok_actions          = var.sns_topic_cloudwatch_alarm_arn == "" ? [] : [var.sns_topic_cloudwatch_alarm_arn]
  alarm_description   = "${each.value.url} - SuccessPercent LessThanThreshold 90"
  dimensions = {
    CanaryName = aws_synthetics_canary.canary[each.key].name
  }
}

# resource "aws_cloudwatch_event_rule" "saints-xctf-sign-in-canary-event-rule" {
#   name = "saints-xctf-sign-in-canary-rule"
#   event_pattern = jsonencode({
#     source = ["aws.synthetics"]
#     detail = {
#       "canary-name": [aws_synthetics_canary.saints-xctf-sign-in.name],
#       "test-run-status": ["FAILED"]
#     }
#   })
# }

# resource "aws_cloudwatch_event_target" "saints-xctf-sign-in-canary-event-target" {
#   target_id = "SaintsXCTFSignInCanaryTarget"
#   arn = data.aws_sns_topic.alert-email.arn
#   rule = aws_cloudwatch_event_rule.saints-xctf-sign-in-canary-event-rule.name
# }