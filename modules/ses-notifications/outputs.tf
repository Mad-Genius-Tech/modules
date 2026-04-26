output "configuration_set_name" {
  description = "Pass this to SendEmail / SendRawEmail (ConfigurationSetName) so bounces, complaints, and delivery events use this module's SNS topics."
  value       = aws_sesv2_configuration_set.this.configuration_set_name
}

output "configuration_set_arn" {
  value = aws_sesv2_configuration_set.this.arn
}

output "bounce_sns_topic_arn" {
  value = aws_sns_topic.this["bounce"].arn
}

output "complaint_sns_topic_arn" {
  value = aws_sns_topic.this["complaint"].arn
}

output "delivery_sns_topic_arn" {
  value = aws_sns_topic.this["delivery"].arn
}

output "bounce_subscription_id" {
  value = try(aws_sns_topic_subscription.this["bounce"].id, null)
}

output "complaint_subscription_id" {
  value = try(aws_sns_topic_subscription.this["complaint"].id, null)
}

output "delivery_subscription_id" {
  value = try(aws_sns_topic_subscription.this["delivery"].id, null)
}

output "reputation_bounce_rate_warn_alarm_arn" {
  value = try(aws_cloudwatch_metric_alarm.reputation_bounce_rate_warn[0].arn, null)
}

output "reputation_bounce_rate_page_alarm_arn" {
  value = try(aws_cloudwatch_metric_alarm.reputation_bounce_rate_page[0].arn, null)
}

output "reputation_complaint_rate_warn_alarm_arn" {
  value = try(aws_cloudwatch_metric_alarm.reputation_complaint_rate_warn[0].arn, null)
}

output "reputation_complaint_rate_page_alarm_arn" {
  value = try(aws_cloudwatch_metric_alarm.reputation_complaint_rate_page[0].arn, null)
}

output "account_suppression_suppressed_reasons" {
  description = "Effective list of suppression reasons configured at account-level."
  value       = aws_sesv2_account_suppression_attributes.this.suppressed_reasons
}
