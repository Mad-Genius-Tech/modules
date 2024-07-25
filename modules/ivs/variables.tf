variable "ivs" {
  type = map(object({
    enable_awscc                           = optional(bool)
    recording_configuration_s3_bucket_name = string
    recording_reconnect_window_seconds     = optional(number)
    thumbnail_configuration = optional(object({
      recording_mode          = optional(string)
      target_interval_seconds = optional(number)
    }))
    create = optional(bool)
  }))
}