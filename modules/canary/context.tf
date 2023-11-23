variable "org_name" {
  type = string
}

variable "stage_name" {
  type = string
}

variable "service_name" {
  type = string
}

variable "team_name" {
  type = string
}

variable "tags" {
  type    = map(any)
  default = {}
}

module "context" {
  source           = "cloudposse/label/null"
  version          = "~> 0.25.0"
  label_key_case   = "lower"
  label_value_case = "lower"
  namespace        = var.org_name
  stage            = var.stage_name
  name             = var.service_name
  delimiter        = "-"
  label_order      = ["namespace", "environment", "stage", "name"]

  tags = merge(var.tags, {
    team      = var.team_name
    service   = var.service_name
    terraform = "yes"
  })
}

locals {
  tags = merge(
    { for k, v in module.context.tags : k => v if k != "name" },
    var.tags,
  )
}
