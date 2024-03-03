locals {
  default_settings = {
    database_engine_version                        = "8.0"
    database_min_capacity                          = 0.5
    database_max_capacity                          = 2.0
    database_monitoring_interval                   = 0
    database_master_username                       = "root"
    database_name                                  = "wordpress"
    database_performance_insights_enabled          = false
    database_performance_insights_retention_period = 1
    database_backup_retention_period               = 1

    efs_performance_mode = "generalPurpose"
    efs_throughput_mode  = "bursting"
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        database_min_capacity                          = 0.5
        database_max_capacity                          = 4.0
        database_monitoring_interval                   = 60
        database_performance_insights_enabled          = false
        database_performance_insights_retention_period = 1
        database_backup_retention_period               = 7
        efs_performance_mode                           = "generalPurpose" # "maxIO"
        efs_throughput_mode                            = "bursting"       # "provisioned"
      }
    )
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  merged_settings = {
    database_engine_version                        = coalesce(var.database_engine_version, local.merged_default_settings.database_engine_version)
    database_min_capacity                          = coalesce(var.database_min_capacity, local.merged_default_settings.database_min_capacity)
    database_max_capacity                          = coalesce(var.database_max_capacity, local.merged_default_settings.database_max_capacity)
    database_monitoring_interval                   = coalesce(var.database_monitoring_interval, local.merged_default_settings.database_monitoring_interval)
    database_master_username                       = coalesce(var.database_master_username, local.merged_default_settings.database_master_username)
    database_name                                  = coalesce(var.database_name, local.merged_default_settings.database_name)
    efs_performance_mode                           = coalesce(var.efs_performance_mode, local.merged_default_settings.efs_performance_mode)
    efs_throughput_mode                            = coalesce(var.efs_throughput_mode, local.merged_default_settings.efs_throughput_mode)
    database_performance_insights_enabled          = coalesce(var.database_performance_insights_enabled, local.merged_default_settings.database_performance_insights_enabled)
    database_performance_insights_retention_period = coalesce(var.database_performance_insights_retention_period, local.merged_default_settings.database_performance_insights_retention_period)
    database_backup_retention_period               = coalesce(var.database_backup_retention_period, local.merged_default_settings.database_backup_retention_period)
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${module.context.id}-db-subnets"
  subnet_ids = var.private_subnet_ids
  tags       = local.tags
}

resource "random_string" "final_snapshot" {
  length  = 6
  special = false
  upper   = false
}

module "aurora" {
  source               = "terraform-aws-modules/rds-aurora/aws"
  version              = "v9.1.0"
  name                 = module.context.id
  engine               = "aurora-mysql"
  engine_mode          = "provisioned"
  master_username      = local.merged_settings.database_master_username
  database_name        = local.merged_settings.database_name
  storage_encrypted    = true
  engine_version       = local.merged_settings.database_engine_version
  vpc_id               = var.vpc_id
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = var.private_subnets_cidr_blocks
    }
  }
  monitoring_interval                   = local.merged_settings.database_monitoring_interval
  performance_insights_enabled          = local.merged_settings.database_performance_insights_enabled
  performance_insights_retention_period = local.merged_settings.database_performance_insights_enabled ? local.merged_settings.database_performance_insights_retention_period : null
  backup_retention_period               = local.merged_settings.database_backup_retention_period
  apply_immediately                     = true
  final_snapshot_identifier             = "${module.context.id}-final-${random_string.final_snapshot.result}"
  serverlessv2_scaling_configuration = {
    min_capacity = local.merged_settings.database_min_capacity
    max_capacity = local.merged_settings.database_max_capacity
  }
  instance_class = "db.serverless"
  instances = {
    1 = {}
  }
  tags = local.tags
}

