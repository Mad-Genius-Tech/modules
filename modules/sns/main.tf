
resource "aws_sns_topic" "topic" {
  count = var.create ? 1 : 0
  name  = "${module.context.id}-alarm"
  tags  = local.tags
}

resource "aws_sns_topic_subscription" "subscription" {
  for_each  = { for k, v in var.sns_email_subscriptions : k => v if var.create && v != "" }
  topic_arn = aws_sns_topic.topic[0].arn
  protocol  = "email"
  endpoint  = each.value
}

data "aws_region" "current" {}

locals {
  lambda_layer = {
    "us-east-1"  = "arn:aws:lambda:us-east-1:668099181075:layer:AWSLambda-Python-AWS-SDK:4"
    "us-west-2"  = "arn:aws:lambda:us-west-2:420165488524:layer:AWSLambda-Python-AWS-SDK:5"
    "eu-north-1" = "arn:aws:lambda:eu-north-1:642425348156:layer:AWSLambda-Python-AWS-SDK:4"
  }
}

module "sns" {
  #source                                 = "ganexcloud/lambda-notifications/aws"
  #version                                = "~> 1.0.8"
  source                                 = "git::https://github.com/debu99/terraform-aws-lambda-notifications.git"
  create                                 = var.create && var.webhook_url != ""
  create_sns_topic                       = false
  lambda_function_name                   = "${module.context.id}-slack"
  sns_topic_name                         = aws_sns_topic.topic[0].name
  messenger                              = "slack"
  webhook_url                            = var.webhook_url
  lambda_layers                          = [local.lambda_layer[data.aws_region.current.name]]
  cloudwatch_log_group_retention_in_days = 1
  tags                                   = local.tags
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
      }
    ]
  })
}