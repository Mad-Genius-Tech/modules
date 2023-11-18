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

variable "ecs_services" {
  type = map(object({
    container_image = optional(string)
    repository_credentials = optional(object({
      credentialsParameter = string
    }))
    create                                 = optional(bool)
    desired_count                          = optional(number)
    fluentbit_cpu                          = optional(number)
    fluentbit_memory                       = optional(number)
    container_cpu                          = optional(number)
    container_memory                       = optional(number)
    memory_reservation                     = optional(number)
    container_port                         = optional(number)
    cloudwatch_log_group_retention_in_days = optional(number)
    enable_autoscaling                     = optional(bool)
    create_alb                             = optional(bool)
    external_alb                           = optional(bool)
    create_nlb                             = optional(bool)
    create_eip                             = optional(bool)
    multiple_ports                         = optional(bool)
    health_check_port                      = optional(number)
    health_check_path                      = optional(string)
    wildcard_domain                        = optional(bool)
    domain_name                            = optional(string)
    task_exec_secret_arns                  = optional(list(string))
    health_check_start_period              = optional(number)
    environment = optional(list(object({
      name  = string
      value = string
    })))
    secrets = optional(list(object({
      name      = string
      valueFrom = string
    })))
    security_group_rules = optional(map(object({
      type        = string
      from_port   = number
      to_port     = number
      protocol    = string
      description = optional(string)
      cidr_blocks = list(string)
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
