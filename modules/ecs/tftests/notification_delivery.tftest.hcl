mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/test-alert-publisher" }
  }
  mock_resource "aws_ecs_task_definition" {
    defaults = { arn = "arn:aws:ecs:us-west-2:123456789012:task-definition/test-job:1" }
  }
  mock_resource "aws_iam_policy" {
    defaults = { arn = "arn:aws:iam::123456789012:policy/test-policy" }
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
  ecs_services = {
    auth    = { container_image = "example/auth:test", require_repository_credentials = false }
    job     = { container_image = "example/job:test", require_repository_credentials = false, type = "scheduled_task", scheduled = { schedule_expression = "rate(1 hour)" } }
    omitted = { container_image = "example/omitted:test", create = false }
  }
}

run "grouped_failures_preserve_deployment_delivery_and_availability" {
  command = apply
  assert {
    condition = (
      length(aws_cloudwatch_event_rule.ecs_service_task_failure) == 1 &&
      length(aws_cloudwatch_metric_alarm.ecs_service_task_failure) == 1 &&
      length(aws_cloudwatch_event_rule.ecs_standalone_task_failure) == 1 &&
      aws_cloudwatch_event_target.ecs_deployment_failure[0].arn == var.sns_topic_cloudwatch_alarm_arn &&
      aws_cloudwatch_event_target.ecs_deployment_failure[0].role_arn == aws_iam_role.ecs_alert_publisher[0].arn &&
      aws_cloudwatch_metric_alarm.ecs_service_running_tasks_below_desired["auth"].treat_missing_data == "breaching"
    )
    error_message = "Only created services get grouped alarms; deployment delivery and missing-data availability paging remain."
  }
  assert {
    condition = (
      jsondecode(aws_cloudwatch_event_rule.ecs_service_task_failure["auth"].event_pattern).detail.group == ["service:mgb-test-fabric-auth"] &&
      jsondecode(aws_cloudwatch_event_rule.ecs_service_task_failure["auth"].event_pattern).detail.clusterArn == [module.ecs_cluster.arn] &&
      jsondecode(aws_cloudwatch_event_rule.ecs_standalone_task_failure[0].event_pattern).detail.clusterArn == [module.ecs_cluster.arn] &&
      jsondecode(aws_cloudwatch_event_rule.ecs_deployment_failure.event_pattern).resources[0].prefix == "arn:aws:ecs:us-west-2:123456789012:service/mgb-test-fabric/"
    )
    error_message = "Rule matching must stay within the intended cluster and exact service."
  }
  assert {
    condition = alltrue([for a in concat(values(aws_cloudwatch_metric_alarm.ecs_service_task_failure), aws_cloudwatch_metric_alarm.ecs_standalone_task_failure) :
      a.namespace == "AWS/Events" && a.metric_name == "TriggeredRules" && a.statistic == "Sum" &&
      a.period == 60 && a.evaluation_periods == 15 && a.datapoints_to_alarm == 1 &&
      a.threshold == 1 && a.comparison_operator == "GreaterThanOrEqualToThreshold" &&
      a.treat_missing_data == "notBreaching" && a.actions_enabled &&
      toset(a.alarm_actions) == toset([var.sns_topic_cloudwatch_alarm_arn]) &&
      toset(a.ok_actions) == toset([var.sns_topic_cloudwatch_alarm_arn]) && length(a.insufficient_data_actions) == 0
    ])
    error_message = "One observed failure must alarm in a 15-period window, with only the configured SNS actions."
  }
  assert {
    condition = (
      aws_cloudwatch_metric_alarm.ecs_service_task_failure["auth"].dimensions == tomap({ RuleName = aws_cloudwatch_event_rule.ecs_service_task_failure["auth"].name }) &&
      aws_cloudwatch_metric_alarm.ecs_standalone_task_failure[0].dimensions == tomap({ RuleName = aws_cloudwatch_event_rule.ecs_standalone_task_failure[0].name })
    )
    error_message = "Alarm dimensions must reference their own default-bus rules exactly."
  }
  assert {
    condition = (
      jsondecode(aws_iam_role_policy.ecs_alert_publisher[0].policy).Statement[0].Action == "sns:Publish" &&
      jsondecode(aws_iam_role_policy.ecs_alert_publisher[0].policy).Statement[0].Resource == var.sns_topic_cloudwatch_alarm_arn &&
      jsondecode(aws_iam_role.ecs_alert_publisher[0].assume_role_policy).Statement[0].Condition.StringEquals["aws:SourceAccount"] == "123456789012" &&
      toset(jsondecode(aws_iam_role.ecs_alert_publisher[0].assume_role_policy).Statement[0].Condition.ArnEquals["aws:SourceArn"]) == toset([aws_cloudwatch_event_rule.ecs_deployment_failure.arn])
    )
    error_message = "The publisher trust must narrow to deployment failure only, without widening SNS permissions."
  }
}

run "notifications_disabled" {
  command = plan
  variables { sns_topic_cloudwatch_alarm_arn = "" }
  assert {
    condition = (
      length(aws_iam_role.ecs_alert_publisher) == 0 && length(aws_iam_role_policy.ecs_alert_publisher) == 0 &&
      length(aws_cloudwatch_event_target.ecs_deployment_failure) == 0 &&
      length(aws_cloudwatch_event_rule.ecs_service_task_failure) == 0 && length(aws_cloudwatch_event_rule.ecs_standalone_task_failure) == 0 &&
      length(aws_cloudwatch_metric_alarm.ecs_service_task_failure) == 0 && length(aws_cloudwatch_metric_alarm.ecs_standalone_task_failure) == 0
    )
    error_message = "Disabled notifications must create no failure rules, alarms or publishing grants."
  }
}
run "custom_window_without_ok_notifications" {
  command = plan
  variables {
    task_failure_alarm_window_minutes = 1
    task_failure_ok_notifications     = false
  }
  assert {
    condition     = alltrue([for a in concat(values(aws_cloudwatch_metric_alarm.ecs_service_task_failure), aws_cloudwatch_metric_alarm.ecs_standalone_task_failure) : a.evaluation_periods == 1 && length(a.ok_actions) == 0])
    error_message = "The minimum window and optional OK action must apply to both alarm kinds."
  }
}
run "maximum_window" {
  command = plan
  variables { task_failure_alarm_window_minutes = 60 }
  assert {
    condition     = aws_cloudwatch_metric_alarm.ecs_standalone_task_failure[0].evaluation_periods == 60
    error_message = "The maximum supported window is 60 minutes."
  }
}

run "reject_zero_window" {
  command = plan
  variables { task_failure_alarm_window_minutes = 0 }
  expect_failures = [var.task_failure_alarm_window_minutes]
}

run "reject_too_large_window" {
  command = plan
  variables { task_failure_alarm_window_minutes = 61 }
  expect_failures = [var.task_failure_alarm_window_minutes]
}

run "reject_fractional_window" {
  command = plan
  variables { task_failure_alarm_window_minutes = 1.5 }
  expect_failures = [var.task_failure_alarm_window_minutes]
}
