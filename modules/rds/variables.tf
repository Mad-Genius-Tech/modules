variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(any)
}

variable "ingress_security_group_id" {
  type    = string
  default = ""
}

variable "ingress_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "rds" {
  type = map(object({
    create                  = optional(bool)
    engine_version          = string
    instance_class          = string
    allocated_storage       = optional(number)
    max_allocated_storage   = optional(number)
    db_name                 = optional(string)
    username                = optional(string)
    port                    = optional(number)
    multi_az                = optional(bool)
    lambda_functions        = optional(list(string))
    apply_immediately       = optional(bool)
    secret_rotation_enabled = optional(bool)
    parameters = optional(list(object({
      name         = string
      value        = string
      apply_method = optional(string)
    })))
    options = optional(list(object({
      option_name = string
      option_settings = list(object({
        name  = string
        value = string
      }))
    })))
    enable_cloudwatch_alarm = optional(bool)
    alarms = optional(map(object({
      metric_name             = string
      comparison_operator     = optional(string)
      dimensions              = optional(map(string), {})
      threshold               = number
      evaluation_periods      = number
      period                  = number
      statistic               = optional(string)
      namespace               = optional(string)
      cloudwatch_alarm_action = optional(string)
    })))
  }))
}

variable "enable_secret_manager" {
  type    = bool
  default = true
}

variable "sns_topic_arn" {
  type    = string
  default = ""
}