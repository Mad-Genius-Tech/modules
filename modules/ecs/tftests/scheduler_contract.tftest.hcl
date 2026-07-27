mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name   = "us-west-2"
      region = "us-west-2"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test"
      user_id    = "AIDATEST"
    }
  }

  mock_data "aws_secretsmanager_secret" {
    defaults = {
      arn  = "arn:aws:secretsmanager:us-west-2:123456789012:secret:mgb-dev/fabric-auth/migration-snapshot-AbCdEf"
      name = "mgb-dev/fabric-auth/migration-snapshot"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }
}

run "service_defaults_remain_backward_compatible" {
  command = plan

  variables {
    org_name            = "mgb"
    stage_name          = "test"
    service_name        = "compat"
    team_name           = "platform"
    tags                = {}
    private_subnets     = ["subnet-private"]
    public_subnets      = ["subnet-public"]
    ingress_cidr_blocks = ["10.0.0.0/16"]
    vpc_id              = "vpc-test"
    vpc_cidr            = "10.0.0.0/16"
    create_internal_alb = false

    ecs_services = {
      api = {
        container_image                = "123456789012.dkr.ecr.us-west-2.amazonaws.com/api:existing"
        require_repository_credentials = false
      }
    }
  }

  assert {
    condition = (
      output.ecs_map.api.enable_health_check &&
      output.ecs_map.api.enable_port_mappings &&
      output.ecs_map.api.enable_default_ingress_rule &&
      output.ecs_map.api.task_exec_iam_role_use_name_prefix &&
      output.ecs_map.api.tasks_iam_role_use_name_prefix
    )
    error_message = "New scheduled-task controls must preserve all existing service defaults."
  }

  assert {
    condition = (
      module.ecs_service["api"].container_definitions["api"].container_definition.healthCheck != null &&
      length(module.ecs_service["api"].container_definitions["api"].container_definition.portMappings) == 1
    )
    error_message = "Existing service callers must retain their HTTP health check and service port mapping."
  }

  assert {
    condition = (
      length(output.ecs_map.api.security_group_ingress_rules_resolved) == 1 &&
      output.ecs_map.api.security_group_egress_rules_resolved.egress_all.cidr_ipv4 == "0.0.0.0/0"
    )
    error_message = "Existing service callers must retain default ingress and broad egress behavior."
  }

  assert {
    condition     = length(aws_scheduler_schedule.ecs_scheduled_task) == 0
    error_message = "Ordinary ECS services must not create Scheduler resources."
  }
}

run "scheduler_task_contract" {
  command = plan

  override_module {
    target          = module.ecs_cluster
    override_during = plan
    outputs = {
      arn  = "arn:aws:ecs:us-west-2:123456789012:cluster/mgb-dev-fabric-auth"
      id   = "arn:aws:ecs:us-west-2:123456789012:cluster/mgb-dev-fabric-auth"
      name = "mgb-dev-fabric-auth"
    }
  }

  override_resource {
    target          = module.ecs_service["migration-snapshot"].aws_ecs_task_definition.this[0]
    override_during = plan
    values = {
      arn = "arn:aws:ecs:us-west-2:123456789012:task-definition/mgb-dev-fabric-auth-migration-snapshot:42"
    }
  }

  override_resource {
    target          = module.ecs_service["migration-snapshot"].aws_iam_role.task_exec[0]
    override_during = plan
    values = {
      arn = "arn:aws:iam::123456789012:role/mgb-dev-fabric-auth-migration-snapshot-execution"
    }
  }

  override_resource {
    target          = module.ecs_service["migration-snapshot"].aws_iam_role.tasks[0]
    override_during = plan
    values = {
      arn = "arn:aws:iam::123456789012:role/mgb-dev-fabric-auth-migration-snapshot-task"
    }
  }

  override_resource {
    target          = module.ecs_service["migration-snapshot"].aws_security_group.this[0]
    override_during = plan
    values = {
      id = "sg-migration-snapshot"
    }
  }

  override_resource {
    target          = aws_sqs_queue.scheduled_task_dlq["migration-snapshot"]
    override_during = plan
    values = {
      arn = "arn:aws:sqs:us-west-2:123456789012:mgb-dev-fabric-auth-migration-snapshot-dlq"
    }
  }

  override_resource {
    target          = aws_iam_role.scheduler["migration-snapshot"]
    override_during = plan
    values = {
      arn = "arn:aws:iam::123456789012:role/mgb-dev-fabric-auth-migration-snapshot-scheduler"
    }
  }

  variables {
    org_name            = "mgb"
    stage_name          = "dev"
    service_name        = "fabric-auth"
    team_name           = "platform"
    tags                = {}
    private_subnets     = ["subnet-private-a", "subnet-private-b"]
    public_subnets      = ["subnet-public"]
    ingress_cidr_blocks = ["10.0.0.0/16"]
    vpc_id              = "vpc-test"
    vpc_cidr            = "10.0.0.0/16"
    create_internal_alb = false

    ecs_services = {
      migration-snapshot = {
        type                               = "scheduled_task"
        container_image                    = "123456789012.dkr.ecr.us-west-2.amazonaws.com/fabric-auth@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        container_name                     = "migration-snapshot"
        task_definition_family             = "mgb-dev-fabric-auth-migration-snapshot"
        task_exec_iam_role_name            = "mgb-dev-fabric-auth-migration-snapshot-execution"
        task_exec_iam_role_use_name_prefix = false
        tasks_iam_role_name                = "mgb-dev-fabric-auth-migration-snapshot-task"
        tasks_iam_role_use_name_prefix     = false
        enable_health_check                = false
        enable_port_mappings               = false
        enable_default_ingress_rule        = false
        security_group_egress_rules = {
          encrypted_bootstrap = {
            from_port   = "443"
            to_port     = "443"
            ip_protocol = "tcp"
            cidr_ipv4   = "10.0.0.0/16"
          }
          aurora = {
            from_port   = "5432"
            to_port     = "5432"
            ip_protocol = "tcp"
            cidr_ipv4   = "10.0.0.0/16"
          }
        }
        secrets = [{
          name        = "DATABASE_URL"
          secret_path = "mgb-dev/fabric-auth/migration-snapshot"
          secret_key  = "database_url"
        }]
        scheduled = {
          enabled                        = false
          schedule_expression            = "cron(0 7 * * ? *)"
          schedule_expression_timezone   = "UTC"
          maximum_retry_attempts         = 2
          maximum_event_age_in_seconds   = 600
          scheduler_role_name            = "mgb-dev-fabric-auth-migration-snapshot-scheduler"
          scheduler_role_use_name_prefix = false
          dead_letter_config = {
            create = true
            name   = "mgb-dev-fabric-auth-migration-snapshot-dlq"
          }
          observability = {
            enabled = true
            success_signal = {
              namespace                = "FabricBloc/AuthMigrationSnapshot"
              metric_name              = "SuccessfulCompletion"
              dimensions               = { Task = "migration-snapshot" }
              freshness_window_seconds = 90000
            }
          }
        }
      }
    }
  }

  assert {
    condition = (
      aws_scheduler_schedule.ecs_scheduled_task["migration-snapshot"].state == "DISABLED" &&
      aws_scheduler_schedule.ecs_scheduled_task["migration-snapshot"].schedule_expression_timezone == "UTC" &&
      aws_scheduler_schedule.ecs_scheduled_task["migration-snapshot"].group_name == aws_scheduler_schedule_group.scheduled_task["migration-snapshot"].name &&
      aws_scheduler_schedule.ecs_scheduled_task["migration-snapshot"].flexible_time_window[0].mode == "OFF" &&
      aws_scheduler_schedule.ecs_scheduled_task["migration-snapshot"].target[0].ecs_parameters[0].launch_type == "FARGATE" &&
      toset(aws_scheduler_schedule.ecs_scheduled_task["migration-snapshot"].target[0].ecs_parameters[0].network_configuration[0].subnets) == toset(["subnet-private-a", "subnet-private-b"]) &&
      !aws_scheduler_schedule.ecs_scheduled_task["migration-snapshot"].target[0].ecs_parameters[0].network_configuration[0].assign_public_ip
    )
    error_message = "The Scheduler target must be disabled-first, UTC, flexible-window-off, private, and Fargate."
  }

  assert {
    condition = (
      aws_scheduler_schedule.ecs_scheduled_task["migration-snapshot"].target[0].retry_policy[0].maximum_retry_attempts == 2 &&
      aws_scheduler_schedule.ecs_scheduled_task["migration-snapshot"].target[0].retry_policy[0].maximum_event_age_in_seconds == 600 &&
      aws_scheduler_schedule.ecs_scheduled_task["migration-snapshot"].target[0].dead_letter_config[0].arn == aws_sqs_queue.scheduled_task_dlq["migration-snapshot"].arn &&
      output.ecs_scheduled_tasks["migration-snapshot"].dead_letter_queue_arn == aws_sqs_queue.scheduled_task_dlq["migration-snapshot"].arn
    )
    error_message = "Retry policy and the exact optional DLQ ARN must reach the Scheduler target and outputs."
  }

  assert {
    condition = (
      output.ecs_map["migration-snapshot"].task_definition_family == "mgb-dev-fabric-auth-migration-snapshot" &&
      !output.ecs_map["migration-snapshot"].task_exec_iam_role_use_name_prefix &&
      !output.ecs_map["migration-snapshot"].tasks_iam_role_use_name_prefix &&
      aws_iam_role.scheduler["migration-snapshot"].name == "mgb-dev-fabric-auth-migration-snapshot-scheduler" &&
      output.ecs_scheduled_tasks["migration-snapshot"].task_definition_family == "mgb-dev-fabric-auth-migration-snapshot" &&
      output.ecs_scheduled_tasks["migration-snapshot"].task_exec_iam_role_name == "mgb-dev-fabric-auth-migration-snapshot-execution" &&
      output.ecs_scheduled_tasks["migration-snapshot"].task_runtime_iam_role_name == "mgb-dev-fabric-auth-migration-snapshot-task" &&
      output.ecs_scheduled_tasks["migration-snapshot"].scheduler_iam_role_name == "mgb-dev-fabric-auth-migration-snapshot-scheduler" &&
      output.ecs_scheduled_tasks["migration-snapshot"].container_name == "migration-snapshot" &&
      output.ecs_scheduled_tasks["migration-snapshot"].cloudwatch_log_group_name == "/aws/ecs/mgb-dev-fabric-auth-migration-snapshot/migration-snapshot" &&
      module.ecs_service["migration-snapshot"].container_definitions["migration-snapshot"].container_definition.image == "123456789012.dkr.ecr.us-west-2.amazonaws.com/fabric-auth@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    )
    error_message = "Stable task, execution, Scheduler, family, container, and log-group identities must be exact."
  }

  assert {
    condition = (
      !can(module.ecs_service["migration-snapshot"].container_definitions["migration-snapshot"].container_definition.healthCheck) &&
      !can(module.ecs_service["migration-snapshot"].container_definitions["migration-snapshot"].container_definition.portMappings) &&
      length(output.ecs_map["migration-snapshot"].security_group_ingress_rules_resolved) == 0 &&
      toset(keys(output.ecs_map["migration-snapshot"].security_group_egress_rules_resolved)) == toset(["encrypted_bootstrap", "aurora"])
    )
    error_message = "One-shot tasks must be able to omit service health, ports, and ingress while supplying bounded egress."
  }

  assert {
    condition = toset(output.ecs_scheduled_tasks["migration-snapshot"].task_exec_secret_arns) == toset([
      "arn:aws:secretsmanager:us-west-2:123456789012:secret:mgb-dev/fabric-auth/migration-snapshot-AbCdEf"
    ])
    error_message = "Scheduled-task execution permissions must derive the exact resolved container secret ARN with no wildcard shortcut."
  }

  assert {
    condition = (
      jsondecode(aws_iam_role.scheduler["migration-snapshot"].assume_role_policy).Statement[0].Principal.Service == "scheduler.amazonaws.com" &&
      jsondecode(aws_iam_role.scheduler["migration-snapshot"].assume_role_policy).Statement[0].Action == ["sts:AssumeRole"]
    )
    error_message = "The dedicated Scheduler role trust must name only scheduler.amazonaws.com."
  }

  assert {
    condition = (
      jsondecode(aws_iam_role_policy.scheduler_run_task["migration-snapshot"].policy).Statement[0].Resource == [output.ecs_scheduled_tasks["migration-snapshot"].task_definition_arn] &&
      jsondecode(aws_iam_role_policy.scheduler_run_task["migration-snapshot"].policy).Statement[0].Condition.ArnEquals["ecs:cluster"] == output.ecs_cluster_arn &&
      toset(jsondecode(aws_iam_role_policy.scheduler_run_task["migration-snapshot"].policy).Statement[1].Resource) == toset([
        output.ecs_scheduled_tasks["migration-snapshot"].task_runtime_iam_role_arn,
        output.ecs_scheduled_tasks["migration-snapshot"].task_exec_iam_role_arn
      ]) &&
      jsondecode(aws_iam_role_policy.scheduler_run_task["migration-snapshot"].policy).Statement[1].Condition.StringEquals["iam:PassedToService"] == "ecs-tasks.amazonaws.com" &&
      !contains(jsondecode(aws_iam_role_policy.scheduler_run_task["migration-snapshot"].policy).Statement[1].Resource, output.ecs_scheduled_tasks["migration-snapshot"].scheduler_iam_role_arn)
    )
    error_message = "Scheduler RunTask and PassRole must be exact, cluster-bound, service-conditioned, and exclude the Scheduler role itself."
  }

  assert {
    condition = (
      jsondecode(aws_iam_role_policy.scheduler_run_task["migration-snapshot"].policy).Statement[2].Action == ["sqs:SendMessage"] &&
      jsondecode(aws_iam_role_policy.scheduler_run_task["migration-snapshot"].policy).Statement[2].Resource == [output.ecs_scheduled_tasks["migration-snapshot"].dead_letter_queue_arn]
    )
    error_message = "DLQ delivery permission must be bounded to the exact queue ARN."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.scheduled_task_launch_failure["migration-snapshot"].namespace == "AWS/Scheduler" &&
      aws_cloudwatch_metric_alarm.scheduled_task_launch_failure["migration-snapshot"].metric_name == "TargetErrorCount" &&
      length(keys(aws_cloudwatch_metric_alarm.scheduled_task_launch_failure["migration-snapshot"].dimensions)) == 1 &&
      aws_cloudwatch_metric_alarm.scheduled_task_launch_failure["migration-snapshot"].dimensions["ScheduleGroup"] == aws_scheduler_schedule_group.scheduled_task["migration-snapshot"].name
    )
    error_message = "Scheduler launch failures must use TargetErrorCount scoped to the task's dedicated schedule group."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.scheduled_task_nonzero_exit["migration-snapshot"].namespace == "AWS/Events" &&
      aws_cloudwatch_metric_alarm.scheduled_task_nonzero_exit["migration-snapshot"].metric_name == "TriggeredRules" &&
      toset(jsondecode(aws_cloudwatch_event_rule.scheduled_task_nonzero_exit["migration-snapshot"].event_pattern).detail.taskDefinitionArn) == toset([output.ecs_scheduled_tasks["migration-snapshot"].task_definition_arn]) &&
      jsondecode(aws_cloudwatch_event_rule.scheduled_task_nonzero_exit["migration-snapshot"].event_pattern).detail.containers.exitCode[0]["anything-but"] == 0
    )
    error_message = "ECS task-result failures must use a distinct exact task-definition/container nonzero-exit signal."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.scheduled_task_freshness["migration-snapshot"].namespace == "FabricBloc/AuthMigrationSnapshot" &&
      aws_cloudwatch_metric_alarm.scheduled_task_freshness["migration-snapshot"].metric_name == "SuccessfulCompletion" &&
      aws_cloudwatch_metric_alarm.scheduled_task_freshness["migration-snapshot"].period == 3600 &&
      aws_cloudwatch_metric_alarm.scheduled_task_freshness["migration-snapshot"].evaluation_periods == 25 &&
      aws_cloudwatch_metric_alarm.scheduled_task_freshness["migration-snapshot"].datapoints_to_alarm == 25 &&
      aws_cloudwatch_metric_alarm.scheduled_task_freshness["migration-snapshot"].comparison_operator == "LessThanThreshold" &&
      aws_cloudwatch_metric_alarm.scheduled_task_freshness["migration-snapshot"].treat_missing_data == "breaching"
    )
    error_message = "Freshness monitoring must use the caller's explicit success metric and breach when it is missing."
  }

  assert {
    condition = (
      aws_scheduler_schedule.ecs_scheduled_task["migration-snapshot"].name != "" &&
      length(regexall("resource \"aws_scheduler_schedule\" \"ecs_scheduled_task\"", file("${path.module}/scheduled_tasks.tf"))) == 1 &&
      length(regexall("resource \"aws_cloudwatch_event_rule\" \"ecs_scheduled_task\"", file("${path.module}/scheduled_tasks.tf"))) == 0 &&
      length(regexall("resource \"aws_cloudwatch_event_target\" \"ecs_scheduled_task\"", file("${path.module}/scheduled_tasks.tf"))) == 0
    )
    error_message = "The scheduling path must use aws_scheduler_schedule and must not substitute the legacy rule/target pair."
  }
}

run "scheduled_observability_is_opt_in" {
  command = plan

  variables {
    org_name            = "mgb"
    stage_name          = "test"
    service_name        = "sched"
    team_name           = "platform"
    tags                = {}
    private_subnets     = ["subnet-private"]
    public_subnets      = ["subnet-public"]
    ingress_cidr_blocks = ["10.0.0.0/16"]
    vpc_id              = "vpc-test"
    vpc_cidr            = "10.0.0.0/16"
    create_internal_alb = false

    ecs_services = {
      nightly = {
        type                           = "scheduled_task"
        container_image                = "123456789012.dkr.ecr.us-west-2.amazonaws.com/nightly:test"
        require_repository_credentials = false
        scheduled = {
          schedule_expression = "cron(0 7 * * ? *)"
        }
      }
    }
  }

  assert {
    condition = (
      aws_scheduler_schedule.ecs_scheduled_task["nightly"].state == "DISABLED" &&
      length(aws_cloudwatch_metric_alarm.scheduled_task_launch_failure) == 0 &&
      length(aws_cloudwatch_metric_alarm.scheduled_task_nonzero_exit) == 0 &&
      length(aws_cloudwatch_metric_alarm.scheduled_task_freshness) == 0 &&
      output.ecs_scheduled_tasks["nightly"].observability_alarm_arns == null
    )
    error_message = "Scheduled tasks must remain disabled and create no per-task alarms unless observability is explicitly enabled."
  }
}
