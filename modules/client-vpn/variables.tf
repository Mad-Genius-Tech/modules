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