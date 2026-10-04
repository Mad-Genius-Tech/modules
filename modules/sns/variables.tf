variable "create" {
  type    = bool
  default = true
}

variable "sns_email_subscriptions" {
  type    = list(string)
  default = []

  validation {
    condition = length([
      for endpoint in var.sns_email_subscriptions : lower(trimspace(endpoint))
      if trimspace(endpoint) != ""
      ]) == length(distinct([
        for endpoint in var.sns_email_subscriptions : lower(trimspace(endpoint))
        if trimspace(endpoint) != ""
    ]))
    error_message = "sns_email_subscriptions must contain unique email addresses, ignoring case and surrounding whitespace."
  }
}

variable "webhook_url" {
  type    = string
  default = ""
}

variable "sns_email_message_body_filter_policy" {
  description = "Optional SNS message-body filter policy as a JSON object for email subscriptions. Null preserves unfiltered email delivery."
  type        = string
  default     = null

  validation {
    condition     = var.sns_email_message_body_filter_policy == null || can(keys(jsondecode(var.sns_email_message_body_filter_policy)))
    error_message = "sns_email_message_body_filter_policy must be null or a JSON object."
  }
}
