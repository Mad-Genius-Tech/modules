variable "ivs" {
  type = map(object({
    recording_configuration_s3_bucket_name = string
    thumbnail_configuration                = optional(list(object({
      recording_mode          = optional(string)
      target_interval_seconds = optional(number)
    })))
    create = optional(bool)
  }))
}