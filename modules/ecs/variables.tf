variable "private_subnets" {
  type = list(string)
}

variable "ingress_cidr_blocks" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "create_internal_alb" {
  type    = bool
  default = true
}

variable "internal_alb_certificate_domains" {
  description = "Ordered ACM certificate domains for shared internal ALB HTTPS; the first is the default and the rest are SNI certificates."
  type        = list(string)
  default     = []

  validation {
    condition = (
      length(var.internal_alb_certificate_domains) == length(distinct([
        for domain in var.internal_alb_certificate_domains : lower(trimspace(domain))
      ])) &&
      alltrue([
        for domain in var.internal_alb_certificate_domains : trimspace(domain) != ""
      ])
    )
    error_message = "internal_alb_certificate_domains must contain unique, non-empty domain names."
  }
}

variable "create_certmagic_table" {
  type    = bool
  default = false
}

variable "service_discovery_dns_name" {
  type    = string
  default = ""
}

variable "container_insights" {
  type    = string
  default = ""
}

variable "ecs_services" {
  type = map(object({
    type                           = optional(string, "service")
    container_image                = optional(string)
    require_repository_credentials = optional(bool)
    repository_credentials = optional(object({
      credentialsParameter = string
    }))
    create                                 = optional(bool)
    enable_service_discovery               = optional(bool)
    enable_execute_command                 = optional(bool, true)
    readonly_root_filesystem               = optional(bool, false)
    desired_count                          = optional(number)
    cpu_architecture                       = optional(string)
    fluentbit_cpu                          = optional(number)
    fluentbit_memory                       = optional(number)
    container_cpu                          = optional(number)
    container_memory                       = optional(number)
    memory_reservation                     = optional(number)
    container_port                         = optional(number)
    cloudwatch_log_group_retention_in_days = optional(number)
    availability_zone_rebalancing          = optional(string)
    enable_autoscaling                     = optional(bool)
    create_alb                             = optional(bool)
    external_alb                           = optional(bool)
    dedicated_internal_alb                 = optional(bool)
    internal_alb_hostnames                 = optional(list(string), [])
    create_nlb                             = optional(bool)
    create_eip                             = optional(bool)
    multiple_ports                         = optional(bool)
    health_check_port                      = optional(number)
    health_check_path                      = optional(string)
    healthy_threshold                      = optional(number)
    health_check_unhealthy_threshold       = optional(number)
    health_check_interval                  = optional(number)
    health_check_matcher                   = optional(string)
    wildcard_domain                        = optional(bool)
    domain_name                            = optional(string)
    task_exec_secret_arns                  = optional(list(string))
    health_check_command                   = optional(list(string))
    health_check_start_period              = optional(number)
    command                                = optional(list(string))
    entry_point                            = optional(list(string))
    health_check_grace_period_seconds      = optional(number)
    multiple_containers                    = optional(bool)
    subnet_ids                             = optional(list(string))
    user                                   = optional(string)
    deployment_minimum_healthy_percent     = optional(number)
    deployment_maximum_percent             = optional(number)
    capacity_provider_strategy = optional(map(object({
      base              = optional(number)
      capacity_provider = string
      weight            = optional(number)
    })))
    autoscaling_max_capacity = optional(number)
    autoscaling_scheduled_actions = optional(map(object({
      name         = optional(string)
      min_capacity = number
      max_capacity = number
      schedule     = string
      start_time   = optional(string)
      end_time     = optional(string)
      timezone     = optional(string)
    })))
    volume = optional(map(object({
      name      = string
      host_path = optional(string)
      efs_volume_configuration = optional(object({
        file_system_id          = string
        root_directory          = optional(string, "/")
        transit_encryption      = optional(string, "ENABLED")
        transit_encryption_port = optional(number, 2999)
        authorization_config = optional(object({
          access_point_id = optional(string)
          iam             = optional(string, "DISABLED")
        }))
      }))
    })))
    mount_points = optional(list(object({
      sourceVolume  = string
      containerPath = string
      readOnly      = optional(bool, false)
    })), [])
    environment = optional(list(object({
      name  = string
      value = string
    })))
    secrets = optional(list(object({
      name        = string
      secret_path = string
      secret_key  = string
    })))
    security_group_rules = optional(map(object({
      from_port   = number
      to_port     = number
      ip_protocol = optional(string, "tcp")
      description = optional(string)
      cidr_ipv4   = string
    })))
    container_name = optional(string)
    container_definitions = optional(map(object({
      essential         = bool
      cpu               = number
      memory            = number
      memoryReservation = optional(number)
      image             = optional(string)
      repositoryCredentials = optional(object({
        credentialsParameter = string
      }))
      startTimeout = optional(number)
      stopTimeout  = optional(number)
      healthCheck = optional(object({
        command     = list(string)
        interval    = number
        timeout     = number
        retries     = number
        startPeriod = number
      }), null)
      environment = optional(list(object({
        name  = string
        value = string
      })))
      command = optional(list(string))
      portMappings = optional(list(object({
        containerPort = number
        hostPort      = number
        protocol      = string
      })))
      user = optional(string, "0")
      mount_points = optional(list(object({
        sourceVolume  = string
        containerPath = string
        readOnly      = optional(bool, false)
      })), [])
      readonlyRootFilesystem                 = optional(bool, false)
      enable_cloudwatch_logging              = optional(bool, true)
      create_cloudwatch_log_group            = optional(bool, true)
      cloudwatch_log_group_retention_in_days = optional(number)
      dependsOn = optional(list(object({
        containerName = string
        condition     = string
      })))
    })))
    tasks_iam_role_statements = optional(map(object({
      resources = list(string)
      actions   = list(string)
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    })))
    scheduled = optional(object({
      enabled                      = optional(bool, false)
      schedule_expression          = optional(string)
      schedule_expression_timezone = optional(string, "UTC")
      subnet_ids                   = optional(list(string))
      security_group_ids           = optional(list(string))
      assign_public_ip             = optional(bool, false)
      task_count                   = optional(number, 1)
      platform_version             = optional(string, "LATEST")
      maximum_retry_attempts       = optional(number, 0)
      maximum_event_age_in_seconds = optional(number, 300)
      command                      = optional(list(string))
      cpu                          = optional(number)
      memory                       = optional(number)
      # Source: exact `ecs_services` map key, or that service full `identifier` string (context-prefixed name in main.tf)
      reuse_task_definition_key = optional(string)
      # When the source is multiple_containers, which container in the task def to override (defaults: container_name, then first container_definitions key)
      reuse_container_name = optional(string)
    }))
  }))

  validation {
    condition = alltrue([
      for v in values(var.ecs_services) :
      contains(["service", "scheduled_task"], lower(v.type))
    ])
    error_message = "ecs_services.type must be either \"service\" or \"scheduled_task\"."
  }

  validation {
    condition = alltrue([
      for v in values(var.ecs_services) :
      lower(v.type) != "scheduled_task" || try(length(v.scheduled.schedule_expression) > 0, false)
    ])
    error_message = "ecs_services scheduled_task entries must set scheduled.schedule_expression."
  }

  validation {
    condition = alltrue([
      for v in values(var.ecs_services) :
      !(lower(v.type) == "scheduled_task" && coalesce(try(v.multiple_containers, null), false))
    ])
    error_message = "ecs_services scheduled_task entries do not support multiple_containers."
  }

  validation {
    condition = alltrue([
      for v in values(var.ecs_services) :
      length(v.internal_alb_hostnames) == 0 || (
        coalesce(v.create_alb, false) &&
        !coalesce(v.external_alb, false) &&
        lower(v.type) == "service" &&
        length(v.internal_alb_hostnames) <= 3 &&
        alltrue([for hostname in v.internal_alb_hostnames : trimspace(hostname) != ""])
      )
    ])
    error_message = "ecs_services.internal_alb_hostnames requires an internal ALB-backed service and may contain at most three non-empty hostnames."
  }

  validation {
    condition = length(flatten([
      for v in values(var.ecs_services) : [
        for hostname in v.internal_alb_hostnames : lower(trimspace(hostname))
      ]
      ])) == length(distinct(flatten([
        for v in values(var.ecs_services) : [
          for hostname in v.internal_alb_hostnames : lower(trimspace(hostname))
        ]
    ])))
    error_message = "ecs_services.internal_alb_hostnames must be globally unique (case-insensitive)."
  }

  validation {
    condition = !anytrue([
      for v in values(var.ecs_services) : length(v.internal_alb_hostnames) > 0
      ]) || alltrue([
      for v in values(var.ecs_services) :
      !coalesce(v.create_alb, false) ||
      (coalesce(v.dedicated_internal_alb, false) && !coalesce(v.external_alb, false)) ||
      length(v.internal_alb_hostnames) > 0 ||
      !contains([80, 443], coalesce(v.container_port, 8080))
    ])
    error_message = "Shared internal ALB host routing cannot coexist with a direct shared listener on port 80 or 443."
  }
}

variable "sns_topic_cloudwatch_alarm_arn" {
  type    = string
  default = ""
}

variable "high_reservation_alert" {
  type    = bool
  default = true
}

variable "low_reservation_alert" {
  type    = bool
  default = false
}
