variable "domain_names" {
  type = list(string)
}

variable "enable_dynamodb_cache" {
  type    = bool
  default = true
}

variable "wildcard_domain" {
  type    = bool
  default = true
}

variable "server_environment_variables" {
  type    = map(string)
  default = {}
}

variable "policy_statements" {
  type = map(object({
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = {}
}

variable "server_cloudwatch_log_retention_in_days" {
  type    = number
  default = null
}

variable "server_memory_size" {
  type    = number
  default = null
}

variable "schedule_expression" {
  type    = string
  default = null
}