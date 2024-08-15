locals {
  default_settings = {
    container = "mp4"
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  elastictranscoder_pipeline_map = {
    for k, v in var.elastictranscoder_pipeline : k => {
      "identifier"       = "${module.context.id}-${k}"
      "name"             = length("${module.context.id}-${k}") > 40 && v.name != null ? v.name : "${module.context.id}-${k}"
      "create"           = coalesce(lookup(v, "create", null), true)
      "container"        = coalesce(lookup(v, "container", null), local.merged_default_settings.container)
      "input_bucket"     = lookup(v, "input_bucket", null)
      "output_bucket"    = lookup(v, "output_bucket", null)
      "content_config"   = lookup(v, "content_config", null)
      "thumbnail_config" = lookup(v, "thumbnail_config", null)
      "content_config_permissions" = lookup(v, "content_config_permissions", null)
      "thumbnail_config_permissions" = lookup(v, "thumbnail_config_permissions", null)
      "notifications"    = lookup(v, "notifications", null)
    } if coalesce(lookup(v, "create", null), true)
  }

  elastictranscoder_preset_map = {
    for k, v in var.elastictranscoder_preset : k => {
      "identifier"          = "${module.context.id}-${k}"
      "name"                = length("${module.context.id}-${k}") > 40 && v.name != null ? v.name : "${module.context.id}-${k}"
      "create"              = coalesce(lookup(v, "create", null), true)
      "container"           = lookup(v, "container", null)
      "audio"               = lookup(v, "audio", null)
      "audio_codec_options" = lookup(v, "audio_codec_options", null)
      "thumbnails"          = lookup(v, "thumbnails", null)
      "video"               = lookup(v, "video", null)
      "video_codec_options" = lookup(v, "video_codec_options", null)
      "video_watermarks"    = lookup(v, "video_watermarks", [])
    } if coalesce(lookup(v, "create", null), true)
  }
}

output "elastictranscoder_pipeline_map" {
  value = local.elastictranscoder_pipeline_map
}

output "elastictranscoder_preset_map" {
  value = local.elastictranscoder_preset_map
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "transcoder_role" {
  for_each = local.elastictranscoder_pipeline_map
  name     = "${each.value.identifier}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elastictranscoder.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_sns_topic" "topic" {
  for_each = { for k,v in local.elastictranscoder_pipeline_map : k => v if var.enable_notification }
  name     = "${each.value.identifier}-sns"
  tags     = local.tags
}

resource "aws_iam_role_policy" "transcoder_policy" {
  for_each = local.elastictranscoder_pipeline_map
  name     = "${each.value.identifier}-policy"
  role     = aws_iam_role.transcoder_role[each.key].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:GetBucketAcl",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${each.value.input_bucket}",
          "arn:aws:s3:::${each.value.input_bucket}/*",
        ]
      },
      {
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${each.value.output_bucket}",
          "arn:aws:s3:::${each.value.output_bucket}/*",
        ]
      },
      {
        Action   = ["s3:HeadBucket"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "sns:Publish"
        ]
        Effect   = "Allow"
        Resource = aws_sns_topic.topic[each.key].arn
      },
      {
        Action = [
          "s3:*Delete*",
          "s3:*Policy*",
          "sns:*Remove*",
          "sns:*Delete*",
          "sns:*Permission*",
        ]
        Effect   = "Deny"
        Resource = "*"
      },
      {
        Action = [
          "elastictranscoder:ReadPipeline",
          "elastictranscoder:ReadPreset",
          "elastictranscoder:ReadJob",
          "elastictranscoder:CreateJob",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:elastictranscoder:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:job/*",
          "arn:aws:elastictranscoder:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:preset/*",
          aws_elastictranscoder_pipeline.pipeline[each.key].arn,
        ]
      }
    ]
  })
}

resource "aws_elastictranscoder_preset" "preset" {
  for_each    = local.elastictranscoder_preset_map
  name        = length("${each.value.identifier}-preset") > 40 ? each.value.name : "${each.value.identifier}-preset"
  description = "Elastictranscoder preset ${each.value.identifier}"
  container   = each.value.container

  dynamic "audio" {
    for_each = each.value.audio != null ? [each.value.audio] : []

    content {
      audio_packing_mode = lookup(audio.value, "audio_packing_mode", null)
      bit_rate           = lookup(audio.value, "bit_rate", null)
      channels           = lookup(audio.value, "channels", null)
      codec              = lookup(audio.value, "codec", null)
      sample_rate        = lookup(audio.value, "sample_rate", null)
    }
  }

  dynamic "audio_codec_options" {
    for_each = each.value.audio_codec_options != null ? [each.value.audio_codec_options] : []

    content {
      profile   = lookup(audio_codec_options.value, "profile", null)
      bit_depth = lookup(audio_codec_options.value, "bit_depth", null)
      bit_order = lookup(audio_codec_options.value, "bit_order", null)
      signed    = lookup(audio_codec_options.value, "signed", null)
    }
  }

  dynamic "thumbnails" {
    for_each = each.value.thumbnails != null ? [each.value.thumbnails] : []

    content {
      format         = lookup(thumbnails.value, "format", null)
      interval       = lookup(thumbnails.value, "interval", null)
      max_width      = lookup(thumbnails.value, "max_width", null)
      max_height     = lookup(thumbnails.value, "max_height", null)
      padding_policy = lookup(thumbnails.value, "padding_policy", null)
      sizing_policy  = lookup(thumbnails.value, "sizing_policy", null)
    }
  }

  dynamic "video" {
    for_each = each.value.video != null ? [each.value.video] : []

    content {
      aspect_ratio         = lookup(video.value, "aspect_ratio", null)
      bit_rate             = lookup(video.value, "bit_rate", null)
      codec                = lookup(video.value, "codec", null)
      display_aspect_ratio = lookup(video.value, "display_aspect_ratio", null)
      fixed_gop            = lookup(video.value, "fixed_gop", null)
      frame_rate           = lookup(video.value, "frame_rate", null)
      keyframes_max_dist   = lookup(video.value, "keyframes_max_dist", null)
      max_frame_rate       = lookup(video.value, "max_frame_rate", null)
      max_height           = lookup(video.value, "max_height", null)
      max_width            = lookup(video.value, "max_width", null)
      padding_policy       = lookup(video.value, "padding_policy", null)
      resolution           = lookup(video.value, "resolution", null)
      sizing_policy        = lookup(video.value, "sizing_policy", null)
    }
  }

  dynamic "video_watermarks" {
    for_each = each.value.video_watermarks

    content {
      id                = lookup(video_watermarks.value, "id", null)
      max_width         = lookup(video_watermarks.value, "max_width", null)
      max_height        = lookup(video_watermarks.value, "max_height", null)
      sizing_policy     = lookup(video_watermarks.value, "sizing_policy", null)
      horizontal_align  = lookup(video_watermarks.value, "horizontal_align", null)
      horizontal_offset = lookup(video_watermarks.value, "horizontal_offset", null)
      vertical_align    = lookup(video_watermarks.value, "vertical_align", null)
      vertical_offset   = lookup(video_watermarks.value, "vertical_offset", null)
      opacity           = lookup(video_watermarks.value, "opacity", null)
      target            = lookup(video_watermarks.value, "target", null)
    }
  }

  video_codec_options = each.value.video_codec_options != null ? {
    Profile                  = each.value.video_codec_options.Profile
    Level                    = each.value.video_codec_options.Level
    MaxReferenceFrames       = each.value.video_codec_options.MaxReferenceFrames
    InterlacedMode           = each.value.video_codec_options.InterlacedMode
    ColorSpaceConversionMode = each.value.video_codec_options.ColorSpaceConversionMode
  } : null

}

resource "aws_elastictranscoder_pipeline" "pipeline" {
  for_each      = local.elastictranscoder_pipeline_map
  name          = length("${each.value.identifier}-pipeline") > 40 ? each.value.identifier : "${each.value.identifier}-pipeline"
  input_bucket  = each.value.input_bucket
  output_bucket = each.value.output_bucket
  role          = aws_iam_role.transcoder_role[each.key].arn

  dynamic "content_config" {
    for_each = each.value.content_config != null ? [each.value.content_config] : []
    content {
      bucket        = lookup(content_config, "bucket", null)
      storage_class = lookup(content_config.value.storage_class, null)
    }
  }

  dynamic "content_config_permissions" {
    for_each = each.value.content_config_permissions != null ? [each.value.content_config_permissions] : []
    content {
      access       = lookup(content_config_permissions.value, "access", null)
      grantee      = lookup(content_config_permissions.value, "grantee", null)
      grantee_type = lookup(content_config_permissions.value, "grantee_type", null)
    }
  }

  dynamic "thumbnail_config" {
    for_each = each.value.thumbnail_config != null ? [each.value.thumbnail_config] : []
    content {
      bucket        = lookup(thumbnail_config, "bucket", null)
      storage_class = thumbnail_config.value.storage_class
    }
  }

  dynamic "thumbnail_config_permissions" {
    for_each = each.value.thumbnail_config_permissions != null ? [each.value.thumbnail_config_permissions] : []
    content {
      access       = lookup(thumbnail_config_permissions.value, "access", null)
      grantee      = lookup(thumbnail_config_permissions.value, "grantee", null)
      grantee_type = lookup(thumbnail_config_permissions.value, "grantee_type", null)
    }
  }

  dynamic "notifications" {
    for_each = var.enable_notification ? [1] : []
    content {
      completed   = try(each.value.notification.completed, aws_sns_topic.topic[each.key].arn)
      progressing = try(each.value.notification.progressing, null)
      error       = try(each.value.notification.error, aws_sns_topic.topic[each.key].arn)
      warning     = try(each.value.notification.warning, null)
    }
  }
}