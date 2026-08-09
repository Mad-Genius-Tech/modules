mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test"
      user_id    = "AIDATEST"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }
}

run "stopped_service_missing_running_count_is_not_breaching" {
  command = plan

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
    container_insights             = "enabled"
    sns_topic_cloudwatch_alarm_arn = "arn:aws:sns:us-east-1:123456789012:alarms"

    ecs_services = {
      capture = {
        container_image                = "123456789012.dkr.ecr.us-east-1.amazonaws.com/capture:test"
        require_repository_credentials = false
        desired_count                  = 0
      }
    }
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.ecs_service_running_tasks_below_desired["capture"].threshold == 0 &&
      aws_cloudwatch_metric_alarm.ecs_service_running_tasks_below_desired["capture"].treat_missing_data == "notBreaching"
    )
    error_message = "An intentionally stopped ECS service must not alarm solely because RunningTaskCount is absent."
  }
}

run "running_service_missing_count_remains_breaching" {
  command = plan

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
    container_insights             = "enabled"
    sns_topic_cloudwatch_alarm_arn = "arn:aws:sns:us-east-1:123456789012:alarms"

    ecs_services = {
      api = {
        container_image                = "123456789012.dkr.ecr.us-east-1.amazonaws.com/api:test"
        require_repository_credentials = false
        desired_count                  = 2
      }
    }
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.ecs_service_running_tasks_below_desired["api"].threshold == 2 &&
      aws_cloudwatch_metric_alarm.ecs_service_running_tasks_below_desired["api"].treat_missing_data == "breaching"
    )
    error_message = "A running ECS service must still alarm when RunningTaskCount is missing or below its positive desired count."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.ecs_service_running_tasks_below_desired["api"].comparison_operator == "LessThanThreshold" &&
      aws_cloudwatch_metric_alarm.ecs_service_running_tasks_below_desired["api"].namespace == "ECS/ContainerInsights" &&
      aws_cloudwatch_metric_alarm.ecs_service_running_tasks_below_desired["api"].metric_name == "RunningTaskCount" &&
      aws_cloudwatch_metric_alarm.ecs_service_running_tasks_below_desired["api"].statistic == "Minimum" &&
      aws_cloudwatch_metric_alarm.ecs_service_running_tasks_below_desired["api"].period == 60 &&
      aws_cloudwatch_metric_alarm.ecs_service_running_tasks_below_desired["api"].evaluation_periods == 2 &&
      aws_cloudwatch_metric_alarm.ecs_service_running_tasks_below_desired["api"].datapoints_to_alarm == 2 &&
      aws_cloudwatch_metric_alarm.ecs_service_running_tasks_below_desired["api"].actions_enabled &&
      toset(aws_cloudwatch_metric_alarm.ecs_service_running_tasks_below_desired["api"].alarm_actions) == toset(["arn:aws:sns:us-east-1:123456789012:alarms"]) &&
      toset(aws_cloudwatch_metric_alarm.ecs_service_running_tasks_below_desired["api"].ok_actions) == toset(["arn:aws:sns:us-east-1:123456789012:alarms"]) &&
      aws_cloudwatch_metric_alarm.ecs_service_running_tasks_below_desired["api"].dimensions["ClusterName"] == module.ecs_cluster.name &&
      aws_cloudwatch_metric_alarm.ecs_service_running_tasks_below_desired["api"].dimensions["ServiceName"] == output.ecs_map.api.identifier
    )
    error_message = "The running-task alarm must preserve its existing metric, threshold window, actions, and ECS dimensions."
  }
}
