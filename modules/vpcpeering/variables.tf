
variable "create" {
  type    = bool
  default = true
}

variable "requester_vpc_id" {
  type = string
}

variable "accepter_vpc_id" {
  type = string
}

variable "accepter_allow_remote_vpc_dns_resolution" {
  type    = bool
  default = true
}

variable "requester_allow_remote_vpc_dns_resolution" {
  type    = bool
  default = true
}

variable "requester_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "accepter_cidr_blocks" {
  type    = list(string)
  default = []
}
