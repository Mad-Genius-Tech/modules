resource "aws_cognito_identity_pool" "identity_pool" {
  for_each                         = local.cognito_map
  identity_pool_name               = each.value.identifier
  allow_unauthenticated_identities = true
  allow_classic_flow               = false
  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.client[each.key].id
    provider_name           = aws_cognito_user_pool.user_pool[each.key].endpoint
    server_side_token_check = false
  }
  tags = local.tags
}

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  for_each         = local.cognito_map
  identity_pool_id = aws_cognito_identity_pool.identity_pool[each.key].id
  roles = {
    authenticated   = aws_iam_role.auth_iam_role[each.key].arn
    unauthenticated = aws_iam_role.guest_iam_role[each.key].arn
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "auth_iam_role" {
  for_each = local.cognito_map
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
    name = "chime-attachment"
    policy = jsonencode(
      {
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:PutObject",
              "s3:DeleteObject"
            ]
            Resource = [
              "arn:aws:s3:::contnt-${var.stage_name}-chat/protected/$${cognito-identity.amazonaws.com:sub}/*",
            ]
          },
          {
            Effect = "Allow"
            Action = [
              "s3:GetObject",
            ]
            Resource = ["arn:aws:s3:::contnt-${var.stage_name}-chat/protected/*"]
          }
        ]
      }
    )
  }

  inline_policy {
    name = "chime-user"
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
              "cognito-idp:ListUsers"
            ]
            Resource = [
              aws_cognito_user_pool.user_pool[each.key].arn
            ]
          },
          {
            Effect = "Allow"
            Action = [
              "chime:SendChannelMessage",
              "chime:GetChannelMessage",
              "chime:ListChannelMessages",
              "chime:CreateChannelMembership",
              "chime:ListChannelMemberships",
              "chime:DeleteChannelMembership",
              "chime:CreateChannelModerator",
              "chime:ListChannelModerators",
              "chime:DescribeChannelModerator",
              "chime:RegisterAppInstanceUserEndpoint",
              "chime:ListAppInstanceUserEndpoints",
              "chime:DescribeAppInstanceUserEndpoint",
              "chime:UpdateAppInstanceUserEndpoint",
              "chime:DeregisterAppInstanceUserEndpoint",
              "chime:PutChannelMembershipPreferences",
              "chime:GetChannelMembershipPreferences",
              "chime:CreateChannel",
              "chime:DescribeChannel",
              "chime:ListChannels",
              "chime:UpdateChannel",
              "chime:DeleteChannel",
              "chime:RedactChannelMessage",
              "chime:UpdateChannelMessage",
              "chime:Connect",
              "chime:ListChannelMembershipsForAppInstanceUser",
              "chime:CreateChannelBan",
              "chime:ListChannelBans",
              "chime:DeleteChannelBan",
              "chime:AssociateChannelFlow",
              "chime:DisassociateChannelFlow",
              "chime:DescribeChannelFlow",
              "chime:ListChannelFlows",
              "chime:ListChannelsModeratedByAppInstanceUser",
              "chime:ListSubChannels",
              "chime:UpdateChannelReadMarker",
              "chime:SearchChannels"
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
  for_each = local.cognito_map
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
    name = "chime-attachment"
    policy = jsonencode(
      {
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "mobileanalytics:PutEvents",
              "cognito-sync:*"
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