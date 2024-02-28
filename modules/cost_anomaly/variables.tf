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

variable "raise_amount_absolute" {
  type    = number
  default = 50
}

variable "raise_amount_percentage" {
  type    = number
  default = 10
}