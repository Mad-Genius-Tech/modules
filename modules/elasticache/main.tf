
locals {
  default_settings = {
    node_type                  = "cache.t4g.micro"
    engine_version             = "6.2"
    transit_encryption_enabled = false
    at_rest_encryption_enabled = true
    auth_token                 = null
    multi_az_enabled           = false
    automatic_failover_enabled = false
    snapshot_retention_limit   = 0
    num_cache_clusters         = 1
    num_node_groups            = null
    replicas_per_node_group    = null
    auto_minor_version_upgrade = true
    kms_key_id                 = null
    parameters                 = {}
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        node_type                = "cache.t4g.medium"
        snapshot_retention_limit = 3
    })
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  redis_map = {
    for k, v in var.redis : k => {
      "identifier"                 = "${module.context.id}-${k}"
      "engine_version"             = try(coalesce(lookup(v, "engine_version", null), local.merged_default_settings.engine_version), local.merged_default_settings.engine_version)
      "node_type"                  = try(coalesce(lookup(v, "node_type", null), local.merged_default_settings.node_type), local.merged_default_settings.node_type)
      "transit_encryption_enabled" = try(coalesce(lookup(v, "transit_encryption_enabled", null), local.merged_default_settings.transit_encryption_enabled), local.merged_default_settings.transit_encryption_enabled)
      "auth_token"                 = try(coalesce(lookup(v, "auth_token", null), local.merged_default_settings.auth_token), local.merged_default_settings.auth_token)
      "at_rest_encryption_enabled" = try(coalesce(lookup(v, "at_rest_encryption_enabled", null), local.merged_default_settings.at_rest_encryption_enabled), local.merged_default_settings.at_rest_encryption_enabled)
      "multi_az_enabled"           = try(coalesce(lookup(v, "multi_az_enabled", null), local.merged_default_settings.multi_az_enabled), local.merged_default_settings.multi_az_enabled)
      "automatic_failover_enabled" = try(coalesce(lookup(v, "automatic_failover_enabled", null), local.merged_default_settings.automatic_failover_enabled), local.merged_default_settings.automatic_failover_enabled)
      "snapshot_retention_limit"   = try(coalesce(lookup(v, "snapshot_retention_limit", null), local.merged_default_settings.snapshot_retention_limit), local.merged_default_settings.snapshot_retention_limit)
      "num_cache_clusters"         = try(coalesce(lookup(v, "num_cache_clusters", null), local.merged_default_settings.num_cache_clusters), local.merged_default_settings.num_cache_clusters)
      "num_node_groups"            = try(coalesce(lookup(v, "num_node_groups", null), local.merged_default_settings.num_node_groups), local.merged_default_settings.num_node_groups)
      "replicas_per_node_group"    = try(coalesce(lookup(v, "replicas_per_node_group", null), local.merged_default_settings.replicas_per_node_group), local.merged_default_settings.replicas_per_node_group)
      "auto_minor_version_upgrade" = try(coalesce(lookup(v, "auto_minor_version_upgrade", null), local.merged_default_settings.auto_minor_version_upgrade), local.merged_default_settings.auto_minor_version_upgrade)
      "kms_key_id"                 = try(coalesce(lookup(v, "kms_key_id", null), local.merged_default_settings.kms_key_id), local.merged_default_settings.kms_key_id)
      "parameters"                 = merge(try(coalesce(lookup(v, "parameters", null), local.merged_default_settings.parameters), local.merged_default_settings.parameters), local.merged_default_settings.parameters)
    } if coalesce(lookup(v, "create", null), true)
  }
}

resource "aws_elasticache_subnet_group" "subnet_group" {
  for_each    = local.redis_map
  name        = each.value.identifier
  description = "Elasticache subnet group for ${each.value.identifier}"
  subnet_ids  = var.subnet_ids
  tags        = local.tags
}

resource "aws_elasticache_parameter_group" "parameter_group" {
  for_each    = local.redis_map
  name        = each.value.identifier
  description = "ElastiCache parameter group for ${each.value.identifier}"
  family      = substr(each.value.engine_version, 0, 1) < 6 ? "redis${replace(each.value.engine_version, "/\\.[\\d]+$/", "")}" : (substr(each.value.engine_version, 0, 1) ==6 ? "redis${replace(each.value.engine_version, "/\\.[\\d]+$/", "")}.x" : "redis${replace(each.value.engine_version, "/\\.[\\d]+$/", "")}")
  dynamic "parameter" {
    for_each = each.value.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elasticache_replication_group" "redis" {
  for_each                   = local.redis_map
  replication_group_id       = each.value.identifier
  description                = "ElastiCache replication group for ${each.value.identifier}"
  engine                     = "redis"
  port                       = 6379
  apply_immediately          = true
  node_type                  = each.value.node_type
  engine_version             = each.value.engine_version
  parameter_group_name       = aws_elasticache_parameter_group.parameter_group[each.key].id
  subnet_group_name          = aws_elasticache_subnet_group.subnet_group[each.key].id
  transit_encryption_enabled = each.value.transit_encryption_enabled
  auth_token                 = each.value.auth_token
  multi_az_enabled           = each.value.multi_az_enabled
  snapshot_retention_limit   = each.value.snapshot_retention_limit
  num_node_groups            = each.value.num_node_groups
  num_cache_clusters         = each.value.num_cache_clusters
  auto_minor_version_upgrade = tonumber(split(".", replace(each.value.engine_version, "v", ""))[0]) >= 6 ? each.value.auto_minor_version_upgrade : false
  at_rest_encryption_enabled = each.value.at_rest_encryption_enabled
  kms_key_id                 = each.value.kms_key_id
  replicas_per_node_group    = each.value.replicas_per_node_group
  security_group_ids         = [module.redis_sg[each.key].security_group_id]
  tags                       = local.tags
}

module "redis_sg" {
  for_each    = local.redis_map
  source      = "terraform-aws-modules/security-group/aws"
  version     = "~> 5.1.0"
  name        = "${each.value.identifier}-sg"
  description = "ElastiCache ${each.value.identifier} Security group"
  vpc_id      = var.vpc_id
  computed_ingress_with_source_security_group_id = length(var.ingress_security_group_id) > 0 ? [
    {
      rule                     = "redis-tcp"
      source_security_group_id = var.ingress_security_group_id
    }
  ] : []
  number_of_computed_ingress_with_source_security_group_id = length(var.ingress_security_group_id) > 0 ? 1 : 0
  computed_ingress_with_cidr_blocks = length(var.ingress_cidr_blocks) > 0 ? [
    {
      rule        = "redis-tcp"
      cidr_blocks = join(",", var.ingress_cidr_blocks)
    }
  ] : []
  number_of_computed_ingress_with_cidr_blocks = length(var.ingress_cidr_blocks) > 0 ? 1 : 0
}
