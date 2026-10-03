mock_provider "aws" {
  mock_resource "aws_sns_topic" {
    defaults = { arn = "arn:aws:sns:us-west-2:123456789012:mgb-test-sns-alarm" }
  }
  mock_resource "aws_cloudwatch_log_group" {
    defaults = { arn = "arn:aws:logs:us-west-2:123456789012:log-group:/aws/lambda/mgb-test-sns-slack:*" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
}

override_module {
  target = module.sns.module.lambda
  outputs = {
    lambda_function_arn = "arn:aws:lambda:us-west-2:123456789012:function:mgb-test-sns-slack"
  }
}

variables {
  org_name                = "mgb"
  stage_name              = "test"
  service_name            = "sns"
  team_name               = "platform"
  webhook_url             = "https://hooks.slack.com/services/TTEST/BTEST/repair-test"
  sns_email_subscriptions = ["monitoring@example.invalid"]
}

run "forwarder_failures_have_an_independent_notification_route" {
  command = apply

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.slack_delivery_errors[0].namespace == "AWS/Lambda" &&
      aws_cloudwatch_metric_alarm.slack_delivery_errors[0].metric_name == "Errors" &&
      aws_cloudwatch_metric_alarm.slack_delivery_errors[0].dimensions.FunctionName == "mgb-test-sns-slack" &&
      aws_cloudwatch_metric_alarm.slack_delivery_errors[0].period == 60 &&
      aws_cloudwatch_metric_alarm.slack_delivery_errors[0].threshold == 1 &&
      aws_cloudwatch_metric_alarm.slack_delivery_errors[0].treat_missing_data == "notBreaching" &&
      toset(aws_cloudwatch_metric_alarm.slack_delivery_errors[0].alarm_actions) == toset([aws_sns_topic.topic[0].arn]) &&
      length(aws_cloudwatch_metric_alarm.slack_delivery_errors[0].ok_actions) == 0 &&
      aws_sns_topic_subscription.subscription["monitoring@example.invalid"].protocol == "email"
    )
    error_message = "Forwarder errors must notify the same SNS topic with an independent email route and no recovery-notification loop."
  }
}

run "email_only_topic_does_not_monitor_a_disabled_forwarder" {
  command = plan
  variables { webhook_url = "" }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.slack_delivery_errors) == 0
    error_message = "An email-only topic must not create a Slack forwarder error alarm."
  }
}

run "adapter_preserves_existing_resource_names_and_retains_diagnostics" {
  command = plan

  module { source = "./slack" }

  variables {
    create               = true
    lambda_function_name = "mgb-test-sns-slack"
    sns_topic_arn        = "arn:aws:sns:us-west-2:123456789012:mgb-test-sns-alarm"
    tags                 = {}
  }

  assert {
    condition = (
      aws_cloudwatch_log_group.lambda[0].name == "/aws/lambda/mgb-test-sns-slack" &&
      aws_cloudwatch_log_group.lambda[0].retention_in_days == 30 &&
      aws_sns_topic_subscription.sns_notify_slack[0].topic_arn == var.sns_topic_arn &&
      aws_sns_topic_subscription.sns_notify_slack[0].protocol == "lambda" &&
      module.lambda.lambda_function_name == "mgb-test-sns-slack" &&
      module.lambda.lambda_role_name == "lambda-mgb-test-sns-slack"
    )
    error_message = "The replacement adapter must retain existing Lambda, role, log group and subscription identities while retaining diagnostics for 30 days."
  }
}

run "cost_anomalies_can_publish_for_the_owning_account" {
  command = apply
  variables { webhook_url = "" }

  assert {
    condition = length([
      for statement in jsondecode(aws_sns_topic_policy.aws_budget.policy).Statement : statement
      if try(
        statement.Effect == "Allow" &&
        statement.Principal.Service == "costalerts.amazonaws.com" &&
        statement.Action == "SNS:Publish" &&
        statement.Resource == aws_sns_topic.topic[0].arn &&
        statement.Condition.StringEquals["aws:SourceAccount"] == "123456789012",
        false
      )
    ]) == 1
    error_message = "Cost Anomaly Detection must be allowed to publish to the topic only on behalf of the owning account."
  }

  assert {
    condition = toset([
      for statement in jsondecode(aws_sns_topic_policy.aws_budget.policy).Statement : statement.Principal.Service
    ]) == toset(["budgets.amazonaws.com", "cloudwatch.amazonaws.com", "costalerts.amazonaws.com"])
    error_message = "The cost-anomaly grant must retain the existing Budgets and CloudWatch publishers."
  }
}
