mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/test-alert-publisher" }
  }
  mock_resource "aws_cloudwatch_log_group" {
    defaults = { arn = "arn:aws:logs:us-west-2:123456789012:log-group:/ecs/events/test" }
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

override_resource {
  target = aws_cloudwatch_event_rule.ecs_deployment_failure
  values = { arn = "arn:aws:events:us-west-2:123456789012:rule/test-deployment-failure" }
}

override_resource {
  target = aws_cloudwatch_event_rule.ecs_task_failure
  values = { arn = "arn:aws:events:us-west-2:123456789012:rule/test-task-failure" }
}

override_resource {
  target = aws_cloudwatch_event_rule.ecs_task_stopped
  values = { arn = "arn:aws:events:us-west-2:123456789012:rule/test-task-stopped" }
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

run "failures_reach_sns_with_cluster_and_topic_scoped_permissions" {
  command = apply

  assert {
    condition = (
      aws_cloudwatch_event_target.ecs_deployment_failure[0].arn == var.sns_topic_cloudwatch_alarm_arn &&
      aws_cloudwatch_event_target.ecs_deployment_failure[0].rule == aws_cloudwatch_event_rule.ecs_deployment_failure.name &&
      aws_cloudwatch_event_target.ecs_deployment_failure[0].role_arn == aws_iam_role.ecs_alert_publisher[0].arn &&
      aws_cloudwatch_event_target.ecs_task_failure[0].role_arn == aws_iam_role.ecs_alert_publisher[0].arn &&
      aws_cloudwatch_event_target.ecs_task_stopped[0].role_arn == aws_iam_role.ecs_alert_publisher[0].arn
    )
    error_message = "All three ECS failure targets must publish to SNS through the scoped execution role."
  }

  assert {
    condition = (
      jsondecode(aws_cloudwatch_event_rule.ecs_deployment_failure.event_pattern).resources[0].prefix == "arn:aws:ecs:us-west-2:123456789012:service/mgb-test-fabric/" &&
      jsondecode(aws_cloudwatch_event_rule.ecs_task_failure.event_pattern).detail.clusterArn == [module.ecs_cluster.arn] &&
      jsondecode(aws_cloudwatch_event_rule.ecs_task_stopped.event_pattern).detail.clusterArn == [module.ecs_cluster.arn]
    )
    error_message = "Each cluster's failure rules must reject events from other clusters."
  }

  assert {
    condition = (
      jsondecode(aws_iam_role_policy.ecs_alert_publisher[0].policy).Statement[0].Action == "sns:Publish" &&
      jsondecode(aws_iam_role_policy.ecs_alert_publisher[0].policy).Statement[0].Resource == var.sns_topic_cloudwatch_alarm_arn &&
      jsondecode(aws_iam_role.ecs_alert_publisher[0].assume_role_policy).Statement[0].Condition.StringEquals["aws:SourceAccount"] == "123456789012" &&
      toset(jsondecode(aws_iam_role.ecs_alert_publisher[0].assume_role_policy).Statement[0].Condition.ArnEquals["aws:SourceArn"]) == toset([
        aws_cloudwatch_event_rule.ecs_deployment_failure.arn,
        aws_cloudwatch_event_rule.ecs_task_failure.arn,
        aws_cloudwatch_event_rule.ecs_task_stopped.arn,
      ])
    )
    error_message = "EventBridge publication must be bounded to one topic and the account's three failure rules."
  }
}

run "successful_standalone_tasks_are_not_failures" {
  command = plan

  assert {
    condition = try(jsondecode(aws_cloudwatch_event_rule.ecs_task_failure.event_pattern).detail["$or"], null) == jsondecode(jsonencode([
      { stopCode = [{ "anything-but" = "EssentialContainerExited" }] },
      { group = [{ prefix = "service:" }] },
      { containers = { exitCode = [{ "anything-but" = 0 }, { exists = false }] } },
    ]))
    error_message = "STOPPED standalone tasks must have a failure stop code or nonzero exit; service-task stops remain monitored."
  }
}

run "notifications_disabled_creates_no_publish_role_or_failure_targets" {
  command = plan
  variables { sns_topic_cloudwatch_alarm_arn = "" }

  assert {
    condition = (
      length(aws_iam_role.ecs_alert_publisher) == 0 &&
      length(aws_iam_role_policy.ecs_alert_publisher) == 0 &&
      length(aws_cloudwatch_event_target.ecs_deployment_failure) == 0 &&
      length(aws_cloudwatch_event_target.ecs_task_failure) == 0 &&
      length(aws_cloudwatch_event_target.ecs_task_stopped) == 0
    )
    error_message = "Disabling notifications must remove the notification role and all failure targets."
  }
}
