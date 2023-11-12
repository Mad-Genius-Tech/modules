locals {
  network_name = module.context.id
  cluster_name = "${var.org_name}-${var.stage_name}-eks"
}

module "vpc" {
  source     = "terraform-aws-modules/vpc/aws"
  version    = "~> 5.1.1"
  create_vpc = var.create

  name = local.network_name
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, var.subnet_num)
  public_subnets  = [for k, v in slice(data.aws_availability_zones.available.names, 0, var.subnet_num) : cidrsubnet(var.vpc_cidr, 4, k)]
  private_subnets = [for k, v in slice(data.aws_availability_zones.available.names, 0, var.subnet_num) : cidrsubnet(var.vpc_cidr, 4, k + var.subnet_num)]

  private_subnet_names = ["${local.network_name}-private-1", "${local.network_name}-private-2", "${local.network_name}-private-3"]
  public_subnet_names  = ["${local.network_name}-public-1", "${local.network_name}-public-2", "${local.network_name}-public-3"]

  create_database_subnet_group  = false
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_vpn_gateway = var.enable_vpn_gateway

  enable_flow_log                     = var.enable_flow_log
  flow_log_destination_type           = "s3"
  flow_log_destination_arn            = module.vpc_flow_logs_bucket.s3_bucket_arn
  flow_log_traffic_type               = "ALL"
  flow_log_file_format                = "parquet"
  flow_log_log_format                 = "$${version} $${account-id} $${vpc-id} $${subnet-id} $${instance-id} $${region} $${az-id} $${action} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${tcp-flags} $${type} $${pkt-srcaddr} $${pkt-dstaddr} $${packets} $${bytes} $${pkt-src-aws-service} $${pkt-dst-aws-service} $${flow-direction} $${traffic-path}"
  flow_log_hive_compatible_partitions = true
  flow_log_per_hour_partition         = true
  vpc_flow_log_tags                   = merge({ "Name" = local.network_name }, local.tags)

  public_subnet_tags = var.enable_eks_tag ? {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
    "Tier"                                        = "public"
    } : {
    "Tier" = "public"
  }

  private_subnet_tags = var.enable_eks_tag ? {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
    "Tier"                                        = "private"
    } : {
    "Tier" = "private"
  }

  tags = var.enable_eks_tag ? merge(local.tags,
    {
      "kubernetes.io/cluster/${local.cluster_name}" = "shared",
    }
  ) : local.tags
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0.0"
  create  = var.create

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
      tags            = merge({ Name = "s3-vpc-endpoint" }, local.tags)
    },
    dynamodb = {
      create          = var.enable_dynamodb_endpoint
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
      tags            = merge({ Name = "dynamodb-vpc-endpoint" }, local.tags)
    }
  }
}

module "vpc_flow_logs_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "~> 3.15.0"
  create_bucket = var.create && var.enable_flow_log

  bucket              = "${local.network_name}-flowlogs"
  acl                 = "private"
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  object_ownership    = "BucketOwnerEnforced"
  policy              = var.create && var.enable_flow_log ? data.aws_iam_policy_document.vpc_flow_logs_bucket[0].json : null
  force_destroy       = false

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.tags
}

data "aws_iam_policy_document" "vpc_flow_logs_bucket" {
  count = var.create && var.enable_flow_log ? 1 : 0
  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = [module.vpc_flow_logs_bucket.s3_bucket_arn]
  }

  statement {
    sid    = "AWSLogDeliveryAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [module.vpc_flow_logs_bucket.s3_bucket_arn]
  }
}