data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "efs" {
  source                          = "terraform-aws-modules/efs/aws"
  version                         = "1.6.0"
  create                          = var.efs_enabled
  name                            = module.context.id
  performance_mode                = local.merged_settings.efs_performance_mode
  throughput_mode                 = local.merged_settings.efs_throughput_mode
  provisioned_throughput_in_mibps = local.merged_settings.efs_throughput_mode == "provisioned" ? 256 : null
  attach_policy                   = true
  deny_nonsecure_transport        = false
  policy_statements = [
    {
      actions = [
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:ClientRootAccess",
        "elasticfilesystem:ClientMount"
      ],
      principals = [
        {
          type = "AWS"
          identifiers = [
            module.asg.iam_role_arn
          ]
        }
      ]
    }
  ]
  mount_targets              = { for k, v in zipmap(var.available_zone_names, var.private_subnet_ids) : k => { subnet_id = v } }
  security_group_description = "${module.context.id}-efs"
  security_group_vpc_id      = var.vpc_id
  security_group_rules = {
    vpc = {
      cidr_blocks = var.private_subnets_cidr_blocks
    }
  }
  tags = local.tags
}
