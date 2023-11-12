

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

output "ecs_services" {
  value = {
    for k, v in module.ecs_service : k => {
      service_id             = v.id
      service_name           = v.name
      task_exec_iam_role_arn = v.task_exec_iam_role_arn
      task_set_id            = v.task_set_id
      # container_definitions = v.container_definitions
    }
  }
}