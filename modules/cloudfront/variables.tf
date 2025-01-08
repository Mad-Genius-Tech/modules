variable "cloudfront" {
  type = map(object({
    create                                 = optional(bool)
    enable_logs                            = optional(bool)
    aliases                                = optional(list(string))
    enabled                                = optional(bool)
    price_class                            = optional(string)
    s3_bucket                              = optional(string)
    default_presigned_url                  = optional(bool)
    use_acm_cert                           = optional(bool)
    wildcard_domain                        = optional(bool)
    domain_name                            = string
    default_allowed_http_methods           = optional(list(string))
    default_cache_behavior_allowed_methods = optional(list(string))
    origin_request_policy                  = optional(string)
    default_cache_policy                   = optional(string)
    default_origin_request_policy          = optional(string)
    default_response_headers_policy        = optional(string)
    response_headers_policy                = optional(string)
    cache_policy                           = optional(string)
    compress                               = optional(bool)
    viewer_protocol_policy                 = optional(string)
    enable_upload_to_s3_origin             = optional(bool)
    default_root_object                    = optional(string)
    viewer_request_function_code           = optional(string)
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
      response_headers_policy_name = optional(string)
    })), [])
    origin_domain_name = optional(string)
    custom_origin_config = optional(object({
      http_port              = optional(number)
      https_port             = optional(number)
      origin_protocol_policy = optional(string)
      origin_ssl_protocols   = optional(list(string))
    }))
  }))
}

variable "output_keyfile" {
  type    = bool
  default = true
}

variable "terragrunt_directory" {
  type    = string
  default = ""
}