# EventBridge Scheduler ECS run-task targets. These are intentionally not
# represented by legacy aws_cloudwatch_event_rule/aws_cloudwatch_event_target
# resources because Scheduler has a different identity and delivery contract.

locals {
  scheduled_task_map = {
    for k, v in local.ecs_map : k => v
    if v.create && v.type == "scheduled_task" && !v.multiple_containers
  }

  scheduled_task_reuse_input = {
    for k, v in local.scheduled_task_map : k => (
      length(try(trimspace(v.scheduled.reuse_task_definition_key), "")) > 0
      ? try(trimspace(v.scheduled.reuse_task_definition_key), "")
      : k
    )
  }

  ecs_service_task_resource_keys = concat(
    [
      for k, v in local.ecs_map : k
      if v.create && !v.multiple_containers && !(v.type == "scheduled_task" && try(v.scheduled.reuse_task_definition_key, null) != null)
    ],
    [
      for k, v in local.ecs_map : k
      if v.create && v.multiple_containers && v.type == "service"
    ]
  )

  ecs_task_key_by_service_identifier = {
    for k, v in local.ecs_map : v.identifier => k
    if contains(local.ecs_service_task_resource_keys, k)
  }

  scheduled_task_ecs_service_key = {
    for k, v in local.scheduled_task_map : k => (
      contains(local.ecs_service_task_resource_keys, local.scheduled_task_reuse_input[k])
      ? local.scheduled_task_reuse_input[k]
      : try(
        local.ecs_task_key_by_service_identifier[local.scheduled_task_reuse_input[k]],
        local.scheduled_task_reuse_input[k]
      )
    )
  }

  ecs_service_task_resource_keys_hint = join(", ", sort(local.ecs_service_task_resource_keys))

  scheduled_task_reused_service_map = {
    for k, v in local.scheduled_task_map : k => v
    if length(try(trimspace(v.scheduled.reuse_task_definition_key), "")) > 0
  }

  scheduled_task_owned_service_map = {
    for k, v in local.scheduled_task_map : k => v
    if length(try(trimspace(v.scheduled.reuse_task_definition_key), "")) == 0
  }

  # Standalone scheduled tasks own one exact task-definition module instance.
  scheduled_task_owned_resources = {
    for k, v in local.scheduled_task_owned_service_map : k => {
      task_definition_arn     = module.ecs_service[k].task_definition_arn
      task_definition_family  = module.ecs_service[k].task_definition_family
      security_group_ids      = compact([module.ecs_service[k].security_group_id])
      task_exec_iam_role_name = module.ecs_service[k].task_exec_iam_role_name
      task_exec_iam_role_arn  = module.ecs_service[k].task_exec_iam_role_arn
      tasks_iam_role_name     = module.ecs_service[k].tasks_iam_role_name
      tasks_iam_role_arn      = module.ecs_service[k].tasks_iam_role_arn
    }
  }

  # Reused scheduled tasks bind to the already-deployed ECS service. This
  # keeps a schedule-only plan independent from the managed service module
  # collection while preserving the service's exact task revision and roles.
  scheduled_task_reused_resources = {
    for k, v in local.scheduled_task_reused_service_map : k => {
      task_definition_arn     = data.aws_ecs_task_definition.scheduled_task_reuse[k].arn
      task_definition_family  = data.aws_ecs_task_definition.scheduled_task_reuse[k].family
      security_group_ids      = data.aws_ecs_service.scheduled_task_reuse[k].network_configuration[0].security_groups
      task_exec_iam_role_name = basename(data.aws_ecs_task_definition.scheduled_task_reuse[k].execution_role_arn)
      task_exec_iam_role_arn  = data.aws_ecs_task_definition.scheduled_task_reuse[k].execution_role_arn
      tasks_iam_role_name     = basename(data.aws_ecs_task_definition.scheduled_task_reuse[k].task_role_arn)
      tasks_iam_role_arn      = data.aws_ecs_task_definition.scheduled_task_reuse[k].task_role_arn
    }
  }

  scheduled_task_ecs_service_resources = merge(
    local.scheduled_task_owned_resources,
    local.scheduled_task_reused_resources
  )

  scheduled_task_container_override_name = {
    for k, v in local.scheduled_task_map : k => coalesce(
      try(v.scheduled.reuse_container_name, null),
      try(local.ecs_map[local.scheduled_task_ecs_service_key[k]].container_name, null),
      local.scheduled_task_ecs_service_key[k]
    )
  }

  scheduled_task_inputs = {
    for k, v in local.scheduled_task_map : k => (
      v.scheduled.command != null || v.scheduled.cpu != null || v.scheduled.memory != null
      ? jsonencode({
        containerOverrides = [merge(
          { name = local.scheduled_task_container_override_name[k] },
          length(coalesce(v.scheduled.command, [])) > 0 ? { command = v.scheduled.command } : {},
          v.scheduled.cpu != null ? { cpu = v.scheduled.cpu } : {},
          v.scheduled.memory != null ? { memory = v.scheduled.memory } : {}
        )]
      })
      : null
    )
  }

  scheduled_task_dlq_create_map = {
    for k, v in local.scheduled_task_map : k => v
    if try(v.scheduled.dead_letter_config.create, false)
  }

  scheduled_task_dlq_arn = {
    for k, v in local.scheduled_task_map : k => (
      try(v.scheduled.dead_letter_config.create, false)
      ? aws_sqs_queue.scheduled_task_dlq[k].arn
      : try(v.scheduled.dead_letter_config.arn, null)
    )
  }

  scheduled_task_observability_map = {
    for k, v in local.scheduled_task_map : k => v
    if try(v.scheduled.observability.enabled, false)
  }

  scheduler_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "SchedulerOnly"
      Effect    = "Allow"
      Action    = ["sts:AssumeRole"]
      Principal = { Service = "scheduler.amazonaws.com" }
    }]
  })

  scheduler_run_task_policy_reused = {
    for k, v in local.scheduled_task_reused_service_map : k => jsonencode({
      Version = "2012-10-17"
      Statement = concat([
        {
          Sid      = "RunExactTaskDefinition"
          Effect   = "Allow"
          Action   = ["ecs:RunTask"]
          Resource = [local.scheduled_task_reused_resources[k].task_definition_arn]
          Condition = {
            ArnEquals = {
              "ecs:cluster" = module.ecs_cluster.arn
            }
          }
        },
        {
          Sid    = "PassExactEcsTaskRoles"
          Effect = "Allow"
          Action = ["iam:PassRole"]
          Resource = distinct(compact([
            local.scheduled_task_reused_resources[k].tasks_iam_role_arn,
            local.scheduled_task_reused_resources[k].task_exec_iam_role_arn
          ]))
          Condition = {
            StringEquals = {
              "iam:PassedToService" = "ecs-tasks.amazonaws.com"
            }
          }
        }
        ], local.scheduled_task_dlq_arn[k] != null ? [{
          Sid      = "SendToExactDeadLetterQueue"
          Effect   = "Allow"
          Action   = ["sqs:SendMessage"]
          Resource = [local.scheduled_task_dlq_arn[k]]
        }] : []
      )
    })
  }

  scheduler_run_task_policy_owned = {
    for k, v in local.scheduled_task_owned_service_map : k => jsonencode({
      Version = "2012-10-17"
      Statement = concat([
        {
          Sid      = "RunExactTaskDefinition"
          Effect   = "Allow"
          Action   = ["ecs:RunTask"]
          Resource = [local.scheduled_task_owned_resources[k].task_definition_arn]
          Condition = {
            ArnEquals = {
              "ecs:cluster" = module.ecs_cluster.arn
            }
          }
        },
        {
          Sid    = "PassExactEcsTaskRoles"
          Effect = "Allow"
          Action = ["iam:PassRole"]
          Resource = distinct(compact([
            local.scheduled_task_owned_resources[k].tasks_iam_role_arn,
            local.scheduled_task_owned_resources[k].task_exec_iam_role_arn
          ]))
          Condition = {
            StringEquals = {
              "iam:PassedToService" = "ecs-tasks.amazonaws.com"
            }
          }
        }
        ], local.scheduled_task_dlq_arn[k] != null ? [{
          Sid      = "SendToExactDeadLetterQueue"
          Effect   = "Allow"
          Action   = ["sqs:SendMessage"]
          Resource = [local.scheduled_task_dlq_arn[k]]
        }] : []
      )
    })
  }
}

data "aws_ecs_service" "scheduled_task_reuse" {
  for_each = local.scheduled_task_reused_service_map

  cluster_arn  = module.ecs_cluster.arn
  service_name = local.ecs_map[local.scheduled_task_ecs_service_key[each.key]].identifier
}

data "aws_ecs_task_definition" "scheduled_task_reuse" {
  for_each = local.scheduled_task_reused_service_map

  task_definition = data.aws_ecs_service.scheduled_task_reuse[each.key].task_definition
}

resource "aws_sqs_queue" "scheduled_task_dlq" {
  for_each = local.scheduled_task_dlq_create_map

  name                       = coalesce(each.value.scheduled.dead_letter_config.name, "${each.value.identifier}-scheduler-dlq")
  message_retention_seconds  = each.value.scheduled.dead_letter_config.message_retention_seconds
  visibility_timeout_seconds = each.value.scheduled.dead_letter_config.visibility_timeout_seconds
  sqs_managed_sse_enabled    = true
  tags                       = local.tags
}

resource "aws_iam_role" "scheduler" {
  for_each = local.scheduled_task_map

  name = each.value.scheduled.scheduler_role_use_name_prefix ? null : coalesce(
    each.value.scheduled.scheduler_role_name,
    "${each.value.identifier}-scheduler"
  )
  name_prefix = each.value.scheduled.scheduler_role_use_name_prefix ? "${coalesce(
    each.value.scheduled.scheduler_role_name,
    "${each.value.identifier}-scheduler"
  )}-" : null
  assume_role_policy = local.scheduler_assume_role_policy
  tags               = local.tags
}

resource "aws_iam_role_policy" "scheduler_run_task" {
  for_each = local.scheduled_task_reused_service_map

  name   = "${each.value.identifier}-scheduler-run-task"
  role   = aws_iam_role.scheduler[each.key].id
  policy = local.scheduler_run_task_policy_reused[each.key]
}

resource "aws_iam_role_policy" "scheduler_run_task_owned" {
  for_each = local.scheduled_task_owned_service_map

  name   = "${each.value.identifier}-scheduler-run-task"
  role   = aws_iam_role.scheduler[each.key].id
  policy = local.scheduler_run_task_policy_owned[each.key]
}

resource "aws_scheduler_schedule_group" "scheduled_task" {
  for_each = local.scheduled_task_map

  name = substr("${each.value.identifier}-schedules", 0, 64)
  tags = local.tags
}

resource "aws_scheduler_schedule" "ecs_scheduled_task" {
  for_each = local.scheduled_task_reused_service_map

  name                         = "${each.value.identifier}-schedule"
  group_name                   = aws_scheduler_schedule_group.scheduled_task[each.key].name
  description                  = "Run ${each.value.identifier} as an ECS one-shot task"
  schedule_expression          = each.value.scheduled.schedule_expression
  schedule_expression_timezone = each.value.scheduled.schedule_expression_timezone
  state                        = each.value.scheduled.enabled ? "ENABLED" : "DISABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = module.ecs_cluster.arn
    role_arn = aws_iam_role.scheduler[each.key].arn
    input    = local.scheduled_task_inputs[each.key]

    dynamic "dead_letter_config" {
      for_each = local.scheduled_task_dlq_arn[each.key] != null ? [local.scheduled_task_dlq_arn[each.key]] : []
      content {
        arn = dead_letter_config.value
      }
    }

    ecs_parameters {
      task_definition_arn = local.scheduled_task_reused_resources[each.key].task_definition_arn
      launch_type         = "FARGATE"
      platform_version    = each.value.scheduled.platform_version
      task_count          = each.value.scheduled.task_count

      network_configuration {
        subnets = coalesce(each.value.scheduled.subnet_ids, each.value.subnet_ids, var.private_subnets)
        security_groups = coalesce(
          each.value.scheduled.security_group_ids,
          local.scheduled_task_reused_resources[each.key].security_group_ids
        )
        assign_public_ip = each.value.scheduled.assign_public_ip
      }
    }

    retry_policy {
      maximum_retry_attempts       = each.value.scheduled.maximum_retry_attempts
      maximum_event_age_in_seconds = each.value.scheduled.maximum_event_age_in_seconds
    }
  }

  # The target and role ARN expressions already establish the exact implicit
  # dependencies for this schedule instance. A collection-wide depends_on here
  # makes a targeted schedule rebind traverse every ECS service and can turn
  # unrelated task-definition drift into deployable changes.

  lifecycle {
    precondition {
      condition     = contains(local.ecs_service_task_resource_keys, local.scheduled_task_ecs_service_key[each.key])
      error_message = "Scheduled task ${each.key}: set scheduled.reuse_task_definition_key to a key from this list: ${local.ecs_service_task_resource_keys_hint} — or pass the service full identifier string."
    }
  }
}

resource "aws_scheduler_schedule" "ecs_scheduled_task_owned" {
  for_each = local.scheduled_task_owned_service_map

  name                         = "${each.value.identifier}-schedule"
  group_name                   = aws_scheduler_schedule_group.scheduled_task[each.key].name
  description                  = "Run ${each.value.identifier} as an ECS one-shot task"
  schedule_expression          = each.value.scheduled.schedule_expression
  schedule_expression_timezone = each.value.scheduled.schedule_expression_timezone
  state                        = each.value.scheduled.enabled ? "ENABLED" : "DISABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = module.ecs_cluster.arn
    role_arn = aws_iam_role.scheduler[each.key].arn
    input    = local.scheduled_task_inputs[each.key]

    dynamic "dead_letter_config" {
      for_each = local.scheduled_task_dlq_arn[each.key] != null ? [local.scheduled_task_dlq_arn[each.key]] : []
      content {
        arn = dead_letter_config.value
      }
    }

    ecs_parameters {
      task_definition_arn = local.scheduled_task_owned_resources[each.key].task_definition_arn
      launch_type         = "FARGATE"
      platform_version    = each.value.scheduled.platform_version
      task_count          = each.value.scheduled.task_count

      network_configuration {
        subnets = coalesce(each.value.scheduled.subnet_ids, each.value.subnet_ids, var.private_subnets)
        security_groups = coalesce(
          each.value.scheduled.security_group_ids,
          local.scheduled_task_owned_resources[each.key].security_group_ids
        )
        assign_public_ip = each.value.scheduled.assign_public_ip
      }
    }

    retry_policy {
      maximum_retry_attempts       = each.value.scheduled.maximum_retry_attempts
      maximum_event_age_in_seconds = each.value.scheduled.maximum_event_age_in_seconds
    }
  }

  lifecycle {
    precondition {
      condition     = contains(local.ecs_service_task_resource_keys, local.scheduled_task_ecs_service_key[each.key])
      error_message = "Scheduled task ${each.key}: set scheduled.reuse_task_definition_key to a key from this list: ${local.ecs_service_task_resource_keys_hint} — or pass the service full identifier string."
    }
  }
}

resource "aws_cloudwatch_event_rule" "scheduled_task_nonzero_exit" {
  for_each = local.scheduled_task_observability_map

  name        = substr("${each.value.identifier}-nonzero-exit", 0, 64)
  description = "Match nonzero ECS container exits for ${each.value.identifier}"
  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Task State Change"]
    detail = {
      lastStatus        = ["STOPPED"]
      clusterArn        = [module.ecs_cluster.arn]
      taskDefinitionArn = [local.scheduled_task_ecs_service_resources[each.key].task_definition_arn]
      containers = {
        name = [local.scheduled_task_container_override_name[each.key]]
        exitCode = [{
          anything-but = 0
        }]
      }
    }
  })

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "scheduled_task_launch_failure" {
  for_each = local.scheduled_task_observability_map

  alarm_name          = "${each.value.identifier}-scheduler-target-errors"
  alarm_description   = "EventBridge Scheduler could not launch ${each.value.identifier}"
  namespace           = "AWS/Scheduler"
  metric_name         = "TargetErrorCount"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    ScheduleGroup = aws_scheduler_schedule_group.scheduled_task[each.key].name
  }
  alarm_actions = each.value.scheduled.observability.alarm_actions
  ok_actions    = each.value.scheduled.observability.ok_actions
  tags          = local.tags
}

resource "aws_cloudwatch_metric_alarm" "scheduled_task_nonzero_exit" {
  for_each = local.scheduled_task_observability_map

  alarm_name          = "${each.value.identifier}-nonzero-exit"
  alarm_description   = "The scheduled ECS task ${each.value.identifier} stopped with a nonzero container exit"
  namespace           = "AWS/Events"
  metric_name         = "TriggeredRules"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    RuleName = aws_cloudwatch_event_rule.scheduled_task_nonzero_exit[each.key].name
  }
  alarm_actions = each.value.scheduled.observability.alarm_actions
  ok_actions    = each.value.scheduled.observability.ok_actions
  tags          = local.tags
}

resource "aws_cloudwatch_metric_alarm" "scheduled_task_freshness" {
  for_each = local.scheduled_task_observability_map

  alarm_name          = "${each.value.identifier}-success-freshness"
  alarm_description   = "No explicit successful completion signal was received for ${each.value.identifier} within its freshness window"
  namespace           = each.value.scheduled.observability.success_signal.namespace
  metric_name         = each.value.scheduled.observability.success_signal.metric_name
  dimensions          = each.value.scheduled.observability.success_signal.dimensions
  statistic           = each.value.scheduled.observability.success_signal.statistic
  period              = each.value.scheduled.observability.success_signal.period_seconds
  evaluation_periods  = each.value.scheduled.observability.success_signal.freshness_window_seconds / each.value.scheduled.observability.success_signal.period_seconds
  datapoints_to_alarm = each.value.scheduled.observability.success_signal.freshness_window_seconds / each.value.scheduled.observability.success_signal.period_seconds
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = each.value.scheduled.observability.alarm_actions
  ok_actions          = each.value.scheduled.observability.ok_actions
  tags                = local.tags
}
