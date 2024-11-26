
locals {
  default_settings = {
    accepter_allow_remote_vpc_dns_resolution  = true
    requester_allow_remote_vpc_dns_resolution = true
    requester_cidr_blocks                     = []
    accepter_cidr_blocks                      = []
  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {

      }
    )
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  vpc_peering_map = {
    for k, v in var.vpc_peering : k => {
      "identifier"                                = "${module.context.id}-${k}"
      "create"                                    = coalesce(lookup(v, "create", null), true)
      "requester_vpc_id"                          = v.requester_vpc_id
      "accepter_vpc_id"                           = v.accepter_vpc_id
      "accepter_owner_id"                         = v.accepter_owner_id
      "accepter_region"                           = v.accepter_region
      "accepter_allow_remote_vpc_dns_resolution"  = try(coalesce(lookup(v, "accepter_allow_remote_vpc_dns_resolution", null), local.merged_default_settings.accepter_allow_remote_vpc_dns_resolution), local.merged_default_settings.accepter_allow_remote_vpc_dns_resolution)
      "requester_allow_remote_vpc_dns_resolution" = try(coalesce(lookup(v, "requester_allow_remote_vpc_dns_resolution", null), local.merged_default_settings.requester_allow_remote_vpc_dns_resolution), local.merged_default_settings.requester_allow_remote_vpc_dns_resolution)
      "requester_cidr_blocks"                     = try(coalesce(lookup(v, "requester_cidr_blocks", null), local.merged_default_settings.requester_cidr_blocks), local.merged_default_settings.requester_cidr_blocks)
      "accepter_cidr_blocks"                      = try(coalesce(lookup(v, "accepter_cidr_blocks", null), local.merged_default_settings.accepter_cidr_blocks), local.merged_default_settings.accepter_cidr_blocks)
    } if coalesce(lookup(v, "create", null), true)
  }
}

resource "aws_vpc_peering_connection" "requester" {
  for_each      = { for k, v in local.vpc_peering_map : k => v if v.create && length(v.requester_cidr_blocks) == 0 }
  vpc_id        = each.value.requester_vpc_id
  peer_owner_id = each.value.accepter_owner_id == null ? data.aws_caller_identity.current.account_id : each.value.accepter_owner_id
  peer_vpc_id   = each.value.accepter_vpc_id
  peer_region   = each.value.accepter_region == null ? data.aws_region.current.name : each.value.accepter_region
  auto_accept   = false
  tags          = merge({ Side = "Requester" }, local.tags)
  lifecycle {
    ignore_changes = [
      auto_accept,
      tags
    ]
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_vpc_peering_connection_options" "requester" {
  for_each                  = { for k, v in local.vpc_peering_map : k => v if v.create && length(v.requester_cidr_blocks) == 0 }
  vpc_peering_connection_id = aws_vpc_peering_connection.requester[each.key].id
  requester {
    allow_remote_vpc_dns_resolution = each.value.requester_allow_remote_vpc_dns_resolution
  }
  depends_on = [aws_vpc_peering_connection.requester]
}

data "aws_vpc_peering_connection" "vpc_peering_connection" {
  for_each    = { for k, v in local.vpc_peering_map : k => v if v.create }
  vpc_id      = each.value.requester_vpc_id
  peer_vpc_id = each.value.accepter_vpc_id
}

resource "aws_vpc_peering_connection_accepter" "accepter" {
  for_each                  = { for k, v in local.vpc_peering_map : k => v if v.create && length(v.accepter_cidr_blocks) == 0 }
  vpc_peering_connection_id = data.aws_vpc_peering_connection.vpc_peering_connection[each.key].id
  auto_accept               = true
  tags                      = merge({ Side = "Accepter" }, local.tags)
  lifecycle {
    ignore_changes = [
      auto_accept,
      tags
    ]
  }
}

resource "aws_vpc_peering_connection_options" "accepter" {
  for_each                  = { for k, v in local.vpc_peering_map : k => v if v.create && length(v.accepter_cidr_blocks) == 0 }
  vpc_peering_connection_id = data.aws_vpc_peering_connection.vpc_peering_connection[each.key].id
  accepter {
    allow_remote_vpc_dns_resolution = each.value.accepter_allow_remote_vpc_dns_resolution
  }
  depends_on = [aws_vpc_peering_connection_accepter.accepter]
}

data "aws_vpc" "requester" {
  for_each = { for k, v in local.vpc_peering_map : k => v if v.create && length(v.requester_cidr_blocks) == 0 }
  id       = each.value.requester_vpc_id
}

data "aws_vpc" "accepter" {
  for_each = { for k, v in local.vpc_peering_map : k => v if v.create && length(v.accepter_cidr_blocks) == 0 }
  id       = each.value.accepter_vpc_id
}

data "aws_subnets" "requester" {
  for_each = { for k, v in local.vpc_peering_map : k => v if v.create && length(v.requester_cidr_blocks) == 0 }
  filter {
    name   = "vpc-id"
    values = [each.value.requester_vpc_id]
  }
  tags = {
    Tier = "private"
  }
}

locals {
  requester_subnets = {
    for pair in flatten([
      for k, v in local.vpc_peering_map : [
        for subnet in data.aws_subnets.requester[k].ids : {
          key       = "${k}|${subnet}"
          vpc_id    = local.vpc_peering_map[k].requester_vpc_id
          subnet_id = subnet
        }
      ] if v.create && length(v.requester_cidr_blocks) == 0
      ]) : pair.key => {
      vpc_id    = pair.vpc_id
      subnet_id = pair.subnet_id
    }
  }
  accepter_subnets = {
    for pair in flatten([
      for k, v in local.vpc_peering_map : [
        for subnet in data.aws_subnets.accepter[k].ids : {
          key       = "${k}|${subnet}"
          vpc_id    = local.vpc_peering_map[k].accepter_vpc_id
          subnet_id = subnet
        }
      ] if v.create && length(v.accepter_cidr_blocks) == 0
      ]) : pair.key => {
      vpc_id    = pair.vpc_id
      subnet_id = pair.subnet_id
    }
  }
}

data "aws_subnet" "requester" {
  for_each = local.requester_subnets
  id       = each.value.subnet_id
}

data "aws_subnets" "accepter" {
  for_each = { for k, v in local.vpc_peering_map : k => v if v.create && length(v.accepter_cidr_blocks) == 0 }
  filter {
    name   = "vpc-id"
    values = [each.value.accepter_vpc_id]
  }
  tags = {
    Tier = "private"
  }
}

data "aws_subnet" "accepter" {
  for_each = local.accepter_subnets
  id       = each.value.subnet_id
}

data "aws_route_table" "requester" {
  for_each = { for k, v in local.vpc_peering_map : k => v if v.create && length(v.requester_cidr_blocks) == 0 }
  vpc_id   = each.value.requester_vpc_id
  filter {
    name   = "tag:Name"
    values = ["*-private"]
  }
}

data "aws_route_table" "accepter" {
  for_each = { for k, v in local.vpc_peering_map : k => v if v.create && length(v.accepter_cidr_blocks) == 0 }
  vpc_id   = each.value.accepter_vpc_id
  filter {
    name   = "tag:Name"
    values = ["*-private"]
  }
}

locals {
  requester_cidr_block_map = merge([
    for k, v in local.vpc_peering_map : {
      for cidr in v.requester_cidr_blocks : "${k}|${cidr}" => merge(v, {
        vpc_peering_map_key  = k
        requester_cidr_block = cidr
      })
    } if v.create && length(v.requester_cidr_blocks) != 0
  ]...)
  accepter_cidr_block_map = merge([
    for k, v in local.vpc_peering_map : {
      for cidr in v.accepter_cidr_blocks : "${k}|${cidr}" => merge(v, {
        vpc_peering_map_key = k
        accepter_cidr_block = cidr
      })
    } if v.create && length(v.accepter_cidr_blocks) != 0
  ]...)
}

resource "aws_route" "requester_route" {
  for_each                  = { for k, v in local.accepter_cidr_block_map : k => v if v.create && length(local.vpc_peering_map[v.vpc_peering_map_key].requester_cidr_blocks) == 0 }
  route_table_id            = data.aws_route_table.requester[each.value.vpc_peering_map_key].id
  destination_cidr_block    = each.value.accepter_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.requester[each.value.vpc_peering_map_key].id
  depends_on                = [aws_vpc_peering_connection.requester]
}

resource "aws_route" "accepter_route" {
  for_each                  = { for k, v in local.requester_cidr_block_map : k => v if v.create && length(local.vpc_peering_map[v.vpc_peering_map_key].accepter_cidr_blocks) == 0 }
  route_table_id            = data.aws_route_table.accepter[each.value.vpc_peering_map_key].id
  destination_cidr_block    = each.value.requester_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter[each.value.vpc_peering_map_key].id
  depends_on                = [aws_vpc_peering_connection_accepter.accepter]
}


locals {
  # requester_cidr = {
  #   for pair in flatten([
  #     for k, v in local.vpc_peering_map : [
  #       for subnet in data.aws_subnets.requester[k].ids : {
  #         key                 = "${k}|${subnet}"
  #         vpc_peering_map_key = k
  #         vpc_id              = local.vpc_peering_map[k].requester_vpc_id
  #         subnet_id           = subnet
  #         cidr                = data.aws_subnet.requester["${k}|${subnet}"].cidr_block
  #       }
  #     ] if v.create && length(v.requester_cidr_blocks) == 0
  #     ]) : pair.key => {
  #     vpc_peering_map_key = pair.vpc_peering_map_key
  #     vpc_id              = pair.vpc_id
  #     subnet_id           = pair.subnet_id
  #     cidr                = pair.cidr
  #   }
  # }
  # accepter_cidr = {
  #   for pair in flatten([
  #     for k, v in local.vpc_peering_map : [
  #       for subnet in data.aws_subnets.accepter[k].ids : {
  #         key                 = "${k}|${subnet}"
  #         vpc_peering_map_key = k
  #         vpc_id              = local.vpc_peering_map[k].accepter_vpc_id
  #         subnet_id           = subnet
  #         cidr                = data.aws_subnet.accepter["${k}|${subnet}"].cidr_block
  #       }
  #     ] if v.create && length(v.accepter_cidr_blocks) == 0
  #     ]) : pair.key => {
  #     vpc_peering_map_key = pair.vpc_peering_map_key
  #     vpc_id              = pair.vpc_id
  #     subnet_id           = pair.subnet_id
  #     cidr                = pair.cidr
  #   }
  # }
}

# resource "aws_route" "requester_route_default_cidr" {
#   for_each                  = local.accepter_cidr

#   route_table_id            = data.aws_route_table.requester[each.value.vpc_peering_map_key].id
#   destination_cidr_block    = each.value.cidr
#   vpc_peering_connection_id = aws_vpc_peering_connection.requester[each.value.vpc_peering_map_key].id
#   depends_on                = [aws_vpc_peering_connection.requester]
# }

# resource "aws_route" "accepter_route_default_cidr" {
#   for_each                  = { for k,v in local.requester_cidr : k => v if v.create && length(local.vpc_peering_map[v.vpc_peering_map_key].requester_cidr_blocks) == 0 }
#   route_table_id            = data.aws_route_table.accepter[each.value.vpc_peering_map_key].id
#   destination_cidr_block    = each.value.cidr
#   vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter[each.value.vpc_peering_map_key].id
#   depends_on                = [aws_vpc_peering_connection_accepter.accepter]
# }