variable "create" {
  type    = bool
  default = true
}

variable "image_uri" {
  type    = string
  default = ""
}

variable "timeout" {
  type    = number
  default = null
}

variable "keep_warm" {
  type    = bool
  default = true
}

variable "keep_warm_expression" {
  type    = string
  default = "rate(5 minutes)"
}

variable "memory_size" {
  type    = number
  default = 1024
}

variable "ephemeral_storage_size" {
  type    = number
  default = 1024
}

variable "environment_variables" {
  type    = map(string)
  default = {}
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

variable "secret_vars" {
  type = map(object({
    secret_path = string
    property    = string
  }))
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

variable "vpc_id" {
  type    = string
  default = ""
}

variable "subnet_ids" {
  type    = list(any)
  default = []
}