variable "sns_topic_arn" {
  type    = string
  default = ""
}

variable "notification_email" {
  type    = string
  default = ""
}

variable "cost_category" {
  type = object({
    name  = string
    value = string
  })
  default = null
}

variable "cost_anomaly" {
  type = object({
    raise_amount_absolute   = optional(number)
    raise_amount_percentage = optional(number)
  })
  default = {}
}

variable "overall_budget" {
  type = map(object({
    limit_amount               = optional(number)
    threshold_percentage       = optional(number)
    include_credit             = optional(bool)
    include_discount           = optional(bool)
    include_other_subscription = optional(bool)
    include_recurring          = optional(bool)
    include_refund             = optional(bool)
    include_subscription       = optional(bool)
    include_support            = optional(bool)
    include_tax                = optional(bool)
    include_upfront            = optional(bool)
    use_blended                = optional(bool)
  }))
  default = {}
}

variable "services_budget" {
  type = map(object({
    time_unit            = optional(string)
    limit_amount         = optional(number)
    threshold_percentage = optional(number)
  }))
  default = {}
}
