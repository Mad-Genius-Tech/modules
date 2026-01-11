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
    container_image                = optional(string)
    require_repository_credentials = optional(bool)
    repository_credentials = optional(object({
      credentialsParameter = string
    }))
    create                                 = optional(bool)
    enable_service_discovery               = optional(bool)
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
    health_check_grace_period_seconds      = optional(number)
    multiple_containers                    = optional(bool)
    subnet_ids                             = optional(list(string))
    user                                   = optional(string)
    deployment_minimum_healthy_percent     = optional(number)
    deployment_maximum_percent             = optional(number)
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
  }))
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
