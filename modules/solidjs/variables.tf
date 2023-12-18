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
