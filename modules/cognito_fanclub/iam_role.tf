
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "auth_iam_role" {
  for_each = { for k, v in local.cognito_map : k => v if v.create_identity_pool }
  name     = "${each.value.identifier}-authenticated"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            Federated = "cognito-identity.amazonaws.com"
          },
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.identity_pool[each.key].id
            }
            "ForAnyValue:StringLike" = {
              "cognito-identity.amazonaws.com:amr" = "authenticated"
            }
          }
        }
      ]
    }
  )

  inline_policy {
    name = "cognito"
    policy = jsonencode(
      {
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "cognito-identity:GetCredentialsForIdentity"
            ]
            Resource = [
              "*",
            ]
          }
        ]
      }
    )
  }

  inline_policy {
    name = "chime"
    policy = jsonencode(
      {
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "chime:GetMessagingSessionEndpoint"
            ]
            Resource = ["*"]
          },
          {
            Effect = "Allow"
            Action = [
              "chime:*"
            ]
            Resource = ["*"]
          },
          {
            Effect = "Allow"
            Action = [
              "chime:Connect",
              "chime:CreateChannelMembership",
              "chime:ListChannelMemberships",              "chime:CreateChannel",
              "chime:DescribeChannel",
              "chime:DeleteChannel",
              "chime:UpdateChannel",
              "chime:SearchChannels",
              "chime:UpdateChannelReadMarker",
              "chime:ListChannelMessages",
              "chime:RedactChannelMessage",
              "chime:SendChannelMessage",
            ]
            Resource = [
              "${var.app_instance_arn}/user/*",
              "${var.app_instance_arn}/channel/*",
              "${var.app_instance_arn}/channel-flow/*"
            ]
          }
        ]
      }
    )
  }

}


resource "aws_iam_role" "guest_iam_role" {
  for_each = { for k, v in local.cognito_map : k => v if v.create_identity_pool }
  name     = "${each.value.identifier}-guest"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            Federated = "cognito-identity.amazonaws.com"
          },
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.identity_pool[each.key].id
            }
            "ForAnyValue:StringLike" = {
              "cognito-identity.amazonaws.com:amr" = "unauthenticated"
            }
          }
        }
      ]
    }
  )

  inline_policy {
    name = "cognito"
    policy = jsonencode(
      {
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "cognito-identity:GetCredentialsForIdentity"
            ]
            Resource = [
              "*",
            ]
          }
        ]
      }
    )
  }

}