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
    create                                      = optional(bool)
    description                                 = optional(string)
    handler                                     = optional(string)
    runtime                                     = optional(string)
    timeout                                     = optional(number)
    memory_size                                 = optional(number)
    ephemeral_storage_size                      = optional(number)
    architectures                               = optional(list(string))
    environment_variables                       = optional(map(string))
    maximum_retry_attempts                      = optional(number)
    maximum_event_age_in_seconds                = optional(number)
    create_async_event_config                   = optional(bool)
    create_current_version_async_event_config   = optional(bool)
    create_unqualified_alias_async_event_config = optional(bool)
    policy_statements = optional(map(object({
      effect    = string
      actions   = list(string)
      resources = list(string)
    })))
    provisioned_concurrent_executions        = optional(number)
    cloudwatch_logs_retention_in_days        = optional(number)
    keep_warm                                = optional(bool)
    keep_warm_expression                     = optional(string)
    policies                                 = optional(list(string))
    db_instance_address                      = optional(string)
    db_instance_arn                          = optional(string)
    db_instance_endpoint                     = optional(string)
    db_instance_identifier                   = optional(string)
    db_instance_master_user_secret_arn       = optional(string)
    db_instance_name                         = optional(string)
    db_instance_port                         = optional(number)
    db_security_group_id                     = optional(string)
    layers                                   = optional(list(string))
    create_lambda_function_url               = optional(bool)
    lambda_bucket_name                       = optional(string)
    duration_evaluation_periods              = optional(number)
    tracing_mode                             = optional(string)
    duration_threshold                       = optional(number)
    throttles_evaluation_periods             = optional(number)
    throttles_threshold                      = optional(number)
    errors_evaluation_periods                = optional(number)
    errors_threshold                         = optional(number)
    concurrent_executions_evaluation_periods = optional(number)
    concurrent_executions_threshold          = optional(number)
    error_rate_evaluation_periods            = optional(number)
    error_rate_threshold                     = optional(number)
    enable_insights                          = optional(bool)
    cors = optional(object({
      allow_origins     = optional(list(string))
      allow_methods     = optional(list(string))
      allow_headers     = optional(list(string))
      expose_headers    = optional(list(string))
      max_age_seconds   = optional(number)
      allow_credentials = optional(bool)
    }))
    sqs = optional(map(object({
      enabled    = optional(bool)
      queue_name = string
      batch_size = optional(number)
    })))
    dynamodb_tables = optional(map(object({
      enabled                        = optional(bool)
      table_name                     = string
      batch_size                     = optional(number)
      starting_position              = optional(string)
      parallelization_factor         = optional(number)
      maximum_record_age_in_seconds  = optional(number)
      maximum_retry_attempts         = optional(number)
      bisect_batch_on_function_error = optional(bool)
    })))
    secret_vars = optional(map(object({
      secret_path = optional(string)
      property    = optional(string)
    })))
    cloudwatch_events = optional(map(object({
      rule_name           = optional(string)
      schedule_expression = optional(string)
    })))
  }))
  default = {}
}

variable "sns_topic_arn" {
  type    = string
  default = ""
}
