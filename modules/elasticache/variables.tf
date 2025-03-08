variable "vpc_id" {}

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

variable "redis" {
  type = map(object({
    create                     = optional(bool)
    node_type                  = optional(string)
    engine_version             = optional(string)
    transit_encryption_enabled = optional(bool)
    auth_token                 = optional(string)
    at_rest_encryption_enabled = optional(bool)
    multi_az_enabled           = optional(bool)
    automatic_failover_enabled = optional(bool)
    snapshot_retention_limit   = optional(number)
    num_cache_clusters         = optional(number)
    num_node_groups            = optional(number)
    replicas_per_node_group    = optional(number)
    auto_minor_version_upgrade = optional(bool)
    kms_key_id                 = optional(string)
    parameters = optional(map(object({
      name  = string
      value = string
    })))
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