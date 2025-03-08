
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
            Resource = ["arn:aws:s3:::${var.org_name}-${var.stage_name}-chat/protected/*"]
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
              "chime:SearchChannels",
              # "chime:DeleteChannelMessage",
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

  inline_policy {
    name = "ivs"
    policy = jsonencode(
      {
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow",
            Action = [
              "ivs:BatchGetChannel",
              "ivs:BatchGetStreamKey",
              "ivs:CreateRecordingConfiguration",
              "ivs:GetChannel",
              "ivs:GetParticipant",
              "ivs:GetRecordingConfiguration",
              "ivs:GetStream",
              "ivs:GetStreamKey",
              "ivs:GetStreamSession",
              "ivs:ListChannels",
              "ivs:ListParticipantEvents",
              "ivs:ListParticipants",
              "ivs:ListRecordingConfigurations",
              "ivs:ListStreamKeys",
              "ivs:ListStreamSessions",
              "ivs:ListStreams",
              "ivschat:CreateChatToken",
              "ivschat:DeleteMessage",
              "ivschat:DisconnectUser",
              "ivschat:GetRoom",
              "ivschat:ListRooms",
              "ivschat:SendEvent",
            ],
            Resource = "*"
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