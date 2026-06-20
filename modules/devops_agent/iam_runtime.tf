resource "aws_iam_role" "agentcore" {
  count = var.enabled ? 1 : 0
  name  = "${module.context.id}-agentcore"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AssumeRolePolicy"
        Effect = "Allow"
        Principal = {
          Service = "bedrock-agentcore.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:bedrock-agentcore:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "agentcore" {
  count = var.enabled ? 1 : 0
  name  = "${module.context.id}-agentcore"
  role  = join("", aws_iam_role.agentcore[*].id)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "BedrockModelInvocation"
          Effect = "Allow"
          Action = [
            "bedrock:InvokeModel",
            "bedrock:InvokeModelWithResponseStream",
            "bedrock:Converse",
            "bedrock:ConverseStream",
          ]
          Resource = [
            "arn:aws:bedrock:*::foundation-model/*",
            "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*",
          ]
        },
        {
          Sid    = "AgentSessionsBucket"
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:ListBucket",
          ]
          Resource = [
            "arn:aws:s3:::${var.session_s3_bucket}",
            "arn:aws:s3:::${var.session_s3_bucket}/*",
          ]
        },
        {
          Sid    = "AgentAttachmentsRead"
          Effect = "Allow"
          Action = [
            "s3:GetObject",
          ]
          Resource = [
            "arn:aws:s3:::${var.attachment_s3_bucket}/*"
          ]
        },
        {
          Sid    = "RuntimeContainerPull"
          Effect = "Allow"
          Action = [
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetAuthorizationToken",
          ]
          Resource = [
            "*"
          ]
        },
        {
          Sid    = "AgentCoreRuntimeLogs"
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
          ]
          Resource = [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*",
          ]
        },
        {
          Sid    = "AgentCoreMetrics"
          Effect = "Allow"
          Action = [
            "cloudwatch:PutMetricData",
          ]
          Resource = "*"
          Condition = {
            StringEquals = {
              "cloudwatch:namespace" = "bedrock-agentcore"
            }
          }
        },
        {
          Sid    = "XRayTracing"
          Effect = "Allow"
          Action = [
            "xray:PutTraceSegments",
            "xray:PutTelemetryRecords",
            "xray:GetSamplingRules",
            "xray:GetSamplingTargets",
          ]
          Resource = ["*"]
        },
      ],
      var.runtime_secrets_name != null ? [
        {
          Sid    = "RuntimeSecrets"
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue"
          ]
          Resource = [
            data.aws_secretsmanager_secret.runtime[0].arn
          ]
        },
      ] : [],
      var.runtime_secrets_name != null ? [
        {
          Sid    = "RuntimeSecretsKms"
          Effect = "Allow"
          Action = [
            "kms:Decrypt",
            "kms:DescribeKey",
          ]
          Resource = [
            data.aws_kms_key.runtime_secret[0].arn
          ]
          Condition = {
            StringEquals = {
              "kms:ViaService"                  = "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
              "kms:EncryptionContext:SecretARN" = data.aws_secretsmanager_secret.runtime[0].arn
            }
          }
        },
      ] : []
    )
  })
}
