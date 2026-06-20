variable "enabled" {
  type    = bool
  default = true
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "agentcore_image" {
  type = string
}

variable "attachment_s3_bucket" {
  type = string
}

variable "session_s3_bucket" {
  type = string
}

variable "runtime_secrets_name" {
  type    = string
  default = null
}

variable "agentcore_environment_variables" {
  type    = map(string)
  default = {}
}
