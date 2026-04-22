
locals {
  terraform_role = var.terraform_role == "" ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/terraform" : var.terraform_role

  default_settings = {
    create                           = true
    key_usage                        = "ENCRYPT_DECRYPT"
    key_administrators               = distinct(concat(["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"], [local.terraform_role]))
    key_users                        = []
    key_asymmetric_sign_verify_users = []
    customer_master_key_spec_by_usage = {
      ENCRYPT_DECRYPT = "SYMMETRIC_DEFAULT"
      SIGN_VERIFY     = "ECC_SECG_P256K1"
    }
    enable_key_rotation_by_usage = {
      ENCRYPT_DECRYPT = true
      SIGN_VERIFY     = false
    }
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  kms_map = {
    for k, v in var.kms : k => {
      "identifier" = "${module.context.id}-${k}"
      "key_usage"  = coalesce(lookup(v, "key_usage", null), local.merged_default_settings.key_usage)
      "customer_master_key_spec" = coalesce(
        lookup(v, "customer_master_key_spec", null),
        lookup(
          local.merged_default_settings.customer_master_key_spec_by_usage,
          coalesce(lookup(v, "key_usage", null), local.merged_default_settings.key_usage),
          local.merged_default_settings.customer_master_key_spec_by_usage[local.merged_default_settings.key_usage]
        )
      )
      "enable_key_rotation" = coalesce(
        lookup(v, "enable_key_rotation", null),
        lookup(
          local.merged_default_settings.enable_key_rotation_by_usage,
          coalesce(lookup(v, "key_usage", null), local.merged_default_settings.key_usage),
          local.merged_default_settings.enable_key_rotation_by_usage[local.merged_default_settings.key_usage]
        )
      )
      "key_administrators" = distinct(compact(concat(coalesce(lookup(v, "key_administrators", null), local.merged_default_settings.key_administrators), local.merged_default_settings.key_administrators)))
      "key_users"          = distinct(compact(concat(coalesce(lookup(v, "key_users", null), local.merged_default_settings.key_users), local.merged_default_settings.key_users)))
      "key_asymmetric_sign_verify_users" = distinct(compact(concat(
        coalesce(
          lookup(v, "key_asymmetric_sign_verify_users", null),
          coalesce(lookup(v, "key_usage", null), local.merged_default_settings.key_usage) == "SIGN_VERIFY" ? coalesce(lookup(v, "key_users", null), local.merged_default_settings.key_users) : local.merged_default_settings.key_asymmetric_sign_verify_users
        ),
        local.merged_default_settings.key_asymmetric_sign_verify_users
      )))
    } if coalesce(lookup(v, "create", null), local.merged_default_settings.create)
  }
}

data "aws_caller_identity" "current" {}

module "kms" {
  source                           = "terraform-aws-modules/kms/aws"
  version                          = "~> 2.0.0"
  for_each                         = local.kms_map
  description                      = "KMS key for ${each.value.identifier}"
  key_usage                        = each.value.key_usage
  customer_master_key_spec         = each.value.customer_master_key_spec
  enable_key_rotation              = each.value.enable_key_rotation
  key_administrators               = each.value.key_administrators
  key_users                        = each.value.key_users
  key_asymmetric_sign_verify_users = each.value.key_asymmetric_sign_verify_users
  aliases                          = ["${each.value.identifier}", "${var.org_name}/${each.value.identifier}"]
  tags                             = local.tags
}

locals {
  sops_dir = var.terragrunt_directory == "" ? [".", "../secretmanager"] : [var.terragrunt_directory, "${var.terragrunt_directory}/../secretmanager"]
}

resource "local_file" "sops" {
  for_each   = { for i in local.sops_dir : i => i if contains(keys(local.kms_map), "sops") }
  filename   = "${each.key}/.sops.yaml"
  content    = <<EOF
creation_rules:
  - path_regex: .*\.yaml$
    kms: "${module.kms["sops"].key_arn}"
EOF
  depends_on = [module.kms]
}
