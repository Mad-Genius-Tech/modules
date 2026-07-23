

output "alb_dns_name" {
  value = {
    for k, v in module.alb : k => {
      dns_name = v.dns_name
    }
  }
}

output "alb_internal_dns_name" {
  value = module.alb_internal.dns_name

  precondition {
    condition     = !local.internal_alb_host_routing_configured || var.create_internal_alb
    error_message = "create_internal_alb must be true when internal ALB host routing is configured."
  }

  precondition {
    condition     = !local.internal_alb_host_routing_configured || length(var.internal_alb_certificate_domains) > 0
    error_message = "internal_alb_certificate_domains must contain at least one domain when internal ALB host routing is configured."
  }
}

output "alb_internal_dedicated_dns_name" {
  value = {
    for k, v in module.alb_internal_dedicated : k => {
      dns_name = v.dns_name
    }
  }
}

output "nlb_dns_name" {
  value = {
    for k, v in module.nlb : k => {
      dns_name = v.dns_name
    }
  }
}

output "ecs_cluster_id" {
  value = module.ecs_cluster.id
}

output "ecs_cluster_arn" {
  value = module.ecs_cluster.arn
}

output "ecs_map" {
  # Preserve the legacy diagnostic output shape for consumers that do not use
  # shared host routing. This routing-only field is consumed inside the module.
  value = {
    for service_key, service in local.ecs_map : service_key => {
      for attribute, attribute_value in service : attribute => attribute_value
      if attribute != "internal_alb_hostnames"
    }
  }
}

output "ecs_services" {
  value = {
    for k, v in module.ecs_service : k => {
      service_id              = v.id
      service_name            = v.name
      task_exec_iam_role_name = v.task_exec_iam_role_name
      task_exec_iam_role_arn  = v.task_exec_iam_role_arn
      task_set_id             = v.task_set_id
      # container_definitions = v.container_definitions
    } if local.ecs_map[k].type == "service"
  }
}

output "ecs_scheduled_tasks" {
  value = {
    for k, v in aws_scheduler_schedule.ecs_scheduled_task : k => {
      schedule_arn                 = v.arn
      schedule_name                = v.name
      schedule_expression          = v.schedule_expression
      schedule_expression_timezone = v.schedule_expression_timezone
      schedule_group_name          = aws_scheduler_schedule_group.scheduled_task[k].name
      schedule_group_arn           = aws_scheduler_schedule_group.scheduled_task[k].arn
      enabled                      = local.scheduled_task_map[k].scheduled.enabled
      task_definition_arn          = local.ecs_service_task_resources[local.scheduled_task_ecs_service_key[k]].task_definition_arn
      task_definition_family       = local.ecs_service_task_resources[local.scheduled_task_ecs_service_key[k]].task_definition_family
      task_exec_iam_role_name      = local.ecs_service_task_resources[local.scheduled_task_ecs_service_key[k]].task_exec_iam_role_name
      task_exec_iam_role_arn       = local.ecs_service_task_resources[local.scheduled_task_ecs_service_key[k]].task_exec_iam_role_arn
      task_exec_secret_arns        = try(local.scheduled_task_exec_secret_arns[local.scheduled_task_ecs_service_key[k]], [])
      task_runtime_iam_role_name   = local.ecs_service_task_resources[local.scheduled_task_ecs_service_key[k]].tasks_iam_role_name
      task_runtime_iam_role_arn    = local.ecs_service_task_resources[local.scheduled_task_ecs_service_key[k]].tasks_iam_role_arn
      scheduler_iam_role_name      = aws_iam_role.scheduler[k].name
      scheduler_iam_role_arn       = aws_iam_role.scheduler[k].arn
      dead_letter_queue_arn        = local.scheduled_task_dlq_arn[k]
      container_name               = local.scheduled_task_container_override_name[k]
      cloudwatch_log_group_name    = "/aws/ecs/${local.scheduled_task_map[k].identifier}/${local.scheduled_task_container_override_name[k]}"
      observability_alarm_arns = try(local.scheduled_task_map[k].scheduled.observability.enabled, false) ? {
        scheduler_launch_failure = aws_cloudwatch_metric_alarm.scheduled_task_launch_failure[k].arn
        task_nonzero_exit        = aws_cloudwatch_metric_alarm.scheduled_task_nonzero_exit[k].arn
        success_freshness        = aws_cloudwatch_metric_alarm.scheduled_task_freshness[k].arn
      } : null
    }
  }
}

# output "ecs" {
#   value = var.ecs_services
# }
