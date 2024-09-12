
variable "apigateway" {
  type = map(object({
    create                      = optional(bool)
    enable_stage                = optional(bool)
    lambda_function             = string
    connection_type             = optional(string)
    enable_log                  = optional(bool)
    logging_level               = optional(string)
    create_log_group            = optional(bool)
    log_group_retention_in_days = optional(number)
  }))
}
