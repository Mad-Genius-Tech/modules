data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  default_settings = {
    github_org_name        = ""
    policy                 = {}
    enable_ecs_task_policy = false
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  github_map = {
    for k, v in var.github_repos : k => {
      "identifier"             = "${module.context.id}-${k}"
      "create"                 = coalesce(lookup(v, "create", null), true)
      "github_org_name"        = v.github_org_name
      "github_repo_names"      = v.github_repo_names
      "policy"                 = coalesce(lookup(v, "policy", null), local.merged_default_settings.policy)
      "enable_ecs_task_policy" = coalesce(lookup(v, "enable_ecs_task_policy", null), local.merged_default_settings.enable_ecs_task_policy)
    } if coalesce(lookup(v, "create", null), true)
  }
}

data "aws_iam_openid_connect_provider" "github_actions" {
  count = var.create_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  count          = var.create_oidc_provider ? 1 : 0
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

data "aws_iam_policy_document" "github_actions_assume_role_policy" {
  for_each = { for k, v in local.github_map : k => v if v.create }
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = var.create_oidc_provider ? [aws_iam_openid_connect_provider.github_actions[0].arn] : [data.aws_iam_openid_connect_provider.github_actions[0].arn]
    }
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "token.actions.githubusercontent.com:iss"
      values   = ["https://token.actions.githubusercontent.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [
        for repo in each.value.github_repo_names : "repo:${each.value.github_org_name}/${repo}:*"
      ]
    }
  }
}

resource "aws_iam_role" "iam_role" {
  for_each           = { for k, v in local.github_map : k => v if v.create }
  name               = each.value.identifier
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role_policy[each.key].json
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  for_each   = local.role_policy
  role       = aws_iam_role.iam_role[split("|", each.key)[0]].name
  policy_arn = module.iam_policy[each.key].arn
}

locals {
  role_policy = merge([
    for k, v in local.github_map : {
      for k2, v2 in v.policy : "${k}|${k2}" => {
        name          = "${module.context.id}-${k}-${k2}"
        resources_arn = v2.resources_arn
        actions       = v2.actions
        conditions    = try(v2.conditions, null)
      }
    } if v.create && can(v.policy)
  ]...)
}

data "aws_iam_policy_document" "iam_policy" {
  for_each = local.role_policy
  statement {
    actions   = each.value.actions
    resources = each.value.resources_arn
    dynamic "condition" {
      for_each = can(each.value.conditions) && each.value.conditions != null ? each.value.conditions : {}
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

module "iam_policy" {
  for_each      = local.role_policy
  source        = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version       = "~> 5.30.0"
  create_policy = true
  name          = each.value.name
  policy        = data.aws_iam_policy_document.iam_policy[each.key].json
  tags          = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_policy_attachment" {
  for_each   = { for k, v in local.github_map : k => v if v.create && v.enable_ecs_task_policy }
  role       = aws_iam_role.iam_role[each.key].name
  policy_arn = aws_iam_policy.ecs_policy[each.key].arn
}

resource "aws_iam_policy" "ecs_policy" {
  for_each    = { for k, v in local.github_map : k => v if v.create && v.enable_ecs_task_policy }
  name        = "${each.value.identifier}-ecs"
  path        = "/"
  description = "Github ECS task update policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.ecs_cluster_name}-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
        ]
        Resource = [
          "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${var.ecs_cluster_name}/*"
        ]
      }
    ]
  })
}