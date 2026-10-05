mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/test-alert-publisher" }
  }
  mock_resource "aws_cloudwatch_log_group" {
    defaults = { arn = "arn:aws:logs:us-west-2:123456789012:log-group:/ecs/events/mgb-test-fabric" }
  }
  mock_data "aws_region" { defaults = { name = "us-west-2" } }
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test"
      user_id    = "AIDATEST"
    }
  }
  mock_data "aws_iam_policy_document" { defaults = { json = "{}" } }
}

override_module {
  target = module.ecs_cluster
  outputs = {
    name = "mgb-test-fabric"
    arn  = "arn:aws:ecs:us-west-2:123456789012:cluster/mgb-test-fabric"
    id   = "mgb-test-fabric"
  }
}

variables {
  org_name                       = "mgb"
  stage_name                     = "test"
  service_name                   = "fabric"
  team_name                      = "platform"
  tags                           = {}
  private_subnets                = ["subnet-private"]
  public_subnets                 = ["subnet-public"]
  ingress_cidr_blocks            = ["10.0.0.0/16"]
  vpc_id                         = "vpc-test"
  vpc_cidr                       = "10.0.0.0/16"
  create_internal_alb            = false
  sns_topic_cloudwatch_alarm_arn = "arn:aws:sns:us-west-2:123456789012:alarms"
  ecs_services                   = {}
}

run "event_delivery_is_scoped_to_one_log_group" {
  command = apply

  assert {
    condition = jsondecode(aws_cloudwatch_log_resource_policy.ecs_events.policy_document) == jsondecode(jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Sid       = "EventBridgeECSLogs"
        Effect    = "Allow"
        Principal = { Service = ["events.amazonaws.com", "delivery.logs.amazonaws.com"] }
        Action    = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource  = "arn:aws:logs:us-west-2:123456789012:log-group:/ecs/events/mgb-test-fabric:*"
      }]
    }))
    error_message = "Grant only the two AWS delivery services and two log-write actions to this exact log group's streams."
  }

  assert {
    condition = (
      aws_cloudwatch_log_resource_policy.ecs_events.policy_name == "mgb-test-fabric-events-to-logs" &&
      aws_cloudwatch_event_target.ecs_events.role_arn == null &&
      aws_cloudwatch_event_target.ecs_events.arn == aws_cloudwatch_log_group.ecs_events.arn &&
      aws_cloudwatch_event_target.ecs_events.rule == aws_cloudwatch_event_rule.ecs_events.name &&
      aws_cloudwatch_log_group.ecs_events.retention_in_days == 3
    )
    error_message = "Preserve the existing role-free event target, log identity and retention."
  }
}

run "event_logging_is_independent_of_sns" {
  command = apply
  variables { sns_topic_cloudwatch_alarm_arn = "" }

  assert {
    condition = (
      length(aws_iam_role.ecs_alert_publisher) == 0 &&
      jsondecode(aws_cloudwatch_log_resource_policy.ecs_events.policy_document).Statement[0].Resource ==
      "arn:aws:logs:us-west-2:123456789012:log-group:/ecs/events/mgb-test-fabric:*" &&
      aws_cloudwatch_event_target.ecs_events.role_arn == null
    )
    error_message = "Event logging must work even when SNS notifications are disabled."
  }
}
