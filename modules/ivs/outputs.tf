output "ivs_configuration" {
  value = {
    for k, v in local.ivs_map : k => {
      "recording_configuration_arn" = try(aws_ivs_recording_configuration.recording_configuration[k].arn, null)
    }
  }
}
