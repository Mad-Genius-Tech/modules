locals {
  aws_deny_statements = concat(
    [
      {
        Sid    = "DenySsmParameterValues"
        Effect = "Deny"
        Action = [
          "ssm:GetParameter*"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyKmsDecrypt"
        Effect = "Deny"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext",
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "kms:ViaService" = "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      },
      {
        Sid    = "DenyAssumeRole"
        Effect = "Deny"
        Action = [
          "sts:AssumeRole",
          "sts:AssumeRoleWithSAML",
          "sts:AssumeRoleWithWebIdentity",
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyS3ObjectReadsWithException"
        Effect = "Deny"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
        ]
        NotResource = [
          "arn:aws:s3:::${var.session_s3_bucket}/*",
          "arn:aws:s3:::${var.attachment_s3_bucket}/*",
        ]
      },
      {
        Sid    = "DenyDynamoDbRead"
        Effect = "Deny"
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:TransactGetItems",
          "dynamodb:PartiQLSelect",
          "dynamodb:ExecuteStatement",
          "dynamodb:ExecuteTransaction",
          "dynamodb:GetRecords",
        ]
        Resource = "*"
      },
    ],
    var.runtime_secrets_name != null ? [
      {
        Sid    = "DenySecretValuesWithException"
        Effect = "Deny"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:BatchGetSecretValue",
        ]
        NotResource = [
          data.aws_secretsmanager_secret.runtime[0].arn,
        ]
      },
    ] : [],
    var.runtime_secrets_name == null ? [
      {
        Sid    = "DenySecretValues"
        Effect = "Deny"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:BatchGetSecretValue",
        ]
        Resource = "*"
      },
    ] : [],
  )
}

resource "aws_iam_role_policy_attachment" "readonly" {
  count      = var.enabled ? 1 : 0
  role       = join("", aws_iam_role.agentcore[*].name)
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "billing_readonly" {
  count      = var.enabled ? 1 : 0
  role       = join("", aws_iam_role.agentcore[*].name)
  policy_arn = "arn:aws:iam::aws:policy/AWSBillingReadOnlyAccess"
}

resource "aws_iam_role_policy" "deny" {
  count = var.enabled ? 1 : 0
  name  = "${module.context.id}-deny"
  role  = join("", aws_iam_role.agentcore[*].name)

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.aws_deny_statements
  })
}
