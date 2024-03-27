resource "aws_cognito_identity_pool" "identity_pool" {
  for_each                         = { for k, v in local.cognito_map : k => v if v.create_identity_pool }
  identity_pool_name               = each.value.identifier
  allow_unauthenticated_identities = each.value.allow_unauthenticated_identities
  allow_classic_flow               = each.value.allow_classic_flow
  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.client[each.key].id
    provider_name           = aws_cognito_user_pool.user_pool[each.key].endpoint
    server_side_token_check = false
  }
  tags = local.tags
}

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  for_each         = { for k, v in local.cognito_map : k => v if v.create_identity_pool }
  identity_pool_id = aws_cognito_identity_pool.identity_pool[each.key].id
  roles = {
    authenticated   = aws_iam_role.auth_iam_role[each.key].arn
    unauthenticated = aws_iam_role.guest_iam_role[each.key].arn
  }
}
