
variable "canary" {
  type = map(object({
    create                    = optional(bool)
    enable_notification       = optional(bool)
    runtime_version           = optional(string)
    handler                   = optional(string)
    take_screenshot           = optional(bool)
    url                       = optional(string)
    schedule_expression       = optional(string)
    period_in_seconds         = optional(number)
    timeout_in_seconds        = optional(number)
    memory_in_mb              = optional(number)
    success_retention_period  = optional(number)
    failure_retention_period  = optional(number)
    threshold_success_percent = optional(number)
  }))
  default = {}
}

variable "sns_topic_cloudwatch_alarm_arn" {
  type        = string
  description = "The SNS topic to notify when canary fails"
  default     = ""
}