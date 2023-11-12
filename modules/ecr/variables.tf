variable "ecr_repositories" {
  type = map(object({
    create                          = optional(bool)
    repository_type                 = optional(string)
    repository_image_tag_mutability = optional(string)
    repository_encryption_type      = optional(string)
    repository_image_scan_on_push   = optional(bool)
    attach_repository_policy        = optional(bool)
    repository_policy               = optional(string)
    create_repository_policy        = optional(bool)
    create_lifecycle_policy         = optional(bool)
    repository_lifecycle_policy     = optional(string)
  }))
  default = {}
}