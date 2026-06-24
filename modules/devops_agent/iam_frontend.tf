resource "aws_iam_policy" "frontend" {
  count = var.enabled ? 1 : 0
  name  = "${module.context.id}-frontend"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
        ]
        Resource = [
          join("", aws_dynamodb_table.conversations[*].arn)
        ]
      },
      {
        Sid    = "InvokeAgentRuntime"
        Effect = "Allow"
        Action = [
          "bedrock-agentcore:InvokeAgentRuntime",
        ]
        Resource = [
          "arn:aws:bedrock-agentcore:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:runtime/${replace(module.context.id, "-", "_")}-*",
        ]
      },
      {
        Sid    = "ListAgentRuntimes"
        Effect = "Allow"
        Action = [
          "bedrock-agentcore:ListAgentRuntimes",
        ]
        Resource = [
          "arn:aws:bedrock-agentcore:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*",
        ]
      },
      {
        Sid    = "AttachmentUploads"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
        ]
        Resource = [
          "arn:aws:s3:::${var.attachment_s3_bucket}/*"
        ]
      },
    ]
  })

  tags = local.tags
}
