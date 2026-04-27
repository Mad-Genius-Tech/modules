# EventBridge (CloudWatch Events) scheduled rules + ECS run-task targets.
# This is the same integration the ECS console shows under "Scheduled tasks".
# (EventBridge Scheduler / aws_scheduler_schedule does not appear there.)
#
# Note: `schedule_expression` for rules uses UTC. The variable
# `schedule_expression_timezone` on ecs_services is not applied to these rules;
# express the schedule in UTC or offset your cron/rate expression accordingly.

locals {
  scheduled_task_map = { for k, v in local.ecs_map : k => v
  if v.create && v.type == "scheduled_task" && !v.multiple_containers }

  # Reuse: trimmed non-empty string, or this map key. Empty/whitespace reverts to this key.
  scheduled_task_reuse_input = { for k, v in local.scheduled_task_map : k => (
    length(trimspace(try(v.scheduled.reuse_task_definition_key, ""))) > 0
    ? trimspace(try(v.scheduled.reuse_task_definition_key, ""))
  : k) }

  ecs_service_task_resources = merge(
    { for key, m in module.ecs_service : key => {
      task_definition_arn    = m.task_definition_arn
      security_group_id      = m.security_group_id
      task_exec_iam_role_arn = m.task_exec_iam_role_arn
      tasks_iam_role_arn     = m.tasks_iam_role_arn
    } },
    { for key, m in module.ecs_service_multiples : key => {
      task_definition_arn    = m.task_definition_arn
      security_group_id      = m.security_group_id
      task_exec_iam_role_arn = m.task_exec_iam_role_arn
      tasks_iam_role_arn     = m.tasks_iam_role_arn
    } }
  )

  # Full ECS service id string `identifier` in main.tf -> ecs_services map key
  ecs_task_key_by_service_identifier = { for k2, v2 in local.ecs_map : v2.identifier => k2
  if contains(keys(local.ecs_service_task_resources), k2) }

  # Resolve to a key in ecs_service_task_resources: direct key, or the full `identifier` string
  scheduled_task_ecs_service_key = { for k, v in local.scheduled_task_map : k => (
    contains(keys(local.ecs_service_task_resources), local.scheduled_task_reuse_input[k]) ? local.scheduled_task_reuse_input[k] : try(
      local.ecs_task_key_by_service_identifier[local.scheduled_task_reuse_input[k]],
      local.scheduled_task_reuse_input[k]
    )
  ) }

  ecs_service_task_resource_keys_hint = join(", ", sort(keys(local.ecs_service_task_resources)))

  scheduled_task_container_override_name = { for k, v in local.scheduled_task_map : k => (
    try(local.ecs_map[local.scheduled_task_ecs_service_key[k]].multiple_containers, false) ? coalesce(
      try(v.scheduled.reuse_container_name, null),
      try(local.ecs_map[local.scheduled_task_ecs_service_key[k]].container_name, null),
      try(element(sort(keys(try(local.ecs_map[local.scheduled_task_ecs_service_key[k]].container_definitions, {}))), 0), null),
      local.scheduled_task_ecs_service_key[k]
    ) : local.scheduled_task_ecs_service_key[k]
  ) }

  scheduler_passrole_arns = distinct(compact(flatten([
    for k, v in local.scheduled_task_map : [
      local.ecs_service_task_resources[local.scheduled_task_ecs_service_key[k]].task_exec_iam_role_arn,
      local.ecs_service_task_resources[local.scheduled_task_ecs_service_key[k]].tasks_iam_role_arn
    ]
  ])))

  scheduled_task_inputs = { for k, v in local.scheduled_task_map : k => (
    v.scheduled.command != null || v.scheduled.cpu != null || v.scheduled.memory != null
    ? jsonencode({
      containerOverrides = [merge(
        { name = local.scheduled_task_container_override_name[k] },
        length(coalesce(v.scheduled.command, [])) > 0 ? { command = v.scheduled.command } : {},
        v.scheduled.cpu != null ? { cpu = v.scheduled.cpu } : {},
        v.scheduled.memory != null ? { memory = v.scheduled.memory } : {}
      )]
    }) : null
  ) }
}

data "aws_iam_policy_document" "scheduler_assume_role" {
  count = length(local.scheduled_task_map) > 0 ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "scheduler_run_task" {
  count = length(local.scheduled_task_map) > 0 ? 1 : 0

  statement {
    sid    = "AllowRunTask"
    effect = "Allow"
    actions = [
      "ecs:RunTask"
    ]
    resources = distinct([for k, v in local.scheduled_task_map : local.ecs_service_task_resources[local.scheduled_task_ecs_service_key[k]].task_definition_arn])
    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = [module.ecs_cluster.arn]
    }
  }

  statement {
    sid    = "AllowPassTaskRoles"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = length(local.scheduler_passrole_arns) > 0 ? local.scheduler_passrole_arns : ["*"]
  }
}

resource "aws_iam_role" "scheduler" {
  count = length(local.scheduled_task_map) > 0 ? 1 : 0

  name               = "${module.context.id}-scheduler-role"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume_role[0].json
  tags               = local.tags
}

resource "aws_iam_role_policy" "scheduler_run_task" {
  count = length(local.scheduled_task_map) > 0 ? 1 : 0

  name   = "${module.context.id}-scheduler-run-task"
  role   = aws_iam_role.scheduler[0].id
  policy = data.aws_iam_policy_document.scheduler_run_task[0].json
}

resource "aws_cloudwatch_event_rule" "ecs_scheduled_task" {
  for_each = local.scheduled_task_map

  name                = "${each.value.identifier}-schedule"
  schedule_expression = each.value.scheduled.schedule_expression
  state               = each.value.scheduled.enabled ? "ENABLED" : "DISABLED"

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "ecs_scheduled_task" {
  for_each = local.scheduled_task_map

  target_id = each.key
  rule      = aws_cloudwatch_event_rule.ecs_scheduled_task[each.key].name
  arn       = module.ecs_cluster.arn
  role_arn  = aws_iam_role.scheduler[0].arn
  input     = local.scheduled_task_inputs[each.key]

  ecs_target {
    task_definition_arn = local.ecs_service_task_resources[local.scheduled_task_ecs_service_key[each.key]].task_definition_arn
    launch_type         = "FARGATE"
    platform_version    = each.value.scheduled.platform_version
    task_count          = each.value.scheduled.task_count

    network_configuration {
      subnets = coalesce(each.value.scheduled.subnet_ids, each.value.subnet_ids, var.private_subnets)
      security_groups = coalesce(
        each.value.scheduled.security_group_ids,
        compact([local.ecs_service_task_resources[local.scheduled_task_ecs_service_key[each.key]].security_group_id])
      )
      assign_public_ip = each.value.scheduled.assign_public_ip
    }
  }

  retry_policy {
    maximum_retry_attempts       = each.value.scheduled.maximum_retry_attempts
    maximum_event_age_in_seconds = each.value.scheduled.maximum_event_age_in_seconds
  }

  depends_on = [
    module.ecs_service,
    module.ecs_service_multiples
  ]

  lifecycle {
    precondition {
      condition     = contains(keys(local.ecs_service_task_resources), local.scheduled_task_ecs_service_key[each.key])
      error_message = "Scheduled task ${each.key}: set scheduled.reuse_task_definition_key to a key from this list: ${local.ecs_service_task_resource_keys_hint} — or pass the service full identifier string (see main.tf `identifier` on ecs_map entries)."
    }
  }
}
