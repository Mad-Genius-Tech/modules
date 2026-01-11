variable "s3_buckets" {
  description = "A map of s3 buckets to create"
  type = map(object({
    create                    = optional(bool)
    acl                       = optional(string)
    attach_policy             = optional(bool)
    policy                    = optional(string)
    attach_public_policy      = optional(bool)
    attach_public_read_policy = optional(bool)
    lifecycle_rule = optional(list(object({
      id      = optional(string)
      prefix  = optional(string)
      enabled = optional(bool)
      expiration = optional(object({
        days                         = optional(number)
        date                         = optional(string)
        expired_object_delete_marker = optional(bool)
      }))
      transition = optional(list(object({
        days          = optional(number)
        date          = optional(string)
        storage_class = optional(string)
      })))
      noncurrent_version_transition = optional(list(object({
        days          = optional(number)
        storage_class = optional(string)
      })))
      noncurrent_version_expiration = optional(object({
        days = optional(number)
      }))
      abort_incomplete_multipart_upload_days = optional(number)
      tags                                   = optional(map(string))
    })))
    versioning = optional(object({
      enabled    = optional(bool)
      mfa_delete = optional(bool)
    }))
    server_side_encryption_configuration = optional(object({
      rule = optional(object({
        apply_server_side_encryption_by_default = optional(object({
          kms_master_key_id = optional(string)
          sse_algorithm     = optional(string)
        }))
      }))
    }))
    block_public_acls        = optional(bool)
    block_public_policy      = optional(bool)
    ignore_public_acls       = optional(bool)
    restrict_public_buckets  = optional(bool)
    control_object_ownership = optional(bool)
    object_ownership         = optional(string)
    acceleration_status      = optional(string)
    cors_rule = optional(list(object({
      allowed_headers = optional(list(string))
      allowed_methods = optional(list(string))
      allowed_origins = optional(list(string))
      expose_headers  = optional(list(string))
      max_age_seconds = optional(number)
    })))
    website = optional(object({
      index_document = optional(string, null)
      error_document = optional(string, null)
      # redirect_all_requests_to = optional(object({
      #   host_name = optional(string)
      #   protocol  = optional(string)
      # }))
      # routing_rules = optional(list(object({
      #   condition = optional(object({
      #     http_error_code_returned_equals = optional(string)
      #     key_prefix_equals               = optional(string)
      #   }))
      #   redirect = optional(object({
      #     host_name               = optional(string)
      #     http_redirect_code      = optional(string)
      #     protocol                = optional(string)
      #     replace_key_prefix_with = optional(string)
      #     replace_key_with        = optional(string)
      #   }))
      # })))
    }))
    lambda_function_name = optional(string)
    events_filter = optional(map(object({
      lambda        = optional(string)
      bucket_events = optional(list(string))
      prefix        = optional(string)
      suffix        = optional(string)
    })))
    intelligent_tiering = optional(object({
      enabled = optional(bool, false)
      transition = optional(list(object({
        days          = optional(number)
        storage_class = optional(string)
      })), [])
    }))
    tags = optional(map(string))
  }))
  default = {}
}