# Account-level reputation metrics (AWS/SES) — not scoped to a single configuration set.

resource "aws_cloudwatch_metric_alarm" "reputation_bounce_rate_warn" {
  count = var.reputation_alarms_enabled ? 1 : 0

  alarm_name          = "${module.context.id}-ses-reputation-bounce-warn"
  alarm_description   = "SES account Reputation.BounceRate warn (>= ${var.reputation_bounce_rate_warn_threshold})"
  namespace           = "AWS/SES"
  metric_name         = "Reputation.BounceRate"
  statistic           = "Average"
  period              = var.reputation_metrics_alarm_period_seconds
  evaluation_periods  = var.reputation_metrics_alarm_evaluation_periods
  threshold           = var.reputation_bounce_rate_warn_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = compact([coalesce(var.reputation_alarm_sns_topic_arn, "")])
  ok_actions          = compact([coalesce(var.reputation_alarm_sns_topic_arn, "")])
}

resource "aws_cloudwatch_metric_alarm" "reputation_bounce_rate_page" {
  count = var.reputation_alarms_enabled ? 1 : 0

  alarm_name          = "${module.context.id}-ses-reputation-bounce-page"
  alarm_description   = "SES account Reputation.BounceRate page (>= ${var.reputation_bounce_rate_page_threshold})"
  namespace           = "AWS/SES"
  metric_name         = "Reputation.BounceRate"
  statistic           = "Average"
  period              = var.reputation_metrics_alarm_period_seconds
  evaluation_periods  = var.reputation_metrics_alarm_evaluation_periods
  threshold           = var.reputation_bounce_rate_page_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = compact([coalesce(var.reputation_alarm_sns_topic_arn, "")])
  ok_actions          = compact([coalesce(var.reputation_alarm_sns_topic_arn, "")])
}

resource "aws_cloudwatch_metric_alarm" "reputation_complaint_rate_warn" {
  count = var.reputation_alarms_enabled ? 1 : 0

  alarm_name          = "${module.context.id}-ses-reputation-complaint-warn"
  alarm_description   = "SES account Reputation.ComplaintRate warn (>= ${var.reputation_complaint_rate_warn_threshold})"
  namespace           = "AWS/SES"
  metric_name         = "Reputation.ComplaintRate"
  statistic           = "Average"
  period              = var.reputation_metrics_alarm_period_seconds
  evaluation_periods  = var.reputation_metrics_alarm_evaluation_periods
  threshold           = var.reputation_complaint_rate_warn_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = compact([coalesce(var.reputation_alarm_sns_topic_arn, "")])
  ok_actions          = compact([coalesce(var.reputation_alarm_sns_topic_arn, "")])
}

resource "aws_cloudwatch_metric_alarm" "reputation_complaint_rate_page" {
  count = var.reputation_alarms_enabled ? 1 : 0

  alarm_name          = "${module.context.id}-ses-reputation-complaint-page"
  alarm_description   = "SES account Reputation.ComplaintRate page (>= ${var.reputation_complaint_rate_page_threshold})"
  namespace           = "AWS/SES"
  metric_name         = "Reputation.ComplaintRate"
  statistic           = "Average"
  period              = var.reputation_metrics_alarm_period_seconds
  evaluation_periods  = var.reputation_metrics_alarm_evaluation_periods
  threshold           = var.reputation_complaint_rate_page_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = compact([coalesce(var.reputation_alarm_sns_topic_arn, "")])
  ok_actions          = compact([coalesce(var.reputation_alarm_sns_topic_arn, "")])
}
