data "aws_caller_identity" "current" {}

locals {
  ses_notifications_by_topic = {
    bounce = {
      event_type = "BOUNCE"
      endpoint   = var.bounce_https_endpoint
    }
    complaint = {
      event_type = "COMPLAINT"
      endpoint   = var.complaint_https_endpoint
    }
    delivery = {
      event_type = "DELIVERY"
      endpoint   = var.delivery_https_endpoint
    }
  }
}

resource "aws_sns_topic" "this" {
  for_each = local.ses_notifications_by_topic

  name = "${module.context.id}-ses-${each.key}"
  tags = local.tags
}

data "aws_iam_policy_document" "ses_sns" {
  for_each = aws_sns_topic.this

  statement {
    sid    = "AllowSESToPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    actions = [
      "sns:Publish",
    ]

    resources = [each.value.arn]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "this" {
  for_each = aws_sns_topic.this

  arn    = each.value.arn
  policy = data.aws_iam_policy_document.ses_sns[each.key].json
}

# HTTPS subscriptions (only when an endpoint is set)

resource "aws_sns_topic_subscription" "this" {
  for_each = {
    for topic, config in local.ses_notifications_by_topic :
    topic => config.endpoint
    if try(trimspace(config.endpoint), "") != ""
  }

  topic_arn              = aws_sns_topic.this[each.key].arn
  protocol               = "https"
  endpoint               = each.value
  endpoint_auto_confirms = false
}
