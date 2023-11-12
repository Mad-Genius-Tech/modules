
variable "create" {
  type    = bool
  default = true
}

variable "vpc_cidr" {
  type = string
}

variable "subnet_num" {
  type    = number
  default = 3
}

variable "enable_vpn_gateway" {
  type    = bool
  default = false
}

variable "enable_flow_log" {
  type    = bool
  default = false
}

variable "enable_eks_tag" {
  type    = bool
  default = false
}

variable "enable_dynamodb_endpoint" {
  type    = bool
  default = true
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}