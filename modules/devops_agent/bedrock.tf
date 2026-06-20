locals {
  source_inference_profile_id = "arn:aws:bedrock:${data.aws_region.current.name}::inference-profile/us.anthropic.claude-sonnet-4-6"
}
resource "aws_bedrock_inference_profile" "inference_profile" {
  count = var.enabled ? 1 : 0
  name  = "${module.context.id}-profile"

  model_source {
    copy_from = local.source_inference_profile_id
  }

  tags = local.tags
}
