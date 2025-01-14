data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# data "aws_kms_key" "by_alias" {
#   key_id = "alias/aws/secretsmanager"
# }

locals {
  cluster_name = module.context.id

  default_settings = {
    container_insights                     = "disabled"
    fargate_weight                         = 0
    fargate_spot_weight                    = 100
    fluentbit_cpu                          = 128
    fluentbit_memory                       = 256
    container_cpu                          = 512
    container_memory                       = 1024
    container_port                         = 8080
    cloudwatch_log_group_retention_in_days = 3
    enable_autoscaling                     = false
    create_alb                             = false
    external_alb                           = false
    create_nlb                             = false
    create_eip                             = false
    multiple_ports                         = false
    health_check_path                      = "/"
    healthy_threshold                      = 5
    health_check_port                      = null
    desired_count                          = 1
    wildcard_domain                        = true
    domain_name                            = ""
    health_check_start_period              = null
    health_check_grace_period_seconds      = null
    environment = [
      {
        name  = "ECS_CLUSTER_NAME"
        value = local.cluster_name
      }
    ]
    secrets               = []
    multiple_containers   = false
    container_definitions = {}
    repository_credentials = {
      credentialsParameter = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.org_name}-${var.stage_name}/github_token"
    }
    task_exec_secret_arns = [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.org_name}-${var.stage_name}/*"
    ]
    tasks_iam_role_statements = {}
    # tasks_iam_role_statements = {
    #   "kms_decrypt" = {
    #     actions = [
    #       "secretsmanager:GetSecretValue"
    #     ]
    #     resources = [
    #       "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.org_name}-${var.stage_name}/*"
    #     ]
    #   }
    # }
    security_group_rules = {}
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        container_insights                     = "enabled"
        fargate_weight                         = 50
        fargate_spot_weight                    = 50
        fluentbit_cpu                          = 256
        fluentbit_memory                       = 512
        container_cpu                          = 1024
        container_memory                       = 1536
        cloudwatch_log_group_retention_in_days = 14
        enable_autoscaling                     = false
        desired_count                          = 2
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  ecs_map = {
    for k, v in var.ecs_services : k => {
      "identifier"       = "${module.context.id}-${k}"
      "create"           = coalesce(lookup(v, "create", null), true)
      "desired_count"    = try(coalesce(lookup(v, "desired_count", null), local.merged_default_settings.desired_count), local.merged_default_settings.desired_count)
      "fluentbit_cpu"    = try(coalesce(lookup(v, "fluentbit_cpu", null), local.merged_default_settings.fluentbit_cpu), local.merged_default_settings.fluentbit_cpu)
      "fluentbit_memory" = try(coalesce(lookup(v, "fluentbit_memory", null), local.merged_default_settings.fluentbit_memory), local.merged_default_settings.fluentbit_memory)
      "container_image"  = v.container_image
      "container_cpu"    = try(coalesce(lookup(v, "container_cpu", null), local.merged_default_settings.container_cpu), local.merged_default_settings.container_cpu)
      "container_memory" = try(coalesce(lookup(v, "container_memory", null), local.merged_default_settings.container_memory), local.merged_default_settings.container_memory)
      # "memory_reservation"                     = try(coalesce(lookup(v, "memory_reservation", null), local.merged_default_settings.memory_reservation), local.merged_default_settings.memory_reservation)
      "container_port"                         = try(coalesce(lookup(v, "container_port", null), local.merged_default_settings.container_port), local.merged_default_settings.container_port)
      "cloudwatch_log_group_retention_in_days" = try(coalesce(lookup(v, "cloudwatch_log_group_retention_in_days", null), local.merged_default_settings.cloudwatch_log_group_retention_in_days), local.merged_default_settings.cloudwatch_log_group_retention_in_days)
      "enable_autoscaling"                     = try(coalesce(lookup(v, "enable_autoscaling", null), local.merged_default_settings.enable_autoscaling), local.merged_default_settings.enable_autoscaling)
      "create_alb"                             = try(coalesce(lookup(v, "create_alb", null), local.merged_default_settings.create_alb), local.merged_default_settings.create_alb)
      "external_alb"                           = try(coalesce(lookup(v, "external_alb", null), local.merged_default_settings.external_alb), local.merged_default_settings.external_alb)
      "create_nlb"                             = try(coalesce(lookup(v, "create_nlb", null), local.merged_default_settings.create_nlb), local.merged_default_settings.create_nlb)
      "create_eip"                             = try(coalesce(lookup(v, "create_eip", null), local.merged_default_settings.create_eip), local.merged_default_settings.create_eip)
      "multiple_ports"                         = try(coalesce(lookup(v, "multiple_ports", null), local.merged_default_settings.multiple_ports), local.merged_default_settings.multiple_ports)
      "health_check_port"                      = try(coalesce(lookup(v, "health_check_port", null), local.merged_default_settings.health_check_port), local.merged_default_settings.health_check_port)
      "health_check_path"                      = try(coalesce(lookup(v, "health_check_path", null), local.merged_default_settings.health_check_path), local.merged_default_settings.health_check_path)
      "healthy_threshold"                      = try(coalesce(lookup(v, "healthy_threshold", null), local.merged_default_settings.healthy_threshold), local.merged_default_settings.healthy_threshold)
      "environment"                            = distinct(concat(try(coalesce(lookup(v, "environment", null), local.merged_default_settings.environment), local.merged_default_settings.environment), local.merged_default_settings.environment))
      "secrets"                                = distinct(concat(try(coalesce(lookup(v, "secrets", null), local.merged_default_settings.secrets), local.merged_default_settings.secrets), local.merged_default_settings.secrets))
      "tasks_iam_role_statements"              = merge(coalesce(lookup(v, "tasks_iam_role_statements", {}), {}), local.merged_default_settings.tasks_iam_role_statements)
      "wildcard_domain"                        = try(coalesce(lookup(v, "wildcard_domain", null), local.merged_default_settings.wildcard_domain), local.merged_default_settings.wildcard_domain)
      "domain_name"                            = try(coalesce(lookup(v, "domain_name", null), local.merged_default_settings.domain_name), local.merged_default_settings.domain_name)
      "task_exec_secret_arns"                  = try(coalesce(lookup(v, "task_exec_secret_arns", null), local.merged_default_settings.task_exec_secret_arns), local.merged_default_settings.task_exec_secret_arns)
      "security_group_rules"                   = merge(coalesce(lookup(v, "security_group_rules", {}), {}), local.merged_default_settings.security_group_rules)
      "repository_credentials"                 = try(coalesce(lookup(v, "repository_credentials", null), local.merged_default_settings.repository_credentials), local.merged_default_settings.repository_credentials)
      "container_name"                         = lookup(v, "container_name", null)
      "multiple_containers"                    = try(coalesce(lookup(v, "multiple_containers", null), local.merged_default_settings.multiple_containers), local.merged_default_settings.multiple_containers)
      "container_definitions"                  = merge(coalesce(lookup(v, "container_definitions", {}), {}), local.merged_default_settings.container_definitions)
      "health_check_start_period"              = try(coalesce(lookup(v, "health_check_start_period", null), local.merged_default_settings.health_check_start_period), local.merged_default_settings.health_check_start_period)
      "health_check_grace_period_seconds"      = try(coalesce(lookup(v, "health_check_grace_period_seconds", null), local.merged_default_settings.health_check_grace_period_seconds), local.merged_default_settings.health_check_grace_period_seconds)
    }
  }
}

module "ecs_cluster" {
  source       = "github.com/terraform-aws-modules/terraform-aws-ecs.git//modules/cluster?ref=v5.5.0"
  cluster_name = local.cluster_name
  cluster_settings = {
    name  = "containerInsights"
    value = local.merged_default_settings.container_insights
  }
  cloudwatch_log_group_retention_in_days = local.merged_default_settings.cloudwatch_log_group_retention_in_days
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = local.merged_default_settings.fargate_weight
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = local.merged_default_settings.fargate_spot_weight
      }
    }
  }
  tags = local.tags
}

data "external" "current_image" {
  for_each = { for k, v in local.ecs_map : k => v if v.create && v.container_image == null }
  program  = ["bash", "${path.module}/scripts/ecs_task.sh", each.value.identifier, data.aws_region.current.name]
}

locals {
  secret_vars_map = merge([
    for k, v in local.ecs_map : { for s in v.secrets : "${k}|${s.name}" => {
      name        = s.name
      secret_path = s.secret_path
      secret_key  = s.secret_key
      }
    }
  ]...)
}

data "aws_secretsmanager_secret" "secret" {
  for_each = local.secret_vars_map
  name     = each.value.secret_path
}

locals {
  secrets_output = {
    for k, v in local.ecs_map : k => [
      for s in v.secrets : {
        name      = s.name
        valueFrom = "${data.aws_secretsmanager_secret.secret["${k}|${s.name}"].arn}:${s.secret_key}::"
      } if v.secrets != null && length(v.secrets) > 0
    ]
  }
}

# output "test" {
#   value = local.secrets_output
# }

module "ecs_service" {
  source                            = "github.com/terraform-aws-modules/terraform-aws-ecs.git//modules/service?ref=v5.5.0"
  for_each                          = { for k, v in local.ecs_map : k => v if v.create && !v.multiple_containers }
  name                              = each.value.identifier
  desired_count                     = each.value.desired_count
  autoscaling_min_capacity          = each.value.enable_autoscaling ? each.value.desired_count : 1
  cluster_arn                       = module.ecs_cluster.arn
  cpu                               = max(ceil(each.value.container_cpu / 256) * 256, 256)
  memory                            = max(ceil(each.value.container_memory / 512) * 512, 512)
  enable_autoscaling                = each.value.enable_autoscaling
  enable_execute_command            = true
  task_exec_secret_arns             = each.value.task_exec_secret_arns
  task_exec_ssm_param_arns          = []
  health_check_grace_period_seconds = each.value.health_check_grace_period_seconds
  container_definitions =  {
    (each.key) = {
      essential              = true
      cpu                    = max(ceil(each.value.container_cpu / 256) * 256, 256)
      memory                 = max(ceil(each.value.container_memory / 512) * 512, 512)
      memory_reservation     = max(ceil(each.value.container_memory / 512) * 512, 512) / 2
      image                  = each.value.container_image == null ? data.external.current_image[each.key].result["IMAGE_NAME"] : each.value.container_image
      repository_credentials = each.value.container_image != null && strcontains(coalesce(each.value.container_image, "null_value"), "ecr.${data.aws_region.current.name}.amazonaws.com") ? {} : each.value.repository_credentials
      health_check = {
        "command"     = ["CMD-SHELL", "curl -f http://localhost:${each.value.health_check_port == null ? each.value.container_port : each.value.health_check_port}${each.value.health_check_path} || exit 1"]
        "interval"    = 30
        "timeout"     = 5
        "retries"     = 3
        "startPeriod" = each.value.health_check_start_period
      }
      readonly_root_filesystem = false
      # interactive        = true
      # pseudo_terminal    = true
      environment = each.value.environment
      secrets     = lookup(local.secrets_output, each.key, null)
      port_mappings = each.value.multiple_ports ? [
        {
          protocol      = "tcp"
          containerPort = 80
          hostPort      = 80
        },
        {
          protocol      = "tcp"
          containerPort = 443
          hostPort      = 443
        }
        ] : [
        {
          protocol      = "tcp"
          containerPort = each.value.container_port
          hostPort      = each.value.container_port
        }
      ]
      systemControls                         = []
      enable_cloudwatch_logging              = true
      create_cloudwatch_log_group            = true
      cloudwatch_log_group_retention_in_days = each.value.cloudwatch_log_group_retention_in_days
      # dependencies = [{
      #   containerName = "fluent-bit"
      #   condition     = "START"
      # }]
    }
    # fluent-bit = {
    #   essential          = true
    #   image              = "906394416424.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/aws-for-fluent-bit:stable"
    #   cpu                = each.value.fluentbit_cpu
    #   memory             = each.value.fluentbit_memory
    #   memory_reservation = 128
    #   readonly_root_filesystem = false
    #   user               = "0"
    #   firelens_configuration = {
    #     type = "fluentbit"
    #     options = {
    #       "enable-ecs-log-metadata" = "true"
    #     }
    #   }
    # log_configuration = {
    #   logDriver = "awslogs"
    #   options = {
    #     "awslogs-group"         = "/aws/ecs/${each.value.identifier}/fluent-bit"
    #     "awslogs-region"        = data.aws_region.current.name
    #     "awslogs-create-group"  = "true"
    #     "awslogs-stream-prefix" = "ecs"
    #   }
    # }
    # }
  }

  load_balancer = each.value.create_alb ? (each.value.external_alb ?
    {
      external_alb = {
        target_group_arn = module.alb[each.key].target_groups[each.value.identifier].arn
        container_name   = each.key
        container_port   = each.value.container_port
      }
      internal_alb = {
        target_group_arn = module.alb_internal.target_groups[each.value.identifier].arn
        container_name   = each.key
        container_port   = each.value.container_port
      }
      } : {
      internal_alb = {
        target_group_arn = module.alb_internal.target_groups[each.value.identifier].arn
        container_name   = each.key
        container_port   = each.value.container_port
      }
      }) : (each.value.create_nlb ? (each.value.multiple_ports ?
      {
        service_80 = {
          target_group_arn = module.nlb[each.key].target_groups["${each.value.identifier}-80"].arn
          container_name   = each.key
          container_port   = 80
        }
        service_443 = {
          target_group_arn = module.nlb[each.key].target_groups["${each.value.identifier}-443"].arn
          container_name   = each.key
          container_port   = 443
        }
        } : {
        service = {
          target_group_arn = module.nlb[each.key].target_groups[each.value.identifier].arn
          container_name   = each.key
          container_port   = each.value.container_port
        }
  }) : {})
  tasks_iam_role_name        = "${each.value.identifier}-taskrole"
  tasks_iam_role_description = "Tasks IAM role for ${each.value.identifier}"
  # tasks_iam_role_policies = {
  #   ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  # }
  tasks_iam_role_statements = each.value.tasks_iam_role_statements
  # tasks_iam_role_statements = { 
  #   for k, v in each.value.tasks_iam_role_statements: k => {
  #     resources = v.resources
  #     actions   = v.actions
  #     conditions = v.conditions != null ? v.conditions : []
  #   }
  # }
  subnet_ids = var.private_subnets
  security_group_rules = merge({
    "ingress_${each.value.container_port}" = {
      type        = "ingress"
      from_port   = each.value.container_port
      to_port     = each.value.container_port
      protocol    = "tcp"
      description = "ECS Container Service port"
      cidr_blocks = [var.vpc_cidr]
    },
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }, each.value.security_group_rules)
  tags = local.tags
}

module "ecs_service_multiples" {
  source                            = "github.com/terraform-aws-modules/terraform-aws-ecs.git//modules/service?ref=v5.12.0"
  for_each                          = { for k, v in local.ecs_map : k => v if v.create && v.multiple_containers }
  name                              = each.value.identifier
  desired_count                     = each.value.desired_count
  autoscaling_min_capacity          = each.value.enable_autoscaling ? each.value.desired_count : 1
  cluster_arn                       = module.ecs_cluster.arn
  cpu                               = max(ceil(each.value.container_cpu / 256) * 256, 256)
  memory                            = max(ceil(each.value.container_memory / 512) * 512, 512)
  enable_autoscaling                = each.value.enable_autoscaling
  enable_execute_command            = true
  task_exec_secret_arns             = each.value.task_exec_secret_arns
  task_exec_ssm_param_arns          = []
  health_check_grace_period_seconds = each.value.health_check_grace_period_seconds
  container_definitions =  each.value.container_definitions

  load_balancer = each.value.create_alb ? (each.value.external_alb ?
    {
      external_alb = {
        target_group_arn = module.alb[each.key].target_groups[each.value.identifier].arn
        container_name   = lookup(each.value, "container_name", each.key)
        container_port   = each.value.container_port
      }
      internal_alb = {
        target_group_arn = module.alb_internal.target_groups[each.value.identifier].arn
        container_name   = lookup(each.value, "container_name", each.key)
        container_port   = each.value.container_port
      }
      } : {
      internal_alb = {
        target_group_arn = module.alb_internal.target_groups[each.value.identifier].arn
        container_name   = lookup(each.value, "container_name", each.key)
        container_port   = each.value.container_port
      }
      }) : (each.value.create_nlb ? (each.value.multiple_ports ?
      {
        service_80 = {
          target_group_arn = module.nlb[each.key].target_groups["${each.value.identifier}-80"].arn
          container_name   = lookup(each.value, "container_name", each.key)
          container_port   = 80
        }
        service_443 = {
          target_group_arn = module.nlb[each.key].target_groups["${each.value.identifier}-443"].arn
          container_name   = lookup(each.value, "container_name", each.key)
          container_port   = 443
        }
        } : {
        service = {
          target_group_arn = module.nlb[each.key].target_groups[each.value.identifier].arn
          container_name   = lookup(each.value, "container_name", each.key)
          container_port   = each.value.container_port
        }
  }) : {})

  tasks_iam_role_name        = "${each.value.identifier}-taskrole"
  tasks_iam_role_description = "Tasks IAM role for ${each.value.identifier}"
  # tasks_iam_role_policies = {
  #   ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  # }
  tasks_iam_role_statements = each.value.tasks_iam_role_statements
  # tasks_iam_role_statements = { 
  #   for k, v in each.value.tasks_iam_role_statements: k => {
  #     resources = v.resources
  #     actions   = v.actions
  #     conditions = v.conditions != null ? v.conditions : []
  #   }
  # }
  subnet_ids = var.private_subnets
  security_group_rules = merge({
    "ingress_${each.value.container_port}" = {
      type        = "ingress"
      from_port   = each.value.container_port
      to_port     = each.value.container_port
      protocol    = "tcp"
      description = "ECS Container Service port"
      cidr_blocks = [var.vpc_cidr]
    },
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }, each.value.security_group_rules)
  tags = local.tags
}
