
variable "apigateway" {
  type = map(object({
    create        = optional(bool)
    endpoint_type = optional(list(string))
    domain_names = optional(map(object({
      use_wildcard_domain = optional(bool)
      domain_name         = optional(string)
      use_acm             = optional(bool)
    })))
    xray_tracing_enabled        = optional(bool)
    lambda_function             = string
    create_log_group            = optional(bool)
    apigw_exec_log_level        = optional(string)
    data_trace_enabled          = optional(bool)
    log_group_retention_in_days = optional(number)
    enable_cors                 = optional(bool)
  }))
}

# See https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html for additional information
# on how to configure logging.
variable "access_log_format" {
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
	"functionResponseStatus": "$context.integration.status",
	"integrationServiceStatus": "$context.integration.integrationStatus",
  "integrationRequestId": "$context.integration.requestId",
  "integrationLatency": "$context.integration.latency",
  "integrationError": "$context.integration.error",
  "authorizeResultStatus": "$context.authorize.status",
	"authorizerServiceStatus": "$context.authorizer.status",
	"authorizerLatency": "$context.authorizer.latency",
	"authorizerRequestId": "$context.authorizer.requestId",
  "ip": "$context.identity.sourceIp",
	"userAgent": "$context.identity.userAgent",
	"principalId": "$context.authorizer.principalId",
	"cognitoUser": "$context.identity.cognitoIdentityId",
  "caller": "$context.identity.caller",
  "user": "$context.identity.user",
  "accountId": "$context.identity.accountId",
  "apiId": "$context.apiId",
  "stage": "$context.stage",
  "errorMessageString": "$context.error.messageString",
  "errorValidationErrorString": "$context.error.validationErrorString",
}
  EOF
}
