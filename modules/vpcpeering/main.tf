resource "aws_vpc_peering_connection" "requester" {
  count       = var.create && length(var.requester_cidr_blocks) == 0 ? 1 : 0
  vpc_id      = var.requester_vpc_id
  peer_vpc_id = var.accepter_vpc_id
  auto_accept = false
  tags = merge({ Side = "Requester" }, local.tags)
  lifecycle {
    ignore_changes = [
      auto_accept,
      tags
    ]
  }
}

resource "aws_vpc_peering_connection_options" "requester" {
  count       = var.create && length(var.requester_cidr_blocks) == 0 ? 1 : 0
  vpc_peering_connection_id = join("", aws_vpc_peering_connection.requester[*].id)
  requester {
    allow_remote_vpc_dns_resolution = var.requester_allow_remote_vpc_dns_resolution
  }
}

data "aws_vpc_peering_connection" "vpc_peering_connection" {
  count           = var.create && length(var.accepter_cidr_blocks) == 0 ? 1 : 0
  vpc_id          = var.requester_vpc_id
}

resource "aws_vpc_peering_connection_accepter" "accepter" {
  count                     = var.create && length(var.accepter_cidr_blocks) == 0 ? 1 : 0
  vpc_peering_connection_id = join("", data.aws_vpc_peering_connection.vpc_peering_connection[*].id)
  auto_accept               = true
  tags = merge({ Side = "Accepter" }, local.tags)
  lifecycle {
    ignore_changes = [
      auto_accept,
      tags
    ]
  }
}

resource "aws_vpc_peering_connection_options" "accepter" {
  count                     = var.create && length(var.accepter_cidr_blocks) == 0 ? 1 : 0
  vpc_peering_connection_id = join("", data.aws_vpc_peering_connection.vpc_peering_connection[*].id)
  accepter {
    allow_remote_vpc_dns_resolution = var.accepter_allow_remote_vpc_dns_resolution
  }
  depends_on = [aws_vpc_peering_connection_accepter.accepter]
}

data "aws_vpc" "requester" {
  count = var.create && length(var.requester_cidr_blocks) == 0 ? 1 : 0
  id    = var.requester_vpc_id
}

data "aws_vpc" "accepter" {
  count = var.create && length(var.accepter_cidr_blocks) == 0 ? 1 : 0
  id    = var.accepter_vpc_id
}

data "aws_subnets" "requester" {
  count = var.create && length(var.requester_cidr_blocks) == 0 ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.requester_vpc_id]
  }
  tags = {
    Tier = "private"
  }
}

data "aws_subnets" "accepter" {
  count = var.create && length(var.accepter_cidr_blocks) == 0 ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.accepter_vpc_id]
  }
  tags = {
    Tier = "private"
  }
}

data "aws_subnet" "requester" {
  for_each = var.create && length(var.requester_cidr_blocks) == 0 ? toset(data.aws_subnets.requester[0].ids) : toset([])
  id       = each.value
}

data "aws_subnet" "accepter" {
  for_each = var.create && length(var.accepter_cidr_blocks) == 0 ? toset(data.aws_subnets.accepter[0].ids) : toset([])
  id       = each.value
}

locals {
  requester_cidr_blocks = var.create ? (length(var.requester_cidr_blocks) == 0 ? [for s in data.aws_subnet.requester : s.cidr_block] : var.requester_cidr_blocks) : []
  accepter_cidr_blocks  = var.create ? (length(var.accepter_cidr_blocks) == 0 ? [for s in data.aws_subnet.accepter : s.cidr_block] : var.accepter_cidr_blocks) : []
}

data "aws_route_table" "requester" {
  count  = var.create && length(var.requester_cidr_blocks) == 0 ? 1 : 0
  vpc_id = var.requester_vpc_id
  filter {
    name   = "tag:Name"
    values = ["*-private"]
  }
}

data "aws_route_table" "accepter" {
  count  = var.create && length(var.accepter_cidr_blocks) == 0 ? 1 : 0
  vpc_id = var.accepter_vpc_id
  filter {
    name   = "tag:Name"
    values = ["*-private"]
  }
}

resource "aws_route" "requester" {
  for_each                  = var.create && length(var.requester_cidr_blocks) == 0 ? toset(local.accepter_cidr_blocks) : toset([])
  route_table_id            = join("", data.aws_route_table.requester[*].id)
  destination_cidr_block    = each.value
  vpc_peering_connection_id = join("", aws_vpc_peering_connection.requester[*].id)
  depends_on                = [aws_vpc_peering_connection.requester]
}

resource "aws_route" "accepter" {
  for_each                  = var.create && length(var.accepter_cidr_blocks) == 0 ? toset(local.requester_cidr_blocks) : toset([])
  route_table_id            = join("", data.aws_route_table.accepter[*].id)
  destination_cidr_block    = each.value
  vpc_peering_connection_id = join("", aws_vpc_peering_connection_accepter.accepter[*].id)
  depends_on                = [aws_vpc_peering_connection_accepter.accepter]
}