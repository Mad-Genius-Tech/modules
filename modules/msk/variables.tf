variable "vpc_id" {}

variable "private_subnet_ids" {
  type = list(string)
}

variable "aws_profile" {
  type = string
}

variable "msk" {
  description = "Map of MSK clusters to create"
  type = map(object({
    create                          = optional(bool, true)
    identifier                      = optional(string)
    kafka_version                   = optional(string)
    number_of_broker_nodes          = optional(number)
    enhanced_monitoring             = optional(string)
    broker_node_instance_type       = optional(string)
    broker_node_storage_volume_size = optional(number)
    storage_mode                    = optional(string)
    jmx_exporter_enabled            = optional(bool)
    node_exporter_enabled           = optional(bool)
    cloudwatch_logs_enabled         = optional(bool)
    s3_logs_enabled                 = optional(bool)
    create_scram_secret_association = optional(bool)
    msk_secrets = optional(map(object({
      description = optional(string)
      username    = optional(string)
      password    = optional(string)
      accesses = optional(list(object({
        mode                  = string # producer or consumer
        topics_prefix         = string
        consumer_group_prefix = string
      })))
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
      cluster_level_alarm     = optional(bool)
    })))
  }))
  default = {}
}

variable "sns_topic_arn" {
  type    = string
  default = ""
}