
variable "kms" {
  type = map(object({
    create                           = optional(bool)
    key_usage                        = optional(string)
    customer_master_key_spec         = optional(string)
    enable_key_rotation              = optional(bool)
    key_administrators               = optional(list(string))
    key_users                        = optional(list(string))
    key_asymmetric_sign_verify_users = optional(list(string))
  }))

  validation {
    condition     = alltrue([for _, key in var.kms : contains(["ENCRYPT_DECRYPT", "SIGN_VERIFY"], coalesce(key.key_usage, "ENCRYPT_DECRYPT"))])
    error_message = "kms[*].key_usage must be ENCRYPT_DECRYPT or SIGN_VERIFY."
  }
}

variable "terragrunt_directory" {
  type    = string
  default = ""
}

variable "terraform_role" {
  type    = string
  default = ""
}