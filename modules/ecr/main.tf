data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  default_settings = {
    repository_force_delete         = false
    repository_type                 = "private"
    repository_image_tag_mutability = "MUTABLE"
    repository_encryption_type      = null
    repository_image_scan_on_push   = false
    attach_repository_policy        = false
    repository_policy               = null
    enable_lambda_download          = false
    lamda_repository_policy         = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "LambdaECRImageRetrievalPolicy",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": [
        "ecr:BatchGetImage",
        "ecr:DeleteRepositoryPolicy",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:SetRepositoryPolicy"
      ],
      "Condition": {
        "StringLike": {
          "aws:sourceArn": "arn:aws:${data.aws_region.current.name}:lambda::${data.aws_caller_identity.current.account_id}:function:*"
        }
      }
    }
  ]
}
EOF
    create_repository_policy        = false
    create_lifecycle_policy         = false
    repository_lifecycle_policy     = ""
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  ecr_map = {
    for k, v in var.ecr_repositories : k => {
      "identifier"                      = "${module.context.id}-${k}"
      "create"                          = coalesce(lookup(v, "create", null), true)
      "repository_force_delete"         = try(coalesce(lookup(v, "repository_force_delete", null), local.merged_default_settings.repository_force_delete), local.merged_default_settings.repository_force_delete)
      "repository_type"                 = try(coalesce(lookup(v, "repository_type", null), local.merged_default_settings.repository_type), local.merged_default_settings.repository_type)
      "repository_image_tag_mutability" = try(coalesce(lookup(v, "repository_image_tag_mutability", null), local.merged_default_settings.repository_image_tag_mutability), local.merged_default_settings.repository_image_tag_mutability)
      "repository_encryption_type"      = try(coalesce(lookup(v, "repository_encryption_type", null), local.merged_default_settings.repository_encryption_type), local.merged_default_settings.repository_encryption_type)
      "repository_image_scan_on_push"   = try(coalesce(lookup(v, "repository_image_scan_on_push", null), local.merged_default_settings.repository_image_scan_on_push), local.merged_default_settings.repository_image_scan_on_push)
      "attach_repository_policy"        = try(coalesce(lookup(v, "attach_repository_policy", null), local.merged_default_settings.attach_repository_policy), local.merged_default_settings.attach_repository_policy)
      "repository_policy"               = try(coalesce(lookup(v, "repository_policy", null), local.merged_default_settings.repository_policy), local.merged_default_settings.repository_policy)
      "enable_lambda_download"          = try(coalesce(lookup(v, "enable_lambda_download", null), false), false)
      "create_repository_policy"        = try(coalesce(lookup(v, "create_repository_policy", null), local.merged_default_settings.create_repository_policy), local.merged_default_settings.create_repository_policy)
      "create_lifecycle_policy"         = try(coalesce(lookup(v, "create_lifecycle_policy", null), local.merged_default_settings.create_lifecycle_policy), local.merged_default_settings.create_lifecycle_policy)
      "repository_lifecycle_policy"     = try(coalesce(lookup(v, "repository_lifecycle_policy", null), local.merged_default_settings.repository_lifecycle_policy), local.merged_default_settings.repository_lifecycle_policy)
    } if coalesce(lookup(v, "create", null), true)
  }
}

module "ecr_repository" {
  for_each                        = local.ecr_map
  source                          = "terraform-aws-modules/ecr/aws"
  version                         = "~> 1.6.0"
  create                          = each.value.create
  create_repository               = each.value.create
  repository_force_delete         = each.value.repository_force_delete
  repository_name                 = each.key
  repository_type                 = each.value.repository_type
  repository_image_tag_mutability = each.value.repository_image_tag_mutability
  repository_encryption_type      = each.value.repository_encryption_type
  repository_image_scan_on_push   = each.value.repository_image_scan_on_push
  attach_repository_policy        = each.value.attach_repository_policy
  repository_policy               = each.value.enable_lambda_download ? local.default_settings.lamda_repository_policy : each.value.repository_policy
  create_repository_policy        = each.value.create_repository_policy
  create_lifecycle_policy         = each.value.create_lifecycle_policy
  repository_lifecycle_policy     = each.value.repository_lifecycle_policy
  tags                            = local.tags
}

