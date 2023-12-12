variable "ecs_cluster_name" {
  type = string
}

variable "github_repos" {
  type = map(object({
    create                 = optional(bool)
    github_org_name        = string
    github_repo_names      = list(string)
    enable_ecs_task_policy = optional(bool)
    policy = optional(map(object({
      resources_arn = list(string)
      actions       = list(string)
      conditions = optional(map(object({
        test     = string
        variable = string
        values   = list(string)
      })))
    })))
  }))
}

variable "create_oidc_provider" {
  type    = bool
  default = true
}
