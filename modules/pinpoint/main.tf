data "aws_region" "current" {}

locals {
  default_settings = {
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


locals {
  template_dirs = fileset(var.templates_dir, "*")

  discovered_templates = {
    for dir in local.template_dirs : dir => {
      yaml_file    = fileexists("${var.templates_dir}/${dir}/main.yml") ? "${var.templates_dir}/${dir}/main.yml" : (fileexists("${var.templates_dir}/${dir}/main.yaml") ? "${var.templates_dir}/${dir}/main.yaml" : null)
      html_content = fileexists("${var.templates_dir}/${dir}/index.html") ? file("${var.templates_dir}/${dir}/index.html") : ""
      text_content = fileexists("${var.templates_dir}/${dir}/index.txt") ? file("${var.templates_dir}/${dir}/index.txt") : ""
    }
  }

  parsed_templates = {
    for dir, template in local.discovered_templates :
    dir => {
      # If yaml_file exists, parse it to get name and subject
      name      = template.yaml_file != null ? yamldecode(file(template.yaml_file))["name"] : dir
      subject   = template.yaml_file != null ? yamldecode(file(template.yaml_file))["subject"] : "Subject for ${dir}"
      html_part = template.html_content
      text_part = template.text_content != "" ? template.text_content : null
    } if template.html_content != ""
  }
}

resource "aws_pinpoint_email_template" "templates" {
  for_each      = local.parsed_templates
  template_name = each.value.name != null ? each.value.name : each.key
  email_template {
    subject   = each.value.subject
    html_part = each.value.html_part
    text_part = each.value.text_part
  }
  tags = local.tags
}
