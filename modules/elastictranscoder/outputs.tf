output "pipeline_id" {
  value = {
    for pipeline in aws_elastictranscoder_pipeline.pipeline : pipeline.name => pipeline.id
  }
}

output "pipeline_arn" {
  value = {
    for pipeline in aws_elastictranscoder_pipeline.pipeline : pipeline.name => pipeline.arn
  }
}

output "preset_id" {
  value = {
    for preset in aws_elastictranscoder_preset.preset : preset.name => preset.id
  }
}

output "preset_arn" {
  value = {
    for preset in aws_elastictranscoder_preset.preset : preset.name => preset.arn
  }
}

output "sns_topic_arn" {
  value = {
    for topic in aws_sns_topic.topic : topic.name => topic.arn
  }
}