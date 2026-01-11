variable "image_uri" {
  type    = string
  default = ""
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "domain_names" {
  type = list(string)
}

variable "wildcard_domain" {
  type    = bool
  default = true
}

variable "cors" {
  type = object({
    allow_origins     = optional(list(string))
    allow_methods     = optional(list(string))
    allow_headers     = optional(list(string))
    expose_headers    = optional(list(string))
    max_age_seconds   = optional(number)
    allow_credentials = optional(bool)
  })
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

variable "policies" {
  type    = list(string)
  default = []
}

variable "schedule_expression" {
  type    = string
  default = "rate(15 minutes)"
}

variable "secret_vars" {
  type = map(object({
    secret_path = optional(string)
    property    = optional(string)
  }))
  default = {}
}
