
variable "apigateway" {
  type = map(object({
    create                      = optional(bool)
    enable_log                  = optional(bool)
    logging_level               = optional(string)
    create_log_group            = optional(bool)
    log_group_retention_in_days = optional(number)
    route_key = optional(map(object({
      lambda_function = string
    })))
  }))
}