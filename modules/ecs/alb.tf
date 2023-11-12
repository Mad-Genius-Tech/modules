module "alb_internal" {
  source                     = "terraform-aws-modules/alb/aws"
  version                    = "~> 9.1.0"
  name                       = "${module.context.id}-internal"
  load_balancer_type         = "application"
  internal                   = true
  vpc_id                     = var.vpc_id
  subnets                    = var.private_subnets
  enable_deletion_protection = false
  access_logs = {
    bucket = module.log_bucket.s3_bucket_id
    prefix = "${module.context.id}-internal"
  }
  security_group_ingress_rules = {
    for v in values(local.ecs_map) : v.identifier => {
      from_port   = v.container_port
      to_port     = v.container_port
      ip_protocol = "tcp"
      description = "${v.identifier} http traffic"
      cidr_ipv4   = var.vpc_cidr
    } if v.create_alb
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = var.vpc_cidr
    }
  }
  listeners = {
    for v in values(local.ecs_map) : v.identifier => {
      port     = v.container_port
      protocol = "HTTP"
      forward = {
        target_group_key = v.identifier
      }
    } if v.create_alb
  }
  target_groups = {
    for v in values(local.ecs_map) : v.identifier => {
      name_prefix          = "${var.stage_name}i-"
      protocol             = "HTTP"
      port                 = v.container_port
      target_type          = "ip"
      deregistration_delay = 150
      create_attachment    = false
      health_check = {
        enabled             = true
        path                = v.health_check_path
        healthy_threshold   = 5
        unhealthy_threshold = 2
        interval            = 15
        protocol            = "HTTP"
        matcher             = "200"
        port                = "traffic-port"
        timeout             = 5
      }
    } if v.create_alb
  }
  tags = local.tags
}

data "aws_acm_certificate" "wildcard" {
  for_each = { for k, v in local.ecs_map : k => v if v.create && v.wildcard_domain && v.domain_name != "" }
  domain   = join(".", slice(split(".", each.value.domain_name), 1, length(split(".", each.value.domain_name))))
  statuses = ["ISSUED"]
}

data "aws_acm_certificate" "non_wildcard" {
  for_each = { for k, v in local.ecs_map : k => v if v.create && !v.wildcard_domain && v.domain_name != "" }
  domain   = each.value.domain_name
  statuses = ["ISSUED"]
}

module "alb" {
  source                     = "terraform-aws-modules/alb/aws"
  version                    = "~> 9.1.0"
  for_each                   = { for k, v in local.ecs_map : k => v if v.create_alb && v.external_alb }
  create                     = each.value.create_alb
  name                       = each.value.identifier
  load_balancer_type         = "application"
  vpc_id                     = var.vpc_id
  subnets                    = var.public_subnets
  enable_deletion_protection = false
  access_logs = {
    bucket = module.log_bucket.s3_bucket_id
    prefix = each.value.identifier
  }
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    },
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
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
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    },
    https = each.value.domain_name != "" ? {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = each.value.wildcard_domain ? data.aws_acm_certificate.wildcard[each.key].arn : data.aws_acm_certificate.non_wildcard[each.key].arn
      forward = {
        target_group_key = each.value.identifier
      }
    } : null
  }
  target_groups = {
    (each.value.identifier) = {
      name_prefix          = "${var.stage_name}-"
      protocol             = "HTTP"
      port                 = each.value.container_port
      target_type          = "ip"
      deregistration_delay = 150
      create_attachment    = false
      health_check = {
        enabled             = true
        path                = each.value.health_check_path
        healthy_threshold   = 5
        unhealthy_threshold = 2
        interval            = 15
        protocol            = "HTTP"
        matcher             = "200"
        port                = "traffic-port"
        timeout             = 5
      }
    }
  }
  tags = local.tags
}

module "log_bucket" {
  source                                = "terraform-aws-modules/s3-bucket/aws"
  version                               = "~> 3.15.1"
  bucket                                = "${module.context.id}-alb-logs"
  acl                                   = "log-delivery-write"
  force_destroy                         = true
  control_object_ownership              = true
  object_ownership                      = "ObjectWriter"
  attach_elb_log_delivery_policy        = true # Required for ALB logs
  attach_lb_log_delivery_policy         = true # Required for ALB/NLB logs
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
  lifecycle_rule = [
    {
      id                                     = "abort-failed-uploads"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 1
    },
    {
      id      = "clear-versioned-assets"
      enabled = true
      # noncurrent_version_transition = [
      #   {
      #     days          = 30
      #     storage_class = "ONEZONE_IA"
      #   }
      # ]
      noncurrent_version_expiration = {
        days = 1
      }
    },
    {
      id      = "delete-logs"
      enabled = true
      expiration = {
        days = 14
      }
    }
  ]
  tags = local.tags
}