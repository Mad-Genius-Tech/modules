locals {
  default_settings = {
    recording_configuration_thumbnail_recording_mode          = "INTERVAL"
    recording_configuration_thumbnail_target_interval_seconds = 10
    thumbnail_configuration = [
      {
        recording_mode          = "INTERVAL"
        target_interval_seconds = 10
      }
    ]
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
      }
    )
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  ivs_map = {
    for k, v in var.ivs : k => {
      "identifier"                             = "${module.context.id}-${k}"
      "recording_configuration_s3_bucket_name" = v.recording_configuration_s3_bucket_name
      "thumbnail_configuration"                = try(coalesce(lookup(v, "thumbnail_configuration", null), local.merged_default_settings.thumbnail_configuration), local.merged_default_settings.thumbnail_configuration)
    } if coalesce(lookup(v, "create", null), true) == true
  }
}



resource "aws_ivs_recording_configuration" "recording_configuration" {
  for_each = local.ivs_map
  name     = "${each.value.identifier}-recording-configuration"
  destination_configuration {
    s3 {
      bucket_name = each.value.recording_configuration_s3_bucket_name
    }
  }
  dynamic "thumbnail_configuration" {
    for_each = each.value.thumbnail_configuration
    content {
      recording_mode          = lookup(thumbnail_configuration.value, "recording_mode")
      target_interval_seconds = lookup(thumbnail_configuration.value, "target_interval_seconds")
    }
  }
  tags = local.tags
}