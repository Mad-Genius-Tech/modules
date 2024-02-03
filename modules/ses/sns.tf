
resource "aws_ses_identity_notification_topic" "bounce" {
  count                    = var.ses_domain_name != "" ? 1 : 0
  identity                 = aws_ses_domain_identity.ses_domain_identity[0].domain
  notification_type        = "Bounce"
  include_original_headers = true
  topic_arn                = aws_sns_topic.sns_topic.arn
}

resource "aws_ses_identity_notification_topic" "complaint" {
  count                    = var.ses_domain_name != "" ? 1 : 0
  identity                 = aws_ses_domain_identity.ses_domain_identity[0].domain
  notification_type        = "Complaint"
  include_original_headers = true
  topic_arn                = aws_sns_topic.sns_topic.arn
}

resource "aws_sns_topic" "sns_topic" {
  name = "${module.context.id}-topic"
  tags = local.tags
}

