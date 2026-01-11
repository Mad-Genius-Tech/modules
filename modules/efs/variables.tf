variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ingress_cidr_blocks" {
  type = list(string)
}

variable "efs" {
  type = map(object({
    create                           = optional(bool, true)
    performance_mode                 = optional(string)
    throughput_mode                  = optional(string)
    encrypted                        = optional(bool)
    enable_backup_policy             = optional(bool)
    create_replication_configuration = optional(bool)
    access_points                    = optional(map(any))
    tags                             = optional(map(any))
    iam_roles_read_access            = optional(list(string))
    iam_roles_write_access           = optional(list(string))
    iam_roles_root_access            = optional(list(string))
  }))
  default = {}
}
