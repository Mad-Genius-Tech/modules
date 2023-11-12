
resource "aws_sns_topic" "topic" {
  count = var.create ? 1 : 0
  name  = "${module.context.id}-alarm"
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
    "us-east-1" =	"arn:aws:lambda:us-east-1:668099181075:layer:AWSLambda-Python-AWS-SDK:4"
    "us-west-2" = "arn:aws:lambda:us-west-2:420165488524:layer:AWSLambda-Python-AWS-SDK:5"
  }
}

module "discord" {
  #source                                 = "ganexcloud/lambda-notifications/aws"
  #version                                = "~> 1.0.7"
  source                                 = "git@github.com:debu99/terraform-aws-lambda-notifications.git"
  create                                 = var.create && var.discord_webhook_url != ""
  create_sns_topic                       = false
  lambda_function_name                   = "${module.context.id}-discord"
  sns_topic_name                         = aws_sns_topic.topic[0].name
  messenger                              = "discord"
  webhook_url                            = var.discord_webhook_url
  lambda_layers                          = [local.lambda_layer[data.aws_region.current.name]]
  cloudwatch_log_group_retention_in_days = 1
  tags                                   = local.tags
}

