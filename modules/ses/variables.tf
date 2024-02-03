variable "ses_domain_name" {
  type    = string
  default = ""
}

variable "ses_emails" {
  type    = list(string)
  default = []
}

variable "contact_list_name" {
  type    = string
  default = ""
}

variable "contact_list_description" {
  type    = string
  default = null
}

variable "topic_name" {
  type    = string
  default = ""
}

variable "topic_display_name" {
  type    = string
  default = null
}

variable "topic_description" {
  type    = string
  default = null
}

variable "alarm_sns_topic_arn" {
  type    = string
  default = ""
}