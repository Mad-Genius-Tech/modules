
variable "access_token" {
  type = string
}

variable "create_iam_role" {
  type    = bool
  default = true
}

variable "iam_service_role_actions" {
  type    = list(string)
  default = []
}

variable "apps" {
  type = map(object({
    repository                    = string
    domain_name                   = optional(string)
    description                   = optional(string)
    platform                      = optional(string)
    framework                     = optional(string)
    auto_branch_creation_patterns = optional(list(string))
    basic_auth_credentials        = optional(string)
    build_spec                    = optional(string)
    enable_auto_branch_creation   = optional(bool)
    enable_branch_auto_build      = optional(bool)
    enable_branch_auto_deletion   = optional(bool)
    enable_basic_auth             = optional(bool)
    environment_variables         = optional(map(string))
    auto_branch_creation_config = optional(object({
      basic_auth_credentials        = optional(string)
      build_spec                    = optional(string)
      enable_auto_build             = optional(bool)
      enable_basic_auth             = optional(bool)
      enable_performance_mode       = optional(bool)
      enable_pull_request_preview   = optional(bool)
      environment_variables         = optional(map(string))
      framework                     = optional(string)
      pull_request_environment_name = optional(string)
      stage                         = optional(string)
    }))
    custom_rules = optional(list(object({
      condition = optional(string)
      source    = string
      status    = optional(string)
      target    = string
    })))
    enable_auto_sub_domain = optional(bool)
    wait_for_verification  = optional(bool)
    backend_environments = optional(map(object({
      environment_name     = optional(string)
      deployment_artifacts = optional(string)
      stack_name           = optional(string)
    })))
    frontend_branches = optional(map(object({
      description                   = optional(string)
      branch_name                   = optional(string)
      ttl                           = optional(number)
      enable_basic_auth             = optional(bool)
      enable_auto_build             = optional(bool)
      enable_pull_request_preview   = optional(bool)
      enable_performance_mode       = optional(bool)
      enable_notification           = optional(bool)
      environment_variables         = optional(map(string))
      pull_request_environment_name = optional(string)
      backend_enabled               = optional(bool)
      sub_domain_name               = optional(string)
      webhook_enabled               = optional(bool)
    })))
  }))
}
