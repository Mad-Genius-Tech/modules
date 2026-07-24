variable "cloudfront" {
  type = map(object({
    create                                 = optional(bool)
    enable_logs                            = optional(bool)
    enable_standard_logging_v2             = optional(bool)
    logging_include_cookies                = optional(bool)
    logging_retention_days                 = optional(number)
    enable_additional_metrics              = optional(bool)
    aliases                                = optional(list(string))
    enabled                                = optional(bool)
    price_class                            = optional(string)
    s3_bucket                              = optional(string)
    default_presigned_url                  = optional(bool)
    disable_presigned_url                  = optional(bool)
    use_acm_cert                           = optional(bool)
    wildcard_domain                        = optional(bool)
    domain_name                            = optional(string)
    domain_names                           = optional(list(string), [])
    default_allowed_http_methods           = optional(list(string))
    default_cache_behavior_allowed_methods = optional(list(string))
    origin_request_policy                  = optional(string)
    default_cache_policy                   = optional(string)
    default_origin_request_policy          = optional(string)
    default_response_headers_policy        = optional(string)
    default_target_origin_id               = optional(string)
    ordered_cache_enable_signed_url        = optional(bool)
    response_headers_policy                = optional(string)
    cache_policy                           = optional(string)
    compress                               = optional(bool)
    viewer_protocol_policy                 = optional(string)
    enable_upload_to_s3_origin             = optional(bool)
    default_root_object                    = optional(string)
    viewer_request_function_code           = optional(string)
    allow_list_bucket_access               = optional(bool)
    custom_error_response = optional(list(object({
      error_code            = number
      response_code         = number
      response_page_path    = string
      error_caching_min_ttl = optional(number)
    })))
    ordered_cache_behavior = optional(list(object({
      path_pattern                 = string
      target_origin_id             = string
      presigned_url                = optional(bool)
      viewer_protocol_policy       = optional(string)
      allowed_methods              = optional(list(string))
      cached_methods               = optional(list(string))
      compress                     = optional(bool)
      use_forwarded_values         = optional(bool)
      cache_policy_name            = optional(string)
      origin_request_policy_name   = optional(string)
      response_headers_policy_id   = optional(string)
      response_headers_policy_name = optional(string)
      trusted_key_groups           = optional(list(string))
      trusted_signers              = optional(list(string))
    })), [])
    origin_domain_name        = optional(string)
    origin_connection_timeout = optional(number)
    # Set to the Lambda function name when origin_domain_name is that
    # function's URL: creates a lambda-type OAC (sigv4-signed, AWS_IAM URLs)
    # and the invoke permission scoped to this distribution.
    lambda_url_origin_function_name = optional(string)
    vpc_origin = optional(object({
      arn                    = string
      name                   = optional(string)
      http_port              = optional(number)
      https_port             = optional(number)
      origin_protocol_policy = optional(string)
      origin_ssl_protocols   = optional(list(string))
    }))
    custom_origin_config = optional(object({
      http_port              = optional(number)
      https_port             = optional(number)
      origin_protocol_policy = optional(string)
      origin_ssl_protocols   = optional(list(string))
      origin_read_timeout    = optional(number)
    }))
  }))

  validation {
    condition = alltrue([
      for config in values(var.cloudfront) :
      coalesce(config.logging_retention_days, 30) >= 1 &&
      coalesce(config.logging_retention_days, 30) <= 365 &&
      floor(coalesce(config.logging_retention_days, 30)) == coalesce(config.logging_retention_days, 30)
    ])
    error_message = "logging_retention_days must be a whole number between 1 and 365 days."
  }
}

variable "output_keyfile" {
  type    = bool
  default = true
}

variable "terragrunt_directory" {
  type    = string
  default = ""
}
