locals {
  default_runtime_environment = merge({
    BEDROCK_MODEL_ID         = join("", aws_bedrock_inference_profile.inference_profile[*].id)
    AGENT_SESSIONS_BUCKET    = var.session_s3_bucket
    AGENT_ATTACHMENTS_BUCKET = var.attachment_s3_bucket

    }, var.runtime_secrets_name != null ? {
    RUNTIME_SECRET_NAME = var.runtime_secrets_name
    } : {}
  )

  runtime_environment_variables = merge(
    local.default_runtime_environment,
    var.agentcore_environment_variables,
  )
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_secretsmanager_secret" "runtime" {
  count = var.runtime_secrets_name != null ? 1 : 0
  name  = var.runtime_secrets_name
}

data "aws_kms_key" "runtime_secret" {
  count = var.runtime_secrets_name != null ? 1 : 0
  key_id = (
    try(data.aws_secretsmanager_secret.runtime[0].kms_key_id, null) != null
    && data.aws_secretsmanager_secret.runtime[0].kms_key_id != ""
    ? data.aws_secretsmanager_secret.runtime[0].kms_key_id
    : "alias/aws/secretsmanager"
  )
}


module "agentcore_sg" {
  create  = var.enabled
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1.0"

  name        = "${module.context.id}-agentcore"
  description = "Security group for Bedrock AgentCore runtime"
  vpc_id      = var.vpc_id

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = local.tags
}


resource "aws_bedrockagentcore_agent_runtime" "agentcore" {
  count              = var.enabled ? 1 : 0
  agent_runtime_name = replace(module.context.id, "-", "_")
  role_arn           = join("", aws_iam_role.agentcore[*].arn)

  protocol_configuration {
    server_protocol = "HTTP"
  }

  environment_variables = local.runtime_environment_variables

  agent_runtime_artifact {
    container_configuration {
      container_uri = var.agentcore_image
    }
  }

  network_configuration {
    network_mode = "VPC"
    network_mode_config {
      security_groups = [module.agentcore_sg.security_group_id]
      subnets         = var.private_subnets
    }
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [
      agent_runtime_artifact,
    ]
  }
}
