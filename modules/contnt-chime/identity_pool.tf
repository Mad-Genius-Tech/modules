
# resource "aws_cognito_identity_pool" "identity" {
#   for_each                         = local.cognito_map
#   identity_pool_name               = each.value.identifier
#   allow_unauthenticated_identities = each.value.allow_unauthenticated_identities
#   allow_classic_flow               = false

#   # cognito_identity_providers {
#   #   client_id               = aws_cognito_user_pool_client.client.id
#   #   provider_name           = aws_cognito_user_pool.pool.endpoint
#   #   server_side_token_check = false
#   # }

#   # supported_login_providers = var.supported_login_providers
#   # dynamic "cognito_identity_providers" {
#   #   for_each = var.cognito_identity_providers

#   #   content {
#   #     client_id               = cognito_identity_providers.value.client_id
#   #     provider_name           = cognito_identity_providers.value.provider_name
#   #     server_side_token_check = cognito_identity_providers.value.server_side_token_check
#   #   }
#   # }
# }

# resource "aws_cognito_identity_pool_roles_attachment" "main" {
#   for_each         = local.cognito_map
#   identity_pool_id = aws_cognito_identity_pool.identity[each.key].id
#   roles = {
#     "authenticated"   = aws_iam_role.authenticated[each.key].arn
#     "unauthenticated" = each.value.allow_unauthenticated_identities ? aws_iam_role.unauthenticated[each.key].arn : null
#   }

#   # role_mapping {
#   #   ambiguous_role_resolution = var.role_mapping.ambiguous_role_resolution
#   #   identity_provider         = var.role_mapping.identity_provider
#   #   type                      = var.role_mapping.type
#   # }
# }


# resource "aws_iam_role" "authenticated" {
#   for_each = local.cognito_map
#   name     = "${each.value.identifier}-auth"
#   assume_role_policy = jsonencode(
#     {
#       Version = "2012-10-17"
#       Statement = [
#         {
#           Effect = "Allow"
#           Principal = {
#             Federated = "cognito-identity.amazonaws.com"
#           }
#           Action = "sts:AssumeRoleWithWebIdentity"
#           Condition = {
#             "StringEquals" = {
#               "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.identity[each.key].id
#             }
#             "ForAnyValue:StringLike" = {
#               "cognito-identity.amazonaws.com:amr" = "authenticated"
#             }
#           }
#         }
#       ]
#     }
#   )
#   tags = local.tags
# }

# resource "aws_iam_role_policy" "authenticated" {
#   for_each = local.cognito_map
#   name     = "${each.value.identifier}-auth-policy"
#   role     = aws_iam_role.authenticated[each.key].id
#   policy = jsonencode(
#     {
#       Version = "2012-10-17"
#       Statement = [
#         {
#           Effect = "Allow"
#           Action = [
#             "mobileanalytics:PutEvents",
#             "cognito-sync:*",
#             "cognito-identity:*",
#             "chime:GetMessagingSessionEndpoint"
#           ]
#           Resource = [
#             "*"
#           ]
#         },
#         {
#           Effect = "Allow"
#           Action = [
#             "s3:GetObject",
#             "s3:PutObject",
#             "s3:DeleteObject"
#           ]
#           Resource = [
#             "arn:aws:s3:::${data.aws_s3_bucket.arn}/protected/$${cognito-identity.amazonaws.com:sub}/*"
#           ]
#         },
#         {
#           Effect = "Allow"
#           Action = [
#             "s3:GetObject"
#           ]
#           Resource = [
#             "arn:aws:s3:::${data.aws_s3_bucket.arn}/protected/*"
#           ]
#         },
#         {
#           Effect = "Allow"
#           Action = [
#             "cognito-idp:ListUsers"
#           ]
#           Resource = [
#             aws_cognito_user_pools.user_pool.arn
#           ]
#         },
#         {
#           Effect = "Allow"
#           Action = [
#             "chime:SendChannelMessage",
#             "chime:GetChannelMessage",
#             "chime:ListChannelMessages",
#             "chime:CreateChannelMembership",
#             "chime:ListChannelMemberships",
#             "chime:DeleteChannelMembership",
#             "chime:CreateChannelModerator",
#             "chime:ListChannelModerators",
#             "chime:DescribeChannelModerator",
#             "chime:RegisterAppInstanceUserEndpoint",
#             "chime:ListAppInstanceUserEndpoints",
#             "chime:DescribeAppInstanceUserEndpoint",
#             "chime:UpdateAppInstanceUserEndpoint",
#             "chime:DeregisterAppInstanceUserEndpoint",
#             "chime:PutChannelMembershipPreferences",
#             "chime:GetChannelMembershipPreferences",
#             "chime:CreateChannel",
#             "chime:DescribeChannel",
#             "chime:ListChannels",
#             "chime:UpdateChannel",
#             "chime:DeleteChannel",
#             "chime:RedactChannelMessage",
#             "chime:UpdateChannelMessage",
#             "chime:Connect",
#             "chime:ListChannelMembershipsForAppInstanceUser",
#             "chime:CreateChannelBan",
#             "chime:ListChannelBans",
#             "chime:DeleteChannelBan",
#             "chime:AssociateChannelFlow",
#             "chime:DisassociateChannelFlow",
#             "chime:DescribeChannelFlow",
#             "chime:ListChannelFlows",
#             "chime:ListChannelsModeratedByAppInstanceUser",
#             "chime:ListSubChannels",
#           ]
#           Resource = [
#             "${local.chime_app_instance_arn}/user/$${cognito-identity.amazonaws.com:sub}",
#             "${local.chime_app_instance_arn}/channel/*",
#             "${local.chime_app_instance_arn}/channel-flow/*"
#           ]
#         },
#       ]
#     }
#   )
# }

data "aws_s3_bucket" "s3_chat_bucket" {
  count  = var.s3_chat_bucket_name != "" ? 1 : 0
  bucket = var.s3_chat_bucket_name
}

# resource "aws_iam_role" "unauthenticated" {
#   for_each = { for k, v in local.cognito_map : k => v if v.allow_unauthenticated_identities }
#   name     = "${each.value.identifier}-unauth"
#   assume_role_policy = jsonencode(
#     {
#       Version = "2012-10-17"
#       Statement = [
#         {
#           Effect = "Allow"
#           Principal = {
#             Federated = "cognito-identity.amazonaws.com"
#           }
#           Action = "sts:AssumeRoleWithWebIdentity"
#           Condition = {
#             "StringEquals" = {
#               "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.identity[each.key].id
#             }
#             "ForAnyValue:StringLike" = {
#               "cognito-identity.amazonaws.com:amr" = "unauthenticated"
#             }
#           }
#         }
#       ]
#     }
#   )
#   tags = local.tags
# }

# resource "aws_iam_role_policy" "unauthenticated" {
#   for_each = { for k, v in local.cognito_map : k => v if v.allow_unauthenticated_identities }
#   name     = "${each.value.identifier}-unauth-policy"
#   role     = aws_iam_role.unauthenticated[each.key].id
#   policy = jsonencode(
#     {
#       Version = "2012-10-17"
#       Statement = [
#         {
#           Effect = "Allow"
#           Action = [
#             "mobileanalytics:PutEvents",
#             "cognito-sync:*"
#           ]
#           Resource = [
#             "*"
#           ]
#         }
#       ]
#     }
#   )
# }