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

variable "environment_variables" {
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
