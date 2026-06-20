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
          join("", aws_bedrockagentcore_agent_runtime.agentcore[*].agent_runtime_arn)
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
