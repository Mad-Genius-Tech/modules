variable "vpc_peering" {
  type = map(object({
    create                                    = optional(bool)
    requester_vpc_id                          = string
    accepter_vpc_id                           = string
    accepter_owner_id                         = optional(string)
    accepter_region                           = optional(string)
    accepter_allow_remote_vpc_dns_resolution  = optional(bool)
    requester_allow_remote_vpc_dns_resolution = optional(bool)
    requester_cidr_blocks                     = optional(list(string))
    accepter_cidr_blocks                      = optional(list(string))
  }))
}
