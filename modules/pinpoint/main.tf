
locals {
  default_settings = {
    base_path_template  = ""
    gcm_channel_api_key = null
    email_from_address  = null

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
      "base_path_template"  = try(coalesce(lookup(v, "base_path_template", null), local.merged_default_settings.base_path_template), local.merged_default_settings.base_path_template)

    } if coalesce(lookup(v, "create", null), true)
  }
}

variable "pinpoint" {
  type = map(object({
    create              = optional(bool)
    gcm_channel_api_key = optional(string)
    email_from_address  = optional(string)
    base_path_template  = optional(string)
  }))
  default = {}
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
  for_each       = { for k, v in local.pinpoint_map : k => v if v.email_from_address != null }
  email          = each.value.email_from_address
}

resource "aws_pinpoint_email_channel" "email" {
  for_each         = { for k, v in local.pinpoint_map : k => v if v.email_from_address != null }
  application_id   = aws_pinpoint_app.app[each.key].application_id
  from_address     = each.value.email_from_address
  identity         = data.aws_ses_email_identity.ses_identity[each.key].arn
}


module "pinpoint_tpl" {
  for_each           = { for k, v in local.pinpoint_map : k => v if v.base_path_template != "" }
  source             = "./terraform-aws-pinpoint-create-templates"
  base_path_template = each.value.base_path_template
  map_replace        = {}
  rules_off          = []
}
