variable "cloudfront" {
  type = map(object({
    create                                 = optional(bool)
    aliases                                = optional(list(string))
    enabled                                = optional(bool)
    price_class                            = optional(string)
    s3_bucket                              = optional(string)
    wildcard_domain                        = optional(bool)
    domain_name                            = string
    default_cache_behavior_allowed_methods = optional(list(string))
    origin_request_policy                  = optional(string)
    response_headers_policy                = optional(string)
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
    origin_domain_name = optional(string)
    custom_origin_config = optional(object({
      http_port              = optional(number)
      https_port             = optional(number)
      origin_protocol_policy = optional(string)
      origin_ssl_protocols   = optional(list(string))
    }))
  }))
}
