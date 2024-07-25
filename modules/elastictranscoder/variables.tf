
variable "elastictranscoder_preset" {
  type = map(object({
    create    = optional(bool, true)
    container = optional(string)
    audio = optional(object({
      audio_packing_mode = optional(string)
      bit_rate           = optional(string)
      channels           = optional(string)
      codec              = optional(string)
      sample_rate        = optional(string)
    }))
    audio_codec_options = optional(object({
      profile   = optional(string)
      bit_depth = optional(string)
      bit_order = optional(string)
      signed    = optional(string)
    }))
    video = optional(object({
      aspect_ratio         = optional(string)
      bit_rate             = optional(string)
      codec                = optional(string)
      display_aspect_ratio = optional(string)
      frame_rate           = optional(string)
      keyframes_max_dist   = optional(string)
      fixed_gop            = optional(string)
      max_frame_rate       = optional(string)
      max_height           = optional(string)
      max_width            = optional(string)
      padding_policy       = optional(string)
      resolution           = optional(string)
      sizing_policy        = optional(string)
    }))
    video_codec_options = optional(object({
      Profile                  = optional(string)
      Level                    = optional(string)
      MaxReferenceFrames       = optional(number)
      InterlacedMode           = optional(string)
      ColorSpaceConversionMode = optional(string)
    }))
    thumbnails = optional(object({
      format         = optional(string, "png")
      interval       = optional(string)
      aspect_ratio   = optional(string)
      max_height     = optional(string)
      max_width      = optional(string)
      padding_policy = optional(string)
      resolution     = optional(string)
      sizing_policy  = optional(string)
    }))
    video_watermarks = optional(list(object({
      id                = optional(string)
      max_height        = optional(string)
      max_width         = optional(string)
      sizing_policy     = optional(string)
      horizontal_align  = optional(string)
      horizontal_offset = optional(string)
      vertical_align    = optional(string)
      vertical_offset   = optional(string)
      opacity           = optional(string)
      target            = optional(string)
    })))
  }))
}

variable "elastictranscoder_pipeline" {
  type = map(object({
    create        = optional(bool, true)
    container     = optional(string)
    input_bucket  = string
    output_bucket = string
    content_config = optional(object({
      storage_class = optional(string)
    }))
    content_config_permissions = optional(object({
      access = optional(string)
      grantee = optional(string)
      grantee_type = optional(string)
    }))
    thumbnail_config = optional(object({
      storage_class = optional(string)
    }))
    thumbnail_config_permissions = optional(object({
      access = optional(string)
      grantee = optional(string)
      grantee_type = optional(string)
    }))
    notifications = optional(object({
      completed   = optional(string)
      progressing = optional(string)
      error       = optional(string)
      warning     = optional(string)
    }))
  }))
}

variable "enable_notification" {
  type    = bool
  default = true
}