
locals {
  default_settings = {
    hash_key                              = null
    range_key                             = null
    attributes                            = []
    server_side_encryption_enabled        = true
    deletion_protection_enabled           = false
    global_secondary_indexes              = []
    table_class                           = "STANDARD"
    billing_mode                          = "PROVISIONED"
    write_capacity                        = 5
    read_capacity                         = 5
    autoscaling_enabled                   = true
    ignore_changes_global_secondary_index = true
    autoscaling_read_enabled              = true
    autoscaling_read_scale_in_cooldown    = 50
    autoscaling_read_scale_out_cooldown   = 40
    autoscaling_read_target_value         = 45
    autoscaling_read_max_capacity         = 10
    autoscaling_write_enabled             = true
    autoscaling_write_scale_in_cooldown   = 50
    autoscaling_write_scale_out_cooldown  = 40
    autoscaling_write_target_value        = 45
    autoscaling_write_max_capacity        = 10
    autoscaling_indexes                   = {}
    stream_enabled                        = true
    stream_view_type                      = "NEW_AND_OLD_IMAGES"
    ttl_enabled                           = false
    ttl_attribute_name                    = ""
    point_in_time_recovery_enabled        = false
    tags                                  = {}

  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        tags = {
          "aws_backup" = "true"
        }
      }
    )
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  dynamodb_map = {
    for k, v in var.dynamodb : k => {
      "identifier"                            = "${module.context.id}-${k}"
      "table_name"                            = v.table_name
      "billing_mode"                          = try(coalesce(lookup(v, "billing_mode", null), local.merged_default_settings.billing_mode), local.merged_default_settings.billing_mode)
      "table_class"                           = try(coalesce(lookup(v, "table_class", null), local.merged_default_settings.table_class), local.merged_default_settings.table_class)
      "hash_key"                              = try(coalesce(lookup(v, "hash_key", null), local.merged_default_settings.hash_key), local.merged_default_settings.hash_key)
      "range_key"                             = try(coalesce(lookup(v, "range_key", null), local.merged_default_settings.range_key), local.merged_default_settings.range_key)
      "attributes"                            = try(coalesce(lookup(v, "attributes", null), local.merged_default_settings.attributes), local.merged_default_settings.attributes)
      "read_capacity"                         = try(coalesce(lookup(v, "read_capacity", null), local.merged_default_settings.read_capacity), local.merged_default_settings.read_capacity)
      "write_capacity"                        = try(coalesce(lookup(v, "write_capacity", null), local.merged_default_settings.write_capacity), local.merged_default_settings.write_capacity)
      "server_side_encryption_enabled"        = try(coalesce(lookup(v, "server_side_encryption_enabled", null), local.merged_default_settings.server_side_encryption_enabled), local.merged_default_settings.server_side_encryption_enabled)
      "global_secondary_indexes"              = try(coalesce(lookup(v, "global_secondary_indexes", null), local.merged_default_settings.global_secondary_indexes), local.merged_default_settings.global_secondary_indexes)
      "deletion_protection_enabled"           = try(coalesce(lookup(v, "deletion_protection_enabled", null), local.merged_default_settings.deletion_protection_enabled), local.merged_default_settings.deletion_protection_enabled)
      "autoscaling_enabled"                   = try(coalesce(lookup(v, "autoscaling_enabled", null), local.merged_default_settings.autoscaling_enabled), local.merged_default_settings.autoscaling_enabled)
      "ignore_changes_global_secondary_index" = try(coalesce(lookup(v, "ignore_changes_global_secondary_index", null), local.merged_default_settings.ignore_changes_global_secondary_index), local.merged_default_settings.ignore_changes_global_secondary_index)
      "autoscaling_read_enabled"              = try(coalesce(lookup(v, "autoscaling_read_enabled", null), local.merged_default_settings.autoscaling_read_enabled), local.merged_default_settings.autoscaling_read_enabled)
      "autoscaling_read_scale_in_cooldown"    = try(coalesce(lookup(v, "autoscaling_read_scale_in_cooldown", null), local.merged_default_settings.autoscaling_read_scale_in_cooldown), local.merged_default_settings.autoscaling_read_scale_in_cooldown)
      "autoscaling_read_scale_out_cooldown"   = try(coalesce(lookup(v, "autoscaling_read_scale_out_cooldown", null), local.merged_default_settings.autoscaling_read_scale_out_cooldown), local.merged_default_settings.autoscaling_read_scale_out_cooldown)
      "autoscaling_read_target_value"         = try(coalesce(lookup(v, "autoscaling_read_target_value", null), local.merged_default_settings.autoscaling_read_target_value), local.merged_default_settings.autoscaling_read_target_value)
      "autoscaling_read_max_capacity"         = try(coalesce(lookup(v, "autoscaling_read_max_capacity", null), local.merged_default_settings.autoscaling_read_max_capacity), local.merged_default_settings.autoscaling_read_max_capacity)
      "autoscaling_write_enabled"             = try(coalesce(lookup(v, "autoscaling_write_enabled", null), local.merged_default_settings.autoscaling_write_enabled), local.merged_default_settings.autoscaling_write_enabled)
      "autoscaling_write_scale_in_cooldown"   = try(coalesce(lookup(v, "autoscaling_write_scale_in_cooldown", null), local.merged_default_settings.autoscaling_write_scale_in_cooldown), local.merged_default_settings.autoscaling_write_scale_in_cooldown)
      "autoscaling_write_scale_out_cooldown"  = try(coalesce(lookup(v, "autoscaling_write_scale_out_cooldown", null), local.merged_default_settings.autoscaling_write_scale_out_cooldown), local.merged_default_settings.autoscaling_write_scale_out_cooldown)
      "autoscaling_write_target_value"        = try(coalesce(lookup(v, "autoscaling_write_target_value", null), local.merged_default_settings.autoscaling_write_target_value), local.merged_default_settings.autoscaling_write_target_value)
      "autoscaling_write_max_capacity"        = try(coalesce(lookup(v, "autoscaling_write_max_capacity", null), local.merged_default_settings.autoscaling_write_max_capacity), local.merged_default_settings.autoscaling_write_max_capacity)
      "autoscaling_indexes"                   = merge(coalesce(lookup(v, "autoscaling_indexes", null), local.merged_default_settings.autoscaling_indexes), local.merged_default_settings.autoscaling_indexes)
      "ttl_enabled"                           = try(coalesce(lookup(v, "ttl_enabled", null), local.merged_default_settings.ttl_enabled), local.merged_default_settings.ttl_enabled)
      "ttl_attribute_name"                    = try(coalesce(lookup(v, "ttl_attribute_name", null), local.merged_default_settings.ttl_attribute_name), local.merged_default_settings.ttl_attribute_name)
      "stream_enabled"                        = try(coalesce(lookup(v, "stream_enabled", null), local.merged_default_settings.stream_enabled), local.merged_default_settings.stream_enabled)
      "stream_view_type"                      = try(coalesce(lookup(v, "stream_view_type", null), local.merged_default_settings.stream_view_type), local.merged_default_settings.stream_view_type)
      "point_in_time_recovery_enabled"        = try(coalesce(lookup(v, "point_in_time_recovery_enabled", null), local.merged_default_settings.point_in_time_recovery_enabled), local.merged_default_settings.point_in_time_recovery_enabled)
      "tags"                                  = merge(coalesce(lookup(v, "tags", null), {}), local.merged_default_settings.tags)
    } if coalesce(lookup(v, "create", true), true)
  }
}


module "dynamodb_table" {
  source                         = "terraform-aws-modules/dynamodb-table/aws"
  version                        = "~> 3.3.0"
  for_each                       = local.dynamodb_map
  name                           = each.value.table_name
  table_class                    = each.value.table_class
  hash_key                       = each.value.hash_key
  range_key                      = each.value.range_key
  billing_mode                   = each.value.billing_mode
  write_capacity                 = each.value.billing_mode == "PROVISIONED" ? each.value.write_capacity : null
  read_capacity                  = each.value.billing_mode == "PROVISIONED" ? each.value.read_capacity : null
  server_side_encryption_enabled = each.value.server_side_encryption_enabled
  attributes                     = each.value.attributes
  global_secondary_indexes       = each.value.global_secondary_indexes
  deletion_protection_enabled    = each.value.deletion_protection_enabled
  point_in_time_recovery_enabled = each.value.point_in_time_recovery_enabled
  stream_enabled                 = each.value.stream_enabled
  stream_view_type               = each.value.stream_enabled ? each.value.stream_view_type : null

  autoscaling_read = each.value.autoscaling_read_enabled ? {
    scale_in_cooldown  = each.value.autoscaling_read_scale_in_cooldown
    scale_out_cooldown = each.value.autoscaling_read_scale_out_cooldown
    target_value       = each.value.autoscaling_read_target_value
    max_capacity       = each.value.autoscaling_read_max_capacity
  } : null

  autoscaling_write = each.value.autoscaling_write_enabled ? {
    scale_in_cooldown  = each.value.autoscaling_write_scale_in_cooldown
    scale_out_cooldown = each.value.autoscaling_write_scale_out_cooldown
    target_value       = each.value.autoscaling_write_target_value
    max_capacity       = each.value.autoscaling_write_max_capacity
  } : null

  autoscaling_indexes = length(each.value.autoscaling_indexes) > 0 ? each.value.autoscaling_indexes : null

  tags = merge(local.tags, each.value.tags)
}

resource "aws_iam_policy" "dynamodb_fullaccess" {
  count       = length(module.dynamodb_table) > 0 ? 1 : 0
  name        = "${module.context.id}-fullaccess"
  path        = "/"
  description = "DynamoDB policy for ${module.context.id}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["dynamodb:*"],
        Effect   = "Allow"
        Resource = [for table in module.dynamodb_table : table.dynamodb_table_arn]
      },
    ]
  })
  tags = local.tags
}
