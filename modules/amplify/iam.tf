locals {
  # source: https://github.com/aws-amplify/amplify-cli/issues/4322#issuecomment-455022473
  default_actions = [
    "appsync:*",
    "amplify:*",
    "apigateway:POST",
    "apigateway:DELETE",
    "apigateway:PATCH",
    "apigateway:PUT",
    "cloudformation:CreateStack",
    "cloudformation:CreateStackSet",
    "cloudformation:DeleteStack",
    "cloudformation:DeleteStackSet",
    "cloudformation:DescribeStackEvents",
    "cloudformation:DescribeStackResource",
    "cloudformation:DescribeStackResources",
    "cloudformation:DescribeStackSet",
    "cloudformation:DescribeStackSetOperation",
    "cloudformation:DescribeStacks",
    "cloudformation:UpdateStack",
    "cloudformation:UpdateStackSet",
    "cloudfront:CreateCloudFrontOriginAccessIdentity",
    "cloudfront:CreateDistribution",
    "cloudfront:DeleteCloudFrontOriginAccessIdentity",
    "cloudfront:DeleteDistribution",
    "cloudfront:GetCloudFrontOriginAccessIdentity",
    "cloudfront:GetCloudFrontOriginAccessIdentityConfig",
    "cloudfront:GetDistribution",
    "cloudfront:GetDistributionConfig",
    "cloudfront:TagResource",
    "cloudfront:UntagResource",
    "cloudfront:UpdateCloudFrontOriginAccessIdentity",
    "cloudfront:UpdateDistribution",
    "cognito-identity:CreateIdentityPool",
    "cognito-identity:DeleteIdentityPool",
    "cognito-identity:DescribeIdentity",
    "cognito-identity:DescribeIdentityPool",
    "cognito-identity:SetIdentityPoolRoles",
    "cognito-identity:UpdateIdentityPool",
    "cognito-idp:CreateUserPool",
    "cognito-idp:CreateUserPoolClient",
    "cognito-idp:DeleteUserPool",
    "cognito-idp:DeleteUserPoolClient",
    "cognito-idp:DescribeUserPool",
    "cognito-idp:UpdateUserPool",
    "cognito-idp:UpdateUserPoolClient",
    "dynamodb:CreateTable",
    "dynamodb:DeleteItem",
    "dynamodb:DeleteTable",
    "dynamodb:DescribeTable",
    "dynamodb:PutItem",
    "dynamodb:UpdateItem",
    "dynamodb:UpdateTable",
    "iam:CreateRole",
    "iam:DeleteRole",
    "iam:DeleteRolePolicy",
    "iam:GetRole",
    "iam:GetUser",
    "iam:PassRole",
    "iam:PutRolePolicy",
    "iam:UpdateRole",
    "lambda:AddPermission",
    "lambda:CreateFunction",
    "lambda:DeleteFunction",
    "lambda:GetFunction",
    "lambda:GetFunctionConfiguration",
    "lambda:InvokeAsync",
    "lambda:InvokeFunction",
    "lambda:RemovePermission",
    "lambda:UpdateFunctionCode",
    "lambda:UpdateFunctionConfiguration",
    "s3:*",
    "logs:CreateLogStream",
    "logs:CreateLogGroup",
    "logs:DescribeLogGroups",
    "logs:PutLogEvents"
  ]
  iam_role_actions = length(var.iam_service_role_actions) > 0 ? var.iam_service_role_actions : local.default_actions
}

data "aws_iam_policy_document" "iam_policy" {
  count = var.create_iam_role ? 1 : 0
  statement {
    sid       = "AmplifyAccess"
    effect    = "Allow"
    resources = ["*"]
    actions   = local.iam_role_actions
  }
}

resource "aws_iam_policy" "iam_policy" {
  count  = var.create_iam_role ? 1 : 0
  name   = module.context.id
  path   = "/"
  policy = try(data.aws_iam_policy_document.iam_policy[0].json, "")
}

module "iam_role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version               = "~> 5.32.0"
  trusted_role_services = ["amplify.amazonaws.com"]
  create_role           = var.create_iam_role
  role_name             = module.context.id
  role_requires_mfa     = false
  custom_role_policy_arns = [
    try(aws_iam_policy.iam_policy[0].arn, "")
  ]
  tags = local.tags
}