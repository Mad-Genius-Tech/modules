
variable "enabled" {
  type    = bool
  default = true
}

variable "backup_plans" {
  type = map(object({
    create               = optional(bool)
    backup_resources     = optional(list(string))
    not_backup_resources = optional(list(string))
    selection_tag = optional(list(object({
      type  = optional(string)
      key   = optional(string)
      value = optional(string)
    })))
    condition = optional(object({
      string_equals = optional(list(object({
        key   = string
        value = string
      })), [])
      string_not_equals = optional(list(object({
        key   = string
        value = string
      })), [])
      string_like = optional(list(object({
        key   = string
        value = string
      })), [])
      string_not_like = optional(list(object({
        key   = string
        value = string
      })), [])
    }))
    rules = map(object({
      name                     = optional(string)
      schedule                 = optional(string)
      start_window             = optional(number)
      completion_window        = optional(number)
      enable_continuous_backup = optional(bool)
      recovery_point_tags      = optional(map(string))
      lifecycle = optional(object({
        cold_storage_after = optional(number)
        delete_after       = optional(number)
      }))
      copy_action = optional(object({
        destination_vault_arn = optional(string)
        lifecycle = optional(object({
          cold_storage_after = optional(number)
          delete_after       = optional(number)
        }))
      }))
    }))
  }))
}
