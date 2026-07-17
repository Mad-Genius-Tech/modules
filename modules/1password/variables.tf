
variable "create" {
  type        = bool
  description = "Create the secret"
  default     = true
}

variable "secrets" {
  type = map(object({
    secret_prefix      = optional(string)
    password_vault     = string
    password_title     = string
    password_section   = optional(string)
    password_exclude   = optional(list(string))
    password_whitelist = optional(list(string))
  }))

  validation {
    condition = alltrue([
      for secret in values(var.secrets) :
      secret.password_section == null || try(trimspace(secret.password_section) != "", false)
    ])
    error_message = "password_section must be null or a non-empty section label."
  }
}
