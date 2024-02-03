resource "aws_cloudwatch_metric_alarm" "bounce_rate" {
  alarm_name          = "${module.context.id}-bounce-rate"
  alarm_description   = "This metric monitors SES reputation bounce rate"
  namespace           = "AWS/SES"
  metric_name         = "Reputation.BounceRate"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = 3600
  threshold           = "0.025"
  statistic           = "Average"
  alarm_actions       = compact([var.alarm_sns_topic_arn])
  ok_actions          = compact([var.alarm_sns_topic_arn])
}

resource "aws_cloudwatch_metric_alarm" "complaint_rate" {
  alarm_name          = "${module.context.id}-complaint-rate"
  alarm_description   = "This metric monitors SES reputation complaint rate"
  namespace           = "AWS/SES"
  metric_name         = "Reputation.ComplaintRate"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = "0.0005"
  period              = 3600
  statistic           = "Average"
  alarm_actions       = compact([var.alarm_sns_topic_arn])
  ok_actions          = compact([var.alarm_sns_topic_arn])
}