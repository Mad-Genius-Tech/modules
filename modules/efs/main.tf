
locals {
  default_settings = {
    performance_mode                 = "generalPurpose"
    throughput_mode                  = "bursting"
    enable_backup_policy             = false
    create_replication_configuration = false
    encrypted                        = true
    access_points                    = {}
    tags                             = {}
    iam_roles_read_access            = []
    iam_roles_write_access           = []
    iam_roles_root_access            = []
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
      }
    )
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  efs_map = {
    for k, v in var.efs : k => {
      "identifier"                       = "${module.context.id}-${k}"
      "create_replication_configuration" = try(coalesce(lookup(v, "create_replication_configuration", null), local.merged_default_settings.create_replication_configuration), local.merged_default_settings.create_replication_configuration)
      "enable_backup_policy"             = try(coalesce(lookup(v, "enable_backup_policy", null), local.merged_default_settings.enable_backup_policy), local.merged_default_settings.enable_backup_policy)
      "performance_mode"                 = try(coalesce(lookup(v, "performance_mode", null), local.merged_default_settings.performance_mode), local.merged_default_settings.performance_mode)
      "throughput_mode"                  = try(coalesce(lookup(v, "throughput_mode", null), local.merged_default_settings.throughput_mode), local.merged_default_settings.throughput_mode)
      "encrypted"                        = try(coalesce(lookup(v, "encrypted", null), local.merged_default_settings.encrypted), local.merged_default_settings.encrypted)
      "access_points"                    = merge(coalesce(lookup(v, "access_points", null), {}), local.merged_default_settings.access_points)
      "tags"                             = merge(coalesce(lookup(v, "tags", null), {}), local.merged_default_settings.tags)
      "iam_roles_read_access"            = coalesce(lookup(v, "iam_roles_read_access", []), local.merged_default_settings.iam_roles_read_access)
      "iam_roles_write_access"           = coalesce(lookup(v, "iam_roles_write_access", []), local.merged_default_settings.iam_roles_write_access)
      "iam_roles_root_access"            = coalesce(lookup(v, "iam_roles_root_access", []), local.merged_default_settings.iam_roles_root_access)
    } if coalesce(lookup(v, "create", true), true)
  }
}

data "aws_subnet" "private_subnet" {
  for_each = toset(var.private_subnet_ids)
  id       = each.value
}

locals {
  subnet_list  = [for s in data.aws_subnet.private_subnet : { id = s.id, az = s.availability_zone }]
  az_to_subnet = { for entry in local.subnet_list : entry.az => { subnet_id = entry.id } }
  single_az    = length(keys(local.az_to_subnet)) == 1 ? keys(local.az_to_subnet)[0] : null
}

data "aws_caller_identity" "current" {}

module "efs" {
  source                                    = "terraform-aws-modules/efs/aws"
  version                                   = "~> 1.8.0"
  for_each                                  = local.efs_map
  name                                      = each.value.identifier
  performance_mode                          = each.value.performance_mode
  throughput_mode                           = each.value.throughput_mode
  encrypted                                 = each.value.encrypted
  enable_backup_policy                      = each.value.enable_backup_policy
  create_replication_configuration          = each.value.create_replication_configuration
  availability_zone_name                    = local.single_az
  mount_targets                             = local.az_to_subnet
  deny_nonsecure_transport_via_mount_target = false
  policy_statements = concat([
    {
      sid = "AllowAdminDescribeAccess"
      actions = [
        "elasticfilesystem:Describe*"
      ]
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/terraform"]
        }
      ]
    }
    ],
    [
      for role_arn in each.value.iam_roles_read_access : {
        sid = "AllowReadAccess"
        actions = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:DescribeFileSystems",
        ]
        principals = [
          {
            type        = "AWS"
            identifiers = [role_arn]
          }
        ]
      }
    ],
    [
      for role_arn in each.value.iam_roles_write_access : {
        sid = "AllowWriteAccess"
        actions = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:DescribeFileSystems",
        ]
        principals = [
          {
            type        = "AWS"
            identifiers = [role_arn]
          }
        ]
      }
    ],
    [
      for role_arn in each.value.iam_roles_root_access : {
        sid = "AllowRootAccess"
        actions = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess",
          "elasticfilesystem:DescribeFileSystems",
        ]
        principals = [
          {
            type        = "AWS"
            identifiers = [role_arn]
          }
        ]
      }
  ])
  access_points         = each.value.access_points
  security_group_vpc_id = var.vpc_id
  security_group_rules = {
    2049 = {
      # relying on the defaults provided for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = var.ingress_cidr_blocks
    }
    2999 = {
      from_port   = 2999
      to_port     = 2999
      description = "EFS TLS ingress from VPC private subnets"
      protocol    = "tcp"
      cidr_blocks = var.ingress_cidr_blocks
    }
  }
  tags = merge(local.tags, each.value.tags)
}