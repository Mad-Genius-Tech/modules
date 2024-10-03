
variable "create" {
  type    = bool
  default = true
}

variable "step_function" {
  type = map(object({
    create                      = optional(bool)
    type                        = optional(string)
    definition                  = string
    publish                     = optional(bool)
    create_iam_role             = optional(bool)
    create_log_group            = optional(bool)
    log_group_retention_in_days = optional(number)
    logging_configuration       = optional(map(string))
    service_integrations        = optional(map(string))
  }))
}