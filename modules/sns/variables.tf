variable "create" {
  type    = bool
  default = true
}

variable "sns_email_subscriptions" {
  type    = list(string)
  default = []
}

variable "discord_webhook_url" {
  type    = string
  default = ""
}
