variable "sns_topic_arn" {
  type = string
}

variable "raise_amount_absolute" {
  type    = number
  default = 50
}

variable "raise_amount_percentage" {
  type    = number
  default = 10
}