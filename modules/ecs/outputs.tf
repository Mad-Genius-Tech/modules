

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
    for k, v in aws_scheduler_schedule.ecs_task : k => {
      schedule_arn          = v.arn
      schedule_name         = v.name
      task_definition_arn   = module.ecs_service[k].task_definition_arn
      task_exec_iam_role    = module.ecs_service[k].task_exec_iam_role_arn
      task_runtime_iam_role = module.ecs_service[k].tasks_iam_role_arn
    }
  }
}

# output "ecs" {
#   value = var.ecs_services
# }