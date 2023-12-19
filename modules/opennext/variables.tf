variable "domain_names" {
  type = list(string)
}

variable "enable_dynamodb_cache" {
  type    = bool
  default = false
}

variable "wildcard_domain" {
  type    = bool
  default = true
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}