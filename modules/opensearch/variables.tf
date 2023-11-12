variable "vpc_id" {}

variable "subnet_ids" {
  type = list(any)
}

variable "ingress_security_group_id" {
  type    = string
  default = ""
}

variable "ingress_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "create_linked_role" {
  type    = bool
  default = false
}

variable "aws_service_name_for_linked_role" {
  type        = string
  description = "AWS service name for linked role."
  default     = "opensearchservice.amazonaws.com"
}

variable "enable_secret_manager" {
  type    = bool
  default = true
}

variable "opensearch" {
  type = map(object({
    create                         = optional(bool)
    engine_version                 = optional(string)
    instance_type                  = optional(string)
    instance_count                 = optional(number)
    zone_awareness_enabled         = optional(bool)
    dedicated_master_enabled       = optional(bool)
    dedicated_master_type          = optional(string)
    dedicated_master_count         = optional(number)
    warm_enabled                   = optional(bool)
    warm_count                     = optional(number)
    warm_type                      = optional(string)
    encrypt_at_rest_enabled        = optional(bool)
    node_to_node_encryption        = optional(bool)
    security_options_enabled       = optional(bool)
    anonymous_auth_enabled         = optional(bool)
    internal_user_database_enabled = optional(bool)
    master_user_name               = optional(string)
    ebs_enabled                    = optional(bool)
    volume_type                    = optional(string)
    volume_size                    = optional(number)
    iops                           = optional(number)
    throughput                     = optional(number)
    wildcard_domain                = optional(bool)
    custom_endpoint                = optional(string)
    enforce_https                  = optional(bool)
    tls_security_policy            = optional(string)
    audit_logs_enabled             = optional(bool)
    search_logs_enabled            = optional(bool)
    index_logs_enabled             = optional(bool)
    application_logs_enabled       = optional(bool)
    retention_in_days              = optional(number)
    iam_role_arns                  = optional(list(string))
    availability_zone_count        = optional(number)
  }))
  default = {}
}
