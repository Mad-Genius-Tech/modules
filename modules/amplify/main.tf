locals {

  default_settings = {
    description                 = null
    branch_name                 = "main"
    environment_variables       = {}
    build_spec                  = null
    enable_basic_auth           = false
    enable_auto_branch_creation = false
    enable_branch_auto_build    = true
    enable_branch_auto_deletion = false
    iam_service_role_enabled    = false
    iam_service_role_actions    = []
    platform                    = "WEB"
    environments = {
      framework       = "React"
      webhook_enabled = false
    }
  }




  env_default_settings = {
    prod = merge(local.default_settings,
      {
      }
    )
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  apps_map = {
    for k, v in var.apps : k => {
      "identifier"                  = "${module.context.id}-${k}"
      "repository"                  = v.repository
      "description"                 = try(coalesce(lookup(v, "description", null), local.merged_default_settings.description), local.merged_default_settings.description)
      "build_spec"                  = try(coalesce(lookup(v, "build_spec", null), local.merged_default_settings.build_spec), local.merged_default_settings.build_spec)
      "branch_name"                 = try(coalesce(lookup(v, "branch_name", null), local.merged_default_settings.branch_name), local.merged_default_settings.branch_name)
      "oauth_token"                 = try(coalesce(lookup(v, "oauth_token", null), var.oauth_token), var.oauth_token)
      "domains"                     = try(coalesce(lookup(v, "domains", null)), {})
      "environment_variables"       = merge(coalesce(lookup(v, "environment_variables", null), local.merged_default_settings.environment_variables), local.merged_default_settings.environment_variables)
      "enable_basic_auth"           = coalesce(lookup(v, "enable_basic_auth", null), local.merged_default_settings.enable_basic_auth)
      "enable_auto_branch_creation" = coalesce(lookup(v, "enable_auto_branch_creation", null), local.merged_default_settings.enable_auto_branch_creation)
      "enable_branch_auto_build"    = coalesce(lookup(v, "enable_branch_auto_build", null), local.merged_default_settings.enable_branch_auto_build)
      "enable_branch_auto_deletion" = coalesce(lookup(v, "enable_branch_auto_deletion", null), local.merged_default_settings.enable_branch_auto_deletion)
      "iam_service_role_enabled"    = coalesce(lookup(v, "iam_service_role_enabled", null), local.merged_default_settings.iam_service_role_enabled)
      "iam_service_role_actions"    = distinct(compact(concat(coalesce(lookup(v, "iam_service_role_actions", null), local.merged_default_settings.iam_service_role_actions), local.merged_default_settings.iam_service_role_actions)))
      "platform"                    = coalesce(lookup(v, "platform", null), local.merged_default_settings.platform)
      "environments" = {
        for k1, v1 in v.environments : k1 => merge(v1, local.merged_default_settings.environments) if can(v.environments)
      }
    }
  }
}

module "amplify_app" {
  source                      = "cloudposse/amplify-app/aws"
  version                     = "1.0.0"
  for_each                    = local.apps_map
  enabled                     = length(var.access_token) > 0 ? true : false
  access_token                = var.access_token
  name                        = each.key
  description                 = each.value.description
  repository                  = each.value.repository
  platform                    = each.value.platform
  build_spec                  = each.value.build_spec
  enable_auto_branch_creation = each.value.enable_auto_branch_creation
  enable_branch_auto_build    = each.value.enable_branch_auto_build
  enable_branch_auto_deletion = each.value.enable_branch_auto_deletion
  environment_variables       = each.value.environment_variables
  domains                     = each.value.domains
  context                     = module.context.context
  domain_config               = var.domain_config
  environments                = each.value.environments
}

resource "aws_amplify_webhook" "webhook" {
  for_each = merge([
    for k, v in local.apps_map : {
      for branch in module.amplify_app[k].branch_names : "${k}-${branch}" => {
        "app_id"      = module.amplify_app[k].id,
        "branch_name" = branch,
        "description" = format("trigger-%s", branch)
      }
    }
  ]...)
  app_id      = each.value.app_id
  branch_name = each.value.branch_name
  description = each.value.description

}

resource "null_resource" "webhook_trigger" {
  for_each = { for k, v in aws_amplify_webhook.webhook : k => v }

  # NOTE: We trigger the webhook via local-exec so as to kick off the first build on creation of Amplify App
  provisioner "local-exec" {
    command = "curl -s -X POST -d {} '${aws_amplify_webhook.webhook[each.key].url}&operation=startbuild' -H 'Content-Type:application/json'"
  }
  depends_on = [aws_amplify_webhook.webhook]
}