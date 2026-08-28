mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-west-2"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:role/test"
      user_id    = "AROATEST"
    }
  }
}

mock_provider "awsutils" {}
mock_provider "local" {}
mock_provider "random" {}
mock_provider "tls" {}

run "instance_status_failure_is_alarmable" {
  command = plan

  variables {
    org_name     = "mgb"
    stage_name   = "dev"
    service_name = "observability"
    team_name    = "platform"
    vpc_id       = "vpc-test"

    ec2 = {
      host = {
        ami                         = "ami-test"
        subnet_id                   = "subnet-test"
        key_name                    = "test-key"
        create_iam_instance_profile = false
        enable_cloudwatch_alarm     = true
      }
    }
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.status_check["host"].metric_name == "StatusCheckFailed_Instance" &&
      aws_cloudwatch_metric_alarm.status_check["host"].comparison_operator == "GreaterThanOrEqualToThreshold" &&
      aws_cloudwatch_metric_alarm.status_check["host"].threshold == 1 &&
      aws_cloudwatch_metric_alarm.status_check["host"].evaluation_periods == 10 &&
      aws_cloudwatch_metric_alarm.status_check["host"].period == 60
    )
    error_message = "A sustained binary instance-status failure must cross the alarm threshold."
  }
}
