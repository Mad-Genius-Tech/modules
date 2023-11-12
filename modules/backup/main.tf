
locals {
  default_settings = {
    selection_tag = []
    condition = {
      string_equals     = []
      string_not_equals = []
      string_like       = []
      string_not_like   = []
    }
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  backup_plans = {
    for k, v in var.backup_plans : k => merge(v, {
      "create"        = coalesce(lookup(v, "create", null), true)
      "identifier"    = "${module.context.id}-${k}"
      "selection_tag" = try(coalesce(lookup(v, "selection_tag", null), local.merged_default_settings.selection_tag), local.merged_default_settings.selection_tag)
      "condition"     = try(coalesce(lookup(v, "condition", null), local.merged_default_settings.condition), local.merged_default_settings.condition)
    }) if coalesce(lookup(v, "create", true), true)
  }
}

# AWS Backup vault
resource "aws_backup_vault" "vault" {
  count = var.enabled ? 1 : 0
  name  = module.context.id
  tags  = local.tags
}

# AWS Backup plan
resource "aws_backup_plan" "backup_plan" {
  for_each = local.backup_plans
  name     = each.value.identifier

  # Rules
  dynamic "rule" {
    for_each = each.value.rules
    content {
      rule_name                = coalesce(lookup(rule.value, "name", null), "${each.value.identifier}-${rule.key}")
      target_vault_name        = aws_backup_vault.vault[0].name
      schedule                 = lookup(rule.value, "schedule", null)
      start_window             = lookup(rule.value, "start_window", null)
      completion_window        = lookup(rule.value, "completion_window", null)
      enable_continuous_backup = lookup(rule.value, "enable_continuous_backup", null)
      recovery_point_tags      = merge(local.tags, lookup(rule.value, "recovery_point_tags", {}))

      dynamic "lifecycle" {
        for_each = length(lookup(rule.value, "lifecycle", {})) == 0 ? [] : [lookup(rule.value, "lifecycle", {})]
        content {
          cold_storage_after = lookup(lifecycle.value, "cold_storage_after", 0)
          delete_after       = lookup(lifecycle.value, "delete_after", 90)
        }
      }

    }
  }

  tags       = local.tags
  depends_on = [aws_backup_vault.vault]
}


data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup_role" {
  name               = "${module.context.id}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_role.name
}

resource "aws_backup_selection" "selection" {
  for_each      = local.backup_plans
  name          = each.value.identifier
  iam_role_arn  = aws_iam_role.backup_role.arn
  plan_id       = aws_backup_plan.backup_plan[each.key].id
  resources     = each.value.backup_resources
  not_resources = each.value.not_backup_resources

  condition {
    dynamic "string_equals" {
      for_each = lookup(each.value.condition, "string_equals", [])
      content {
        key   = lookup(string_equals.value, "key", null)
        value = lookup(string_equals.value, "value", null)
      }
    }
    dynamic "string_like" {
      for_each = lookup(each.value.condition, "string_like", [])
      content {
        key   = lookup(string_like.value, "key", null)
        value = lookup(string_like.value, "value", null)
      }
    }
    dynamic "string_not_equals" {
      for_each = lookup(each.value.condition, "string_not_equals", [])
      content {
        key   = lookup(string_not_equals.value, "key", null)
        value = lookup(string_not_equals.value, "value", null)
      }
    }
    dynamic "string_not_like" {
      for_each = lookup(each.value.condition, "string_not_like", [])
      content {
        key   = lookup(string_not_like.value, "key", null)
        value = lookup(string_not_like.value, "value", null)
      }
    }
  }

  dynamic "selection_tag" {
    for_each = each.value.selection_tag
    content {
      type  = selection_tag.value["type"]
      key   = selection_tag.value["key"]
      value = selection_tag.value["value"]
    }
  }
}