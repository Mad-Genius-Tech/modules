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
    provisioned_concurrent_executions = optional(number)
    cloudwatch_logs_retention_in_days = optional(number)
    keep_warm                         = optional(bool)
    keep_warm_expression              = optional(string)
    policies                          = optional(list(string))
    layers                            = optional(list(string))
    create_lambda_function_url        = optional(bool)
    lambda_bucket_name                = optional(string)
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
    apigateway_path = optional(string)
    http_method     = optional(string)
  }))
  default = {}
}


variable "lambda_bucket_name" {
  type    = string
  default = ""
}

variable "api_domain_name" {
  type    = string
  default = ""
}

variable "use_wildcard_domain" {
  type    = bool
  default = true
}

variable "api_domain_name_endpoint_type" {
  type    = string
  default = "REGIONAL"
}

variable "create_apigateway_log_group" {
  type    = bool
  default = false
}

variable "log_group_retention_in_days" {
  type    = number
  default = 3
}


# See https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html for additional information
# on how to configure logging.
variable "apigateway_log_format" {
  description = "The format of the access log file."
  type        = string
  default     = <<EOF
  {
	"requestTime": "$context.requestTime",
	"requestId": "$context.requestId",
	"httpMethod": "$context.httpMethod",
	"path": "$context.path",
	"resourcePath": "$context.resourcePath",
	"status": $context.status,
	"responseLatency": $context.responseLatency,
  "xrayTraceId": "$context.xrayTraceId",
  "integrationRequestId": "$context.integration.requestId",
	"functionResponseStatus": "$context.integration.status",
  "integrationLatency": "$context.integration.latency",
	"integrationServiceStatus": "$context.integration.integrationStatus",
  "authorizeResultStatus": "$context.authorize.status",
	"authorizerServiceStatus": "$context.authorizer.status",
	"authorizerLatency": "$context.authorizer.latency",
	"authorizerRequestId": "$context.authorizer.requestId",
  "ip": "$context.identity.sourceIp",
	"userAgent": "$context.identity.userAgent",
	"principalId": "$context.authorizer.principalId",
	"cognitoUser": "$context.identity.cognitoIdentityId",
  "user": "$context.identity.user"
}
  EOF
}