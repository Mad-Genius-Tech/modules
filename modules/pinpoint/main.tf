data "aws_region" "current" {}

locals {
  default_settings = {
    base_path_template  = ""
    gcm_channel_api_key = null
    email_from_address  = null
    ses_region          = data.aws_region.current.name
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  pinpoint_map = {
    for k, v in var.pinpoint : k => {
      "identifier"          = "${module.context.id}-${k}"
      "gcm_channel_api_key" = try(coalesce(lookup(v, "gcm_channel_api_key", null), local.merged_default_settings.gcm_channel_api_key), local.merged_default_settings.gcm_channel_api_key)
      "email_from_address"  = try(coalesce(lookup(v, "email_from_address", null), local.merged_default_settings.email_from_address), local.merged_default_settings.email_from_address)
      "ses_region"          = try(coalesce(lookup(v, "ses_region", null), local.merged_default_settings.ses_region), local.merged_default_settings.ses_region)
      "base_path_template"  = try(coalesce(lookup(v, "base_path_template", null), local.merged_default_settings.base_path_template), local.merged_default_settings.base_path_template)

    } if coalesce(lookup(v, "create", null), true)
  }
}

resource "aws_pinpoint_app" "app" {
  for_each = local.pinpoint_map
  name     = each.value.identifier
  tags     = local.tags
}

resource "aws_pinpoint_gcm_channel" "gcm" {
  for_each       = { for k, v in local.pinpoint_map : k => v if v.gcm_channel_api_key != null }
  application_id = aws_pinpoint_app.app[each.key].application_id
  api_key        = each.value.gcm_channel_api_key
}

data "aws_ses_email_identity" "ses_identity" {
  for_each = { for k, v in local.pinpoint_map : k => v if v.email_from_address != null && v.ses_region != "us-east-1" }
  email    = each.value.email_from_address
}

data "aws_ses_email_identity" "ses_identity_default" {
  for_each = { for k, v in local.pinpoint_map : k => v if v.email_from_address != null && v.ses_region == "us-east-1" }
  email    = each.value.email_from_address
  provider = aws.us-east-1
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

resource "aws_pinpoint_email_channel" "email" {
  for_each       = { for k, v in local.pinpoint_map : k => v if v.email_from_address != null }
  application_id = aws_pinpoint_app.app[each.key].application_id
  from_address   = each.value.email_from_address
  identity       = each.value.ses_region != "us-east-1" ? data.aws_ses_email_identity.ses_identity[each.key].arn : data.aws_ses_email_identity.ses_identity_default[each.key].arn
}


module "pinpoint_tpl" {
  for_each           = { for k, v in local.pinpoint_map : k => v if v.base_path_template != "" }
  source             = "./terraform-aws-pinpoint-create-templates"
  base_path_template = each.value.base_path_template
  map_replace        = {}
  rules_off          = []
}
