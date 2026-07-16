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
