
variable "access_token" {
  type    = string
  default = null
}

variable "oauth_token" {
  type    = string
  default = null
}

variable "domain_name" {
  type    = string
  default = ""
}

variable "apps" {
  type = map(object({
    repository                  = string
    description                 = optional(string)
    branch_name                 = optional(string)
    platform                    = optional(string)
    oauth_token                 = optional(string)
    build_spec                  = optional(string)
    enable_auto_branch_creation = optional(bool)
    enable_branch_auto_build    = optional(bool)
    enable_branch_auto_deletion = optional(bool)
    environment_variables       = optional(map(string))
    iam_service_role_enabled    = optional(bool)
    stage                       = optional(string)
    domains = optional(map(object({
      enable_auto_sub_domain = optional(bool, false)
      wait_for_verification  = optional(bool, false)
      sub_domain = list(object({
        branch_name = string
        prefix      = string
      }))
    })))
    environments = optional(map(object({
      branch_name                   = optional(string)
      backend_enabled               = optional(bool, false)
      environment_name              = optional(string)
      deployment_artifacts          = optional(string)
      stack_name                    = optional(string)
      display_name                  = optional(string)
      description                   = optional(string)
      enable_auto_build             = optional(bool)
      enable_basic_auth             = optional(bool)
      enable_notification           = optional(bool)
      enable_performance_mode       = optional(bool)
      enable_pull_request_preview   = optional(bool)
      environment_variables         = optional(map(string))
      framework                     = optional(string)
      pull_request_environment_name = optional(string)
      stage                         = optional(string)
      ttl                           = optional(number)
      webhook_enabled               = optional(bool, false)
    })))
  }))
}

variable "domain_config" {
  type = object({
    domain_name            = optional(string)
    enable_auto_sub_domain = optional(bool, false)
    wait_for_verification  = optional(bool, false)
    sub_domain = list(object({
      branch_name = string
      prefix      = string
    }))
  })
  description = "Amplify custom domain configuration"
  default     = null
}
