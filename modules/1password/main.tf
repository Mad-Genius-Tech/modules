locals {
  secrets = var.secrets

  all_passwords = {
    for k in keys(local.secrets) : k => merge([
      for item in data.onepassword_item.password_item[k].section : {
        for secret in item["field"] : secret["label"] => secret["value"] if can(local.secrets[k]["password_exclude"]) && !contains(coalesce(local.secrets[k]["password_exclude"], []), secret["label"])
      } if length(item["field"]) > 0
    ]...)
  }
  whitelist_passwords = {
    for k in keys(local.secrets) : k => merge([
      for item in data.onepassword_item.password_item[k].section : {
        for secret in item["field"] : secret["label"] => secret["value"] if contains(coalesce(local.secrets[k].password_whitelist, []), secret["label"])
      } if length(item["field"]) > 0
    ]...)
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
}
