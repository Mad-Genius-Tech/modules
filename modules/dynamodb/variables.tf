
variable "dynamodb" {
  type = map(object({
    table_name   = string
    table_class  = optional(string)
    billing_mode = optional(string)
    hash_key     = optional(string)
    range_key    = optional(string)
    attributes = optional(list(object({
      name = string
      type = string
    })))
    server_side_encryption_enabled = optional(bool)
    deletion_protection_enabled    = optional(bool)
    global_secondary_indexes = optional(list(object({
      name                                  = string
      hash_key                              = optional(string)
      range_key                             = optional(string)
      write_capacity                        = optional(number)
      read_capacity                         = optional(number)
      projection_type                       = optional(string)
      non_key_attributes                    = optional(list(string))
      server_side_encryption_enabled        = optional(bool)
      stream_enabled                        = optional(bool)
      stream_view_type                      = optional(string)
      projection_non_key_attributes         = optional(list(string))
      projection_include                    = optional(bool)
      projection_include_type               = optional(string)
      projection_include_non_key_attributes = optional(list(string))
    })))
    autoscaling_enabled                   = optional(bool)
    ignore_changes_global_secondary_index = optional(bool)
    autoscaling_read_enabled              = optional(bool)
    autoscaling_read_scale_in_cooldown    = optional(number)
    autoscaling_read_scale_out_cooldown   = optional(number)
    autoscaling_read_target_value         = optional(number)
    autoscaling_read_max_capacity         = optional(number)
    autoscaling_write_enabled             = optional(bool)
    autoscaling_write_scale_in_cooldown   = optional(number)
    autoscaling_write_scale_out_cooldown  = optional(number)
    autoscaling_write_target_value        = optional(number)
    autoscaling_write_max_capacity        = optional(number)
    tags                                  = optional(map(string))
    autoscaling_indexes = optional(map(object({
      read_max_capacity  = optional(number)
      read_min_capacity  = optional(number)
      write_max_capacity = optional(number)
      write_min_capacity = optional(number)
    })))
    point_in_time_recovery_enabled = optional(bool)
    stream_enabled                 = optional(bool)
    stream_view_type               = optional(string)
    ttl_enabled                    = optional(bool)
    ttl_attribute_name             = optional(string)
  }))
}