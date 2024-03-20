
locals {
  default_role = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/terraform",
  ]

  default_settings = {
    key_administrators = distinct(concat(["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"], local.default_role))
    key_users          = []
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  kms_map = {
    for k, v in var.kms : k => {
      "identifier"         = "${module.context.id}-${k}"
      "key_administrators" = distinct(compact(concat(coalesce(lookup(v, "key_administrators", null), local.merged_default_settings.key_administrators), local.merged_default_settings.key_administrators)))
      "key_users"          = distinct(compact(concat(coalesce(lookup(v, "key_users", null), local.merged_default_settings.key_users), local.merged_default_settings.key_users)))
    } if coalesce(lookup(v, "create", null), true)
  }
}

data "aws_caller_identity" "current" {}

module "kms" {
  source             = "terraform-aws-modules/kms/aws"
  version            = "~> 2.0.0"
  for_each           = local.kms_map
  description        = "KMS key for ${each.value.identifier}"
  key_usage          = "ENCRYPT_DECRYPT"
  key_administrators = each.value.key_administrators
  key_users          = each.value.key_users
  aliases            = ["${each.value.identifier}", "${var.org_name}/${each.value.identifier}"]
  tags               = local.tags
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
