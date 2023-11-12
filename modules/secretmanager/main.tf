locals {
  secrets_content = var.secret_yaml != "" ? yamldecode(var.secret_yaml) : {}
  secret_prefix   = var.use_prefix ? (var.secret_prefix == "" ? "${var.org_name}-${var.stage_name}" : var.secret_prefix) : ""
}

resource "aws_secretsmanager_secret" "secret" {
  for_each = { for k, v in local.secrets_content : k => v if var.create }
  name     = "${local.secret_prefix}/${each.key}"
  tags     = local.tags
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  for_each = {
    for path, kv in local.secrets_content : path => {
      secret_id     = aws_secretsmanager_secret.secret[path].id
      secret_string = jsonencode(kv)
    } if var.create
  }
  secret_id     = each.value.secret_id
  secret_string = each.value.secret_string
}
