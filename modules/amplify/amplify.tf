locals {
  default_settings = {
    description                   = null
    platform                      = "WEB"
    framework                     = "React"
    auto_branch_creation_patterns = []
    enable_auto_branch_creation   = false
    enable_branch_auto_build      = true
    enable_branch_auto_deletion   = false
    enable_basic_auth             = false
    basic_auth_credentials        = null
    create_iam_role               = true
    iam_service_role_actions      = []
    enable_auto_sub_domain        = false
    wait_for_verification         = false
    build_spec                    = <<-EOT
      version: 1
      frontend:
        phases:
          preBuild:
            commands:
              - yarn install
          build:
            commands:
              - yarn run build
        artifacts:
          baseDirectory: .next
          files:
            - '**/*'
        cache:
          paths:
            - node_modules/**/*
    EOT
    custom_rules = [
      # {
      #   source = "/<*>"
      #   status = "404"
      #   target = "/"
      # }
    ]
    environment_variables = {
      ENV = var.stage_name
    }
    backend_environments                          = {}
    frontend_branch_description                   = null
    frontend_branch_branch_name                   = var.stage_name
    frontend_branch_ttl                           = null
    frontend_branch_enable_basic_auth             = false
    frontend_branch_enable_auto_build             = true
    frontend_branch_enable_pull_request_preview   = false
    frontend_branch_enable_performance_mode       = false
    frontend_branch_enable_notification           = false
    frontend_branch_environment_variables         = {}
    frontend_branch_pull_request_environment_name = null
    frontend_branch_backend_enabled               = false
    frontend_branch_sub_domain_name               = var.stage_name
    frontend_branch_webhook_enabled               = false
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        frontend_branch_branch_name     = "main"
        frontend_branch_sub_domain_name = null
      }
    )
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  apps_map = {
    for k, v in var.apps : k => {
      "identifier"                    = "${module.context.id}-${k}"
      "repository"                    = v.repository
      "domain_name"                   = v.domain_name
      "description"                   = try(coalesce(lookup(v, "description", null), local.merged_default_settings.description), local.merged_default_settings.description)
      "platform"                      = coalesce(lookup(v, "platform", null), local.merged_default_settings.platform)
      "enable_basic_auth"             = coalesce(lookup(v, "enable_basic_auth", null), local.merged_default_settings.enable_basic_auth)
      "enable_auto_branch_creation"   = coalesce(lookup(v, "enable_auto_branch_creation", null), local.merged_default_settings.enable_auto_branch_creation)
      "enable_branch_auto_build"      = coalesce(lookup(v, "enable_branch_auto_build", null), local.merged_default_settings.enable_branch_auto_build)
      "enable_branch_auto_deletion"   = coalesce(lookup(v, "enable_branch_auto_deletion", null), local.merged_default_settings.enable_branch_auto_deletion)
      "create_iam_role"               = coalesce(lookup(v, "create_iam_role", null), local.merged_default_settings.create_iam_role)
      "iam_service_role_actions"      = distinct(compact(concat(coalesce(lookup(v, "iam_service_role_actions", null), local.merged_default_settings.iam_service_role_actions), local.merged_default_settings.iam_service_role_actions)))
      "auto_branch_creation_patterns" = distinct(compact(concat(coalesce(lookup(v, "auto_branch_creation_patterns", null), local.merged_default_settings.auto_branch_creation_patterns), local.merged_default_settings.auto_branch_creation_patterns)))
      "auto_branch_creation_config"   = v.auto_branch_creation_config
      "basic_auth_credentials"        = try(coalesce(lookup(v, "basic_auth_credentials", null), local.merged_default_settings.basic_auth_credentials), local.merged_default_settings.basic_auth_credentials)
      "build_spec"                    = try(coalesce(lookup(v, "build_spec", null), local.merged_default_settings.build_spec), local.merged_default_settings.build_spec)
      "environment_variables"         = merge(coalesce(lookup(v, "environment_variables", null), local.merged_default_settings.environment_variables), local.merged_default_settings.environment_variables)
      "enable_auto_sub_domain"        = coalesce(lookup(v, "enable_auto_sub_domain", null), local.merged_default_settings.enable_auto_sub_domain)
      "wait_for_verification"         = coalesce(lookup(v, "wait_for_verification", null), local.merged_default_settings.wait_for_verification)
      "custom_rules"                  = try(coalesce(lookup(v, "custom_rules", null), local.merged_default_settings.custom_rules), local.merged_default_settings.custom_rules)
      "backend_environments"          = merge(coalesce(lookup(v, "backend_environments", null), local.merged_default_settings.backend_environments), local.merged_default_settings.backend_environments)
      "frontend_branches"             = v.frontend_branches
    }
  }

  branches_map = merge([
    for k, v in local.apps_map : {
      for branch_name in keys(v.frontend_branches) : "${k}|${branch_name}" => {
        "description"                   = try(coalesce(lookup(v.frontend_branches[branch_name], "description", null), local.merged_default_settings.frontend_branch_description), local.merged_default_settings.frontend_branch_description)
        "branch_name"                   = try(coalesce(lookup(v.frontend_branches[branch_name], "branch_name", null), local.merged_default_settings.frontend_branch_branch_name), local.merged_default_settings.frontend_branch_branch_name)
        "framework"                     = try(coalesce(lookup(v.frontend_branches[branch_name], "framework", null), local.merged_default_settings.framework), local.merged_default_settings.framework)
        "ttl"                           = try(coalesce(lookup(v.frontend_branches[branch_name], "ttl", null), local.merged_default_settings.frontend_branch_ttl), local.merged_default_settings.frontend_branch_ttl)
        "enable_basic_auth"             = try(coalesce(lookup(v.frontend_branches[branch_name], "enable_basic_auth", null), local.merged_default_settings.frontend_branch_enable_basic_auth), local.merged_default_settings.frontend_branch_enable_basic_auth)
        "enable_auto_build"             = try(coalesce(lookup(v.frontend_branches[branch_name], "enable_auto_build", null), local.merged_default_settings.frontend_branch_enable_auto_build), local.merged_default_settings.frontend_branch_enable_auto_build)
        "enable_pull_request_preview"   = try(coalesce(lookup(v.frontend_branches[branch_name], "enable_pull_request_preview", null), local.merged_default_settings.frontend_branch_enable_pull_request_preview), local.merged_default_settings.frontend_branch_enable_pull_request_preview)
        "enable_performance_mode"       = try(coalesce(lookup(v.frontend_branches[branch_name], "enable_performance_mode", null), local.merged_default_settings.frontend_branch_enable_performance_mode), local.merged_default_settings.frontend_branch_enable_performance_mode)
        "enable_notification"           = try(coalesce(lookup(v.frontend_branches[branch_name], "enable_notification", null), local.merged_default_settings.frontend_branch_enable_notification), local.merged_default_settings.frontend_branch_enable_notification)
        "environment_variables"         = merge(coalesce(lookup(v.frontend_branches[branch_name], "environment_variables", null), local.merged_default_settings.frontend_branch_environment_variables), local.merged_default_settings.frontend_branch_environment_variables)
        "pull_request_environment_name" = try(coalesce(lookup(v.frontend_branches[branch_name], "pull_request_environment_name", null), local.merged_default_settings.frontend_branch_pull_request_environment_name), local.merged_default_settings.frontend_branch_pull_request_environment_name)
        "backend_enabled"               = try(coalesce(lookup(v.frontend_branches[branch_name], "backend_enabled", null), local.merged_default_settings.frontend_branch_backend_enabled), local.merged_default_settings.frontend_branch_backend_enabled)
        "sub_domain_name"               = try(coalesce(lookup(v.frontend_branches[branch_name], "sub_domain_name", null), local.merged_default_settings.frontend_branch_sub_domain_name), local.merged_default_settings.frontend_branch_sub_domain_name)
        "webhook_enabled"               = try(coalesce(lookup(v.frontend_branches[branch_name], "webhook_enabled", null), local.merged_default_settings.frontend_branch_webhook_enabled), local.merged_default_settings.frontend_branch_webhook_enabled)
      }
    } if length(v.frontend_branches) > 0
  ]...)

  environments_map = merge([
    for k, v in local.apps_map : {
      for environment_name in keys(v.backend_environments) : "${k}|${environment_name}" => v.backend_environments[environment_name]
    } if length(v.backend_environments) > 0
  ]...)
}

resource "aws_amplify_app" "amplify" {
  for_each                      = local.apps_map
  name                          = each.key
  description                   = each.value.description
  repository                    = each.value.repository
  platform                      = each.value.platform
  access_token                  = var.access_token
  auto_branch_creation_patterns = each.value.auto_branch_creation_patterns
  basic_auth_credentials        = each.value.basic_auth_credentials
  build_spec                    = each.value.build_spec
  enable_auto_branch_creation   = each.value.enable_auto_branch_creation
  enable_branch_auto_deletion   = each.value.enable_branch_auto_deletion
  enable_basic_auth             = each.value.enable_basic_auth
  enable_branch_auto_build      = each.value.enable_branch_auto_build
  environment_variables         = each.value.environment_variables
  iam_service_role_arn          = module.iam_role.iam_role_arn
  dynamic "auto_branch_creation_config" {
    for_each = each.value.auto_branch_creation_config != null ? [true] : []
    content {
      basic_auth_credentials        = lookup(each.value.auto_branch_creation_config, "basic_auth_credentials", null)
      build_spec                    = lookup(each.value.auto_branch_creation_config, "build_spec", null)
      enable_auto_build             = lookup(each.value.auto_branch_creation_config, "enable_auto_build", null)
      enable_basic_auth             = lookup(each.value.auto_branch_creation_config, "enable_basic_auth", null)
      enable_performance_mode       = lookup(each.value.auto_branch_creation_config, "enable_performance_mode", null)
      enable_pull_request_preview   = lookup(each.value.auto_branch_creation_config, "enable_pull_request_preview", null)
      environment_variables         = lookup(each.value.auto_branch_creation_config, "environment_variables", null)
      framework                     = lookup(each.value.auto_branch_creation_config, "framework", null)
      pull_request_environment_name = lookup(each.value.auto_branch_creation_config, "pull_request_environment_name", null)
    }
  }
  dynamic "custom_rule" {
    for_each = each.value.custom_rules != null ? each.value.custom_rules : []
    content {
      condition = lookup(custom_rule.value, "condition", null)
      source    = custom_rule.value.source
      status    = lookup(custom_rule.value, "status", null)
      target    = custom_rule.value.target
    }
  }
  tags = local.tags
}

resource "aws_amplify_domain_association" "domain_association" {
  for_each               = { for k, v in local.branches_map : k => v if local.apps_map[split("|", k)[0]].domain_name != null }
  app_id                 = aws_amplify_app.amplify[split("|", each.key)[0]].id
  domain_name            = local.apps_map[split("|", each.key)[0]].domain_name
  enable_auto_sub_domain = local.apps_map[split("|", each.key)[0]].enable_auto_sub_domain
  wait_for_verification  = local.apps_map[split("|", each.key)[0]].wait_for_verification
  dynamic "sub_domain" {
    for_each = each.value.sub_domain_name != null ? [true] : []
    content {
      branch_name = each.value.branch_name
      prefix      = each.value.sub_domain_name
    }
  }
}

resource "aws_amplify_branch" "branch" {
  for_each                      = local.branches_map
  app_id                        = aws_amplify_app.amplify[split("|", each.key)[0]].id
  branch_name                   = each.value.branch_name
  backend_environment_arn       = lookup(each.value, "backend_enabled", false) ? aws_amplify_backend_environment.backend_environment[each.key].arn : null
  display_name                  = each.value.sub_domain_name
  enable_basic_auth             = each.value.enable_basic_auth
  enable_auto_build             = each.value.enable_auto_build
  description                   = each.value.description
  enable_pull_request_preview   = each.value.enable_pull_request_preview
  enable_performance_mode       = each.value.enable_performance_mode
  enable_notification           = each.value.enable_notification
  environment_variables         = each.value.environment_variables
  framework                     = each.value.framework
  stage                         = each.value.branch_name == "main" ? "PRODUCTION" : "DEVELOPMENT"
  ttl                           = each.value.ttl
  pull_request_environment_name = each.value.pull_request_environment_name
  tags                          = local.tags
}


resource "aws_amplify_backend_environment" "backend_environment" {
  for_each             = local.environments_map
  app_id               = aws_amplify_app.amplify[split("|", each.key)[0]].id
  environment_name     = each.value.environment_name
  deployment_artifacts = each.value.deployment_artifacts
  stack_name           = each.value.stack_name
}



# resource "aws_amplify_webhook" "webhook" {
#   for_each = merge([
#     for k, v in local.apps_map : {
#       for branch in module.amplify_app[k].branch_names : "${k}-${branch}" => {
#         "app_id"      = module.amplify_app[k].id,
#         "branch_name" = branch,
#         "description" = format("trigger-%s", branch)
#       }
#     }
#   ]...)
#   app_id      = each.value.app_id
#   branch_name = each.value.branch_name
#   description = each.value.description

# }

# resource "null_resource" "webhook_trigger" {
#   for_each = { for k, v in aws_amplify_webhook.webhook : k => v }
#   # NOTE: We trigger the webhook via local-exec so as to kick off the first build on creation of Amplify App
#   provisioner "local-exec" {
#     command = "curl -s -X POST -d {} '${aws_amplify_webhook.webhook[each.key].url}&operation=startbuild' -H 'Content-Type:application/json'"
#   }
#   depends_on = [aws_amplify_webhook.webhook]
# }