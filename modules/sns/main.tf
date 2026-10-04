
locals {
  sns_email_subscriptions = {
    for endpoint in var.sns_email_subscriptions :
    lower(trimspace(endpoint)) => trimspace(endpoint)
    if var.create && trimspace(endpoint) != ""
  }
}

resource "aws_sns_topic" "topic" {
  count = var.create ? 1 : 0
  name  = "${module.context.id}-alarm"
  tags  = local.tags
}

resource "aws_sns_topic_subscription" "subscription" {
  for_each            = local.sns_email_subscriptions
  topic_arn           = aws_sns_topic.topic[0].arn
  protocol            = "email"
  endpoint            = each.value
  filter_policy       = var.sns_email_message_body_filter_policy
  filter_policy_scope = var.sns_email_message_body_filter_policy != null ? "MessageBody" : null
}

module "sns" {
  source               = "./slack"
  create               = var.create && var.webhook_url != ""
  lambda_function_name = "${module.context.id}-slack"
  sns_topic_arn        = try(aws_sns_topic.topic[0].arn, "")
  webhook_url          = var.webhook_url
  tags                 = local.tags
}

resource "aws_cloudwatch_metric_alarm" "slack_delivery_errors" {
  count               = var.create && var.webhook_url != "" ? 1 : 0
  alarm_name          = "${module.context.id}-slack-errors"
  alarm_description   = "Slack notification delivery failed. Inspect the forwarder logs; the SNS email subscription provides an independent notification path."
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { FunctionName = "${module.context.id}-slack" }
  alarm_actions       = [aws_sns_topic.topic[0].arn]
  ok_actions          = []
  # Do not send OK actions to the failing forwarder: its own error alert can
  # fail delivery and otherwise generate an ALARM/OK notification loop.
  tags = local.tags
}

data "aws_caller_identity" "current" {}

resource "aws_sns_topic_policy" "aws_budget" {
  arn = module.sns.sns_topic_arn
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "AWSBudgetPermission"
    Statement = [
      {
        Sid    = "AWSBudgetsSNSPublishingPermissions"
        Effect = "Allow"
        Principal = {
          Service = "budgets.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = module.sns.sns_topic_arn
      },
      {
        Sid    = "CloudwatchSNSPublishingPermissions"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = module.sns.sns_topic_arn
      },
      {
        Sid    = "AWSAnomalyDetectionSNSPublishingPermissions"
        Effect = "Allow"
        Principal = {
          Service = "costalerts.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = module.sns.sns_topic_arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
    ]
  })
}
