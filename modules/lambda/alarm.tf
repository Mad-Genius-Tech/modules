resource "aws_cloudwatch_metric_alarm" "duration" {
  for_each            = { for k, v in local.lambda_map : k => v if v.create && var.sns_topic_arn != "" && v.enable_monitoring }
  alarm_name          = "${each.value.identifier}-duration"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.duration_evaluation_periods
  namespace           = "AWS/Lambda"
  metric_name         = "Duration"
  statistic           = "Maximum"
  period              = 60
  threshold           = each.value.duration_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions = compact([
    var.sns_topic_arn
  ])
  ok_actions = compact([
    var.sns_topic_arn
  ])
  dimensions = {
    FunctionName = each.value.identifier
    Resource     = "${each.value.identifier}:${var.stage_name}"
  }
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "errors" {
  for_each            = { for k, v in local.lambda_map : k => v if v.create && var.sns_topic_arn != "" && v.enable_monitoring }
  alarm_name          = "${each.value.identifier}-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.errors_evaluation_periods
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 60
  threshold           = each.value.errors_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions = compact([
    var.sns_topic_arn
  ])
  ok_actions = compact([
    var.sns_topic_arn
  ])
  dimensions = {
    FunctionName = each.value.identifier
    Resource     = "${each.value.identifier}:${var.stage_name}"
  }
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "concurrent_executions" {
  for_each            = { for k, v in local.lambda_map : k => v if v.create && var.sns_topic_arn != "" && v.enable_monitoring }
  alarm_name          = "${each.value.identifier}-concurrent-executions"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.concurrent_executions_evaluation_periods
  metric_name         = "ConcurrentExecutions"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Maximum"
  threshold           = each.value.concurrent_executions_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions = compact([
    var.sns_topic_arn
  ])
  ok_actions = compact([
    var.sns_topic_arn
  ])

  dimensions = {
    FunctionName = each.value.identifier
    Resource     = "${each.value.identifier}:${var.stage_name}"
  }
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "throttles" {
  for_each            = { for k, v in local.lambda_map : k => v if v.create && var.sns_topic_arn != "" && v.enable_monitoring }
  alarm_name          = "${each.value.identifier}-throttles"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.throttles_evaluation_periods
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = each.value.throttles_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions = compact([
    var.sns_topic_arn
  ])
  ok_actions = compact([
    var.sns_topic_arn
  ])

  dimensions = {
    FunctionName = each.value.identifier
    Resource     = "${each.value.identifier}:${var.stage_name}"
  }
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "error_rate" {
  for_each            = { for k, v in local.lambda_map : k => v if v.create && var.sns_topic_arn != "" && v.enable_monitoring }
  alarm_name          = "${each.value.identifier}-error-rate"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.error_rate_evaluation_periods
  threshold           = each.value.error_rate_threshold

  metric_query {
    id          = "e1"
    return_data = true
    expression  = "m2/m1*100"
    label       = "Error Rate"
  }
  metric_query {
    id = "m1"
    metric {
      namespace   = "AWS/Lambda"
      metric_name = "Invocations"
      period      = 60
      stat        = "Sum"
      unit        = "Count"
      dimensions = {
        FunctionName = each.value.identifier
        Resource     = "${each.value.identifier}:${var.stage_name}"
      }
    }
  }
  metric_query {
    id = "m2"
    metric {
      namespace   = "AWS/Lambda"
      metric_name = "Errors"
      period      = 60
      stat        = "Sum"
      unit        = "Count"
      dimensions = {
        FunctionName = each.value.identifier
        Resource     = "${each.value.identifier}:${var.stage_name}"
      }
    }
  }
  treat_missing_data = "notBreaching"
  alarm_actions = compact([
    var.sns_topic_arn
  ])
  ok_actions = compact([
    var.sns_topic_arn
  ])
  tags = local.tags
}
