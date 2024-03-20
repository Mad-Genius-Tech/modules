variable "vpc_id" {
  type    = string
  default = ""
}

variable "subnet_ids" {
  type    = list(any)
  default = []
}

variable "lambda" {
  type = map(object({
    create                       = optional(bool)
    description                  = optional(string)
    handler                      = optional(string)
    runtime                      = optional(string)
    timeout                      = optional(number)
    memory_size                  = optional(number)
    ephemeral_storage_size       = optional(number)
    architectures                = optional(list(string))
    environment_variables        = optional(map(string))
    maximum_retry_attempts       = optional(number)
    maximum_event_age_in_seconds = optional(number)
    create_async_event_config    = optional(bool)
    policy_statements = optional(map(object({
      effect    = string
      actions   = list(string)
      resources = list(string)
    })))
    sqs = optional(map(object({
      enabled = optional(bool)
      queue_name = string
      batch_size = optional(number)
      scaling_config = optional(list(object({
        maximum_concurrency = optional(number)
      })))
    })))
    provisioned_concurrent_executions = optional(number)
    cloudwatch_logs_retention_in_days = optional(number)
    policies                          = optional(list(string))
    layers                            = optional(list(string))
    create_lambda_function_url        = optional(bool)
    local_existing_package            = optional(string)
    ignore_source_code_hash           = optional(bool)
    lambda_permissions = optional(map(object({
      principal  = string
      source_arn = string
    })))
    eventbridge_rules = optional(map(object({
      name        = optional(string)
      description = optional(string)
      source      = optional(list(string))
      detail_type = list(string)
    })))
    cors = optional(object({
      allow_origins     = optional(list(string))
      allow_methods     = optional(list(string))
      allow_headers     = optional(list(string))
      expose_headers    = optional(list(string))
      max_age_seconds   = optional(number)
      allow_credentials = optional(bool)
    }))
    secret_vars = optional(map(object({
      secret_path = optional(string)
      property    = optional(string)
    })))
  }))
  default = {}
}

