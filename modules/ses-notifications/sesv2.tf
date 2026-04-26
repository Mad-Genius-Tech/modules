resource "aws_sesv2_account_suppression_attributes" "this" {
  suppressed_reasons = ["BOUNCE", "COMPLAINT"]
}

resource "aws_sesv2_configuration_set" "this" {
  configuration_set_name = module.context.id

  reputation_options {
    reputation_metrics_enabled = true
  }
}

resource "aws_sesv2_configuration_set_event_destination" "this" {
  for_each = local.ses_notifications_by_topic

  configuration_set_name = aws_sesv2_configuration_set.this.configuration_set_name
  event_destination_name = "${each.key}-sns"

  event_destination {
    enabled = true
    sns_destination {
      topic_arn = aws_sns_topic.this[each.key].arn
    }
    matching_event_types = [each.value.event_type]
  }
}
