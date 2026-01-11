variable "create" {
  type    = bool
  default = true
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "subnets_cidr_blocks" {
  type = list(string)
}

variable "enable_private_dns" {
  type    = bool
  default = false
}

variable "logs_retention_in_days" {
  type    = number
  default = 1
}

variable "client_cidr_block" {
  type    = string
  default = "192.168.4.0/22"
}

variable "terragrunt_directory" {
  type = string
}

variable "enable_log" {
  type    = bool
  default = false
}

variable "enable_config_file" {
  type    = bool
  default = false
}

variable "vpn_users" {
  type = map(object({
    validity_period_hours = optional(number)
  }))
  default = {}
}

variable "banner_text" {
  default = ""
}

variable "authentication_type" {
  default = "certificate-authentication"
}

variable "saml_metadata_file" {
  default = ""
}

variable "access_group_id" {
  default = ""
}

variable "lambda_function_arn" {
  default = ""
}

variable "lambda_local_package" {
  type    = string
  default = ""
}

variable "lambda_environment_variables" {
  type    = map(string)
  default = {}
}

variable "lambda_ignore_source_code_hash" {
  type    = bool
  default = false
}