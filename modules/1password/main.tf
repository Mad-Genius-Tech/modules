locals {
  secrets = var.secrets

  selected_password_fields = {
    for k in keys(local.secrets) : k => (
      local.secrets[k].password_section == null
      ? merge({}, [
        for section in data.onepassword_item.password_item[k].section : {
          for field in section.field : field.label => field
        } if length(section.field) > 0
      ]...)
      : try(data.onepassword_item.password_item[k].section_map[local.secrets[k].password_section].field_map, {})
    )
  }
  all_passwords = {
    for k in keys(local.secrets) : k => {
      for label, field in local.selected_password_fields[k] : label => field.value
      if can(local.secrets[k]["password_exclude"]) && !contains(coalesce(local.secrets[k]["password_exclude"], []), label)
    }
  }
  whitelist_passwords = {
    for k in keys(local.secrets) : k => {
      for label, field in local.selected_password_fields[k] : label => field.value
      if contains(coalesce(local.secrets[k].password_whitelist, []), label)
    }
  }
}

data "onepassword_item" "password_item" {
  for_each = local.secrets
  vault    = each.value.password_vault
  title    = each.value.password_title
}

resource "aws_secretsmanager_secret" "secret" {
  for_each = { for k, v in local.secrets : k => v if var.create }
  name     = coalesce(each.value["secret_prefix"], "") != "" ? "${each.value["secret_prefix"]}/${each.key}" : each.key
  tags     = local.tags
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  for_each = {
    for k in keys(local.secrets) : k => {
      secret_id     = aws_secretsmanager_secret.secret[k].id
      secret_string = jsonencode(local.all_passwords[k])
    } if var.create && length(coalesce(local.secrets[k].password_whitelist, [])) == 0
  }
  secret_id     = each.value.secret_id
  secret_string = each.value.secret_string

  lifecycle {
    precondition {
      condition = local.secrets[each.key].password_section == null ? true : (
        contains(
          keys(data.onepassword_item.password_item[each.key].section_map),
          local.secrets[each.key].password_section,
        )
      )
      error_message = "password_section must identify an existing 1Password item section."
    }
  }
}

resource "aws_secretsmanager_secret_version" "secret_version_whitelist" {
  for_each = {
    for k in keys(local.secrets) : k => {
      secret_id     = aws_secretsmanager_secret.secret[k].id
      secret_string = jsonencode(local.whitelist_passwords[k])
    } if var.create && length(coalesce(local.secrets[k].password_whitelist, [])) > 0
  }
  secret_id     = each.value.secret_id
  secret_string = each.value.secret_string

  lifecycle {
    precondition {
      condition = local.secrets[each.key].password_section == null ? true : (
        contains(
          keys(data.onepassword_item.password_item[each.key].section_map),
          local.secrets[each.key].password_section,
        )
      )
      error_message = "password_section must identify an existing 1Password item section."
    }

    precondition {
      condition = local.secrets[each.key].password_section == null ? true : (
        alltrue([
          for label in local.secrets[each.key].password_whitelist :
          try(length(local.whitelist_passwords[each.key][label]) > 0, false)
        ])
      )
      error_message = "Every password_whitelist field must exist and be populated in password_section."
    }
  }
}
