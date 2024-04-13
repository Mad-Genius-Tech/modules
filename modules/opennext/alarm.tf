locals {
  lambda_alarms = {
    "duration" = {
      "image-optimization" = {
        "enabled"            = true
        "evaluation_periods" = 1
        "threshold"          = 10000
      }
      "server" = {
        "enabled"            = true
        "evaluation_periods" = 1
        "threshold"          = 30000
      }
    }
    "throttles" = {
      "image-optimization" = {
        "enabled"            = true
        "evaluation_periods" = 1
        "threshold"          = 1
      }
      "server" = {
        "enabled"            = true
        "evaluation_periods" = 1
        "threshold"          = 1
      }
    }
    "errors" = {
      "image-optimization" = {
        "enabled"            = true
        "evaluation_periods" = 1
        "threshold"          = 1
      }
      # "server" = {
      #   "enabled"            = true
      #   "evaluation_periods" = 1
      #   "threshold"          = 1
      # }
    }
    "error_rate" = {
      # "server" = {
      #   "enabled"            = true
      #   "evaluation_periods" = 1
      #   "threshold"          = 85
      # }
    }
    "concurrent_executions" = {
      "server" = {
        "enabled"            = true
        "evaluation_periods" = 1
        "threshold"          = 100
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "duration" {
  for_each            = { for k, v in local.lambda_alarms.duration : k => v if v.enabled && var.sns_topic_arn != "" }
  alarm_name          = "${local.name}-${each.key}-duration"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  namespace           = "AWS/Lambda"
  metric_name         = "Duration"
  statistic           = "Maximum"
  period              = 60
  threshold           = each.value.threshold
  treat_missing_data  = "notBreaching"
  alarm_actions = compact([
    var.sns_topic_arn
  ])
  ok_actions = compact([
    var.sns_topic_arn
  ])

  dimensions = {
    FunctionName = "${local.name}-${each.key}"
  }
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "errors" {
  for_each            = { for k, v in local.lambda_alarms.errors : k => v if v.enabled && var.sns_topic_arn != "" }
  alarm_name          = "${local.name}-${each.key}-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 60
  threshold           = each.value.threshold
  treat_missing_data  = "notBreaching"
  alarm_actions = compact([
    var.sns_topic_arn
  ])
  ok_actions = compact([
    var.sns_topic_arn
  ])

  dimensions = {
    FunctionName = "${local.name}-${each.key}"
  }
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "error_rate" {
  for_each            = { for k, v in local.lambda_alarms.error_rate : k => v if v.enabled && var.sns_topic_arn != "" }
  alarm_name          = "${local.name}-${each.key}-error-rate"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  threshold           = each.value.threshold

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
        FunctionName = "${local.name}-${each.key}"
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
        FunctionName = "${local.name}-${each.key}"
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

resource "aws_cloudwatch_metric_alarm" "concurrent_executions" {
  for_each            = { for k, v in local.lambda_alarms.concurrent_executions : k => v if v.enabled && var.sns_topic_arn != "" }
  alarm_name          = "${local.name}-${each.key}-concurrent-executions"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "ConcurrentExecutions"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Maximum"
  threshold           = each.value.threshold
  treat_missing_data  = "notBreaching"
  alarm_actions = compact([
    var.sns_topic_arn
  ])
  ok_actions = compact([
    var.sns_topic_arn
  ])

  dimensions = {
    FunctionName = "${local.name}-${each.key}"
  }
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "throttles" {
  for_each            = { for k, v in local.lambda_alarms.throttles : k => v if v.enabled && var.sns_topic_arn != "" }
  alarm_name          = "${local.name}-${each.key}-throttles"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = each.value.threshold
  treat_missing_data  = "notBreaching"
  alarm_actions = compact([
    var.sns_topic_arn
  ])
  ok_actions = compact([
    var.sns_topic_arn
  ])

  dimensions = {
    FunctionName = "${local.name}-${each.key}"
  }
  tags = local.tags
}