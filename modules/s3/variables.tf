variable "s3_buckets" {
  description = "A map of s3 buckets to create"
  type = map(object({
    create                                = optional(bool)
    acl                                   = optional(string)
    attach_policy                         = optional(bool)
    policy                                = optional(string)
    attach_public_policy                  = optional(bool)
    attach_public_read_policy             = optional(bool)
    attach_deny_insecure_transport_policy = optional(bool)
    attach_require_latest_tls_policy      = optional(bool)
    attach_elb_log_delivery_policy        = optional(bool)
    attach_lb_log_delivery_policy         = optional(bool)
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
    inventory = optional(object({
      name                     = optional(string, "inventory")
      destination_bucket_arn   = string
      destination_prefix       = optional(string)
      destination_account_id   = optional(string)
      included_object_versions = optional(string, "All")
      optional_fields          = optional(set(string), [])
      frequency                = optional(string, "Daily")
      filter_prefix            = optional(string)
      sse_kms_key_id           = optional(string)
    }))
    tags = optional(map(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for bucket in values(var.s3_buckets) :
      bucket.inventory == null || contains(["All", "Current"], bucket.inventory.included_object_versions)
    ])
    error_message = "inventory.included_object_versions must be either All or Current."
  }

  validation {
    condition = alltrue([
      for bucket in values(var.s3_buckets) :
      bucket.inventory == null || contains(["Daily", "Weekly"], bucket.inventory.frequency)
    ])
    error_message = "inventory.frequency must be either Daily or Weekly."
  }

  validation {
    condition = alltrue([
      for bucket in values(var.s3_buckets) :
      bucket.inventory == null || can(regex("^arn:[^:]+:s3:::[^/]+$", bucket.inventory.destination_bucket_arn))
    ])
    error_message = "inventory.destination_bucket_arn must be an S3 bucket ARN."
  }
}
