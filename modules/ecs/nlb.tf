resource "aws_eip" "eip" {
  count = length(merge([
    for k, v in local.ecs_map : {
      for subnet in var.public_subnets :
      "${k}|${subnet}" => {
        "subnet" = subnet
      }
    } if v.create_nlb && v.create_eip
  ]...))
  domain = "vpc"
  tags   = local.tags
}

module "nlb" {
  source                           = "terraform-aws-modules/alb/aws"
  version                          = "~> 9.1.0"
  for_each                         = { for k, v in local.ecs_map : k => v if v.create_nlb }
  create                           = each.value.create_nlb
  name                             = each.value.identifier
  load_balancer_type               = "network"
  vpc_id                           = var.vpc_id
  dns_record_client_routing_policy = "partial_availability_zone_affinity"
  subnet_mapping = each.value.create_eip ? [for i, eip in aws_eip.eip :
    {
      allocation_id = eip.id
      subnet_id     = var.public_subnets[i % length(var.public_subnets)]
    }
  ] : []
  subnets                    = each.value.create_eip ? null : var.public_subnets
  enable_deletion_protection = false
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP tcp traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS tcp traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = var.vpc_cidr
    }
  }
  listeners = {
    http = {
      port     = 80
      protocol = "TCP"
      forward = {
        target_group_key = each.value.multiple_ports ? "${each.value.identifier}-80" : each.value.identifier
      }
    }
    https = {
      port     = 443
      protocol = "TCP"
      forward = {
        target_group_key = each.value.multiple_ports ? "${each.value.identifier}-443" : each.value.identifier
      }
    }
  }
  target_groups = each.value.multiple_ports ? {
    "${each.value.identifier}-80" = {
      name_prefix        = "${var.stage_name}-"
      protocol           = "TCP"
      port               = 80
      target_type        = "ip"
      create_attachment  = false
      preserve_client_ip = false
      proxy_protocol_v2  = false
      # deregistration_delay = 10
      # connection_termination = true
      # stickiness = {
      #   type = "source_ip"
      # }
      health_check = {
        enabled             = true
        protocol            = "HTTP" # "TCP"
        port                = "traffic-port"
        path                = each.value.health_check_path
        matcher             = "200"
        healthy_threshold   = 5
        unhealthy_threshold = 2
        interval            = 30
        timeout             = 10
      }
    }
    "${each.value.identifier}-443" = {
      name_prefix        = "${var.stage_name}-"
      protocol           = "TCP"
      port               = 443
      target_type        = "ip"
      create_attachment  = false
      preserve_client_ip = false
      proxy_protocol_v2  = false
      # deregistration_delay = 10
      # connection_termination = true
      # stickiness = {
      #   type = "source_ip"
      # }
      health_check = {
        enabled             = true
        protocol            = "HTTP" # "TCP"
        port                = "80"
        path                = each.value.health_check_path
        matcher             = "200"
        healthy_threshold   = 5
        unhealthy_threshold = 2
        interval            = 30
        timeout             = 10
      }
    }
    } : {
    "${each.value.identifier}" = {
      name_prefix        = "${var.stage_name}-"
      protocol           = "TCP"
      port               = each.value.container_port
      target_type        = "ip"
      create_attachment  = false
      preserve_client_ip = false
      proxy_protocol_v2  = false
      health_check = {
        enabled             = true
        path                = each.value.health_check_path
        protocol            = "HTTP"
        matcher             = "200"
        port                = "traffic-port"
        healthy_threshold   = 5
        unhealthy_threshold = 2
        interval            = 30
        timeout             = 10
      }
    }
  }
  tags = local.tags
}