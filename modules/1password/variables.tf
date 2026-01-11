
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
    password_exclude   = optional(list(string))
    password_whitelist = optional(list(string))
  }))
}