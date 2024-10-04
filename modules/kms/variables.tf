
variable "kms" {
  type = map(object({
    key_administrators = optional(list(string))
    key_users          = optional(list(string))
  }))
}

variable "terragrunt_directory" {
  type    = string
  default = ""
}

variable "terraform_role" {
  type    = string
  default = ""
}