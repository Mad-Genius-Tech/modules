

output "alb_dns_name" {
  value = {
    for k, v in module.alb : k => {
      dns_name = v.dns_name
    }
  }
}

output "alb_internal_dns_name" {
  value = module.alb_internal.dns_name
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
  value = local.ecs_map
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
    for k, v in aws_cloudwatch_event_rule.ecs_scheduled_task : k => {
      schedule_arn          = v.arn
      schedule_name         = v.name
      schedule_expression   = v.schedule_expression
      event_target_id       = aws_cloudwatch_event_target.ecs_scheduled_task[k].target_id
      task_definition_arn   = local.ecs_service_task_resources[local.scheduled_task_ecs_service_key[k]].task_definition_arn
      task_exec_iam_role    = local.ecs_service_task_resources[local.scheduled_task_ecs_service_key[k]].task_exec_iam_role_arn
      task_runtime_iam_role = local.ecs_service_task_resources[local.scheduled_task_ecs_service_key[k]].tasks_iam_role_arn
    }
  }
}

# output "ecs" {
#   value = var.ecs_services
# }