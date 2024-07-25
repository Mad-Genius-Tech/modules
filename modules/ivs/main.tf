locals {
  default_settings = {
    enable_awscc = false
    recording_configuration_thumbnail_recording_mode          = "INTERVAL"
    recording_reconnect_window_seconds  = 0
    recording_configuration_thumbnail_target_interval_seconds = 10
    thumbnail_configuration = {
      recording_mode          = "INTERVAL"
      storage                 = ["LATEST"]
      target_interval_seconds = 10
    }
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
      "enable_awscc" = try(coalesce(lookup(v, "enable_awscc", null), local.merged_default_settings.enable_awscc), local.merged_default_settings.enable_awscc)
      "recording_configuration_s3_bucket_name" = v.recording_configuration_s3_bucket_name
      "recording_reconnect_window_seconds" = coalesce(v.recording_reconnect_window_seconds, local.default_settings.recording_reconnect_window_seconds)
      "thumbnail_configuration"                = try(coalesce(lookup(v, "thumbnail_configuration", null), local.merged_default_settings.thumbnail_configuration), local.merged_default_settings.thumbnail_configuration)
    } if coalesce(lookup(v, "create", null), true) == true
  }
}

resource "aws_ivs_recording_configuration" "recording_configuration" {
  for_each = { for k,v in local.ivs_map : k => v if !v.enable_awscc }
  name     = "${each.value.identifier}-recording-configuration"
  recording_reconnect_window_seconds = each.value.recording_reconnect_window_seconds
  destination_configuration {
    s3 {
      bucket_name = each.value.recording_configuration_s3_bucket_name
    }
  }
  dynamic "thumbnail_configuration" {
    for_each = each.value.thumbnail_configuration != null ? [1] : []
    content {
      recording_mode          = each.value.thumbnail_configuration.recording_mode
      target_interval_seconds = each.value.thumbnail_configuration.recording_mode == "INTERVAL" ? each.value.thumbnail_configuration.target_interval_seconds : null
    }
  }
  tags = local.tags

  lifecycle {
    ignore_changes = [tags]
  }
}
# AWS_PROFILE=contnt terragrunt state rm 'awscc_ivs_recording_configuration.recording_configuration["1"]'
# AWS_PROFILE=contnt terragrunt import 'aws_ivs_recording_configuration.recording_configuration["1"]' 'arn:aws:ivs:us-west-2:765602075515:recording-configuration/rebeTY2RG5jQ'

# output "ivs_map" {
#   value = local.ivs_map
# }

resource "awscc_ivs_recording_configuration" "recording_configuration" {
  for_each = { for k,v in local.ivs_map : k => v if v.enable_awscc }
  name     = "${each.value.identifier}-recording-configuration"
  recording_reconnect_window_seconds = each.value.recording_reconnect_window_seconds
  destination_configuration = {
    s3 = {
      bucket_name = each.value.recording_configuration_s3_bucket_name
    }
  }
  thumbnail_configuration = {
    recording_mode          = each.value.thumbnail_configuration.recording_mode
    storage                 = each.value.thumbnail_configuration.storage
    target_interval_seconds = each.value.thumbnail_configuration.recording_mode == "INTERVAL" ? each.value.thumbnail_configuration.target_interval_seconds : null
  }
  tags = [
    for k, v in local.tags : {
      key   = k
      value = v
    }
  ]
  lifecycle {
    ignore_changes = [thumbnail_configuration.resolution]
  }
}