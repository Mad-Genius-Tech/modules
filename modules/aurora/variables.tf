variable "vpc_id" {}

variable "subnet_ids" {
  type = list(any)
}

variable "ingress_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "security_group_rules" {
  type    = map(any)
  default = {}
}

variable "aurora" {
  type = map(object({
    create                       = optional(bool)
    version                      = optional(string)
    min_capacity                 = optional(number)
    max_capacity                 = optional(number)
    master_username              = optional(string)
    database_name                = optional(string)
    skip_final_snapshot          = optional(bool)
    backup_retention_period      = optional(number)
    performance_insights_enabled = optional(bool)
    monitoring_interval          = optional(number)
    instances                    = optional(map(any))
    instances_count              = optional(number)
    enable_proxy                 = optional(bool)
    enable_cloudwatch_alarm      = optional(bool)
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
  default = {}
}

variable "sns_topic_arn" {
  type    = string
  default = ""
}