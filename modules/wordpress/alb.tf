module "alb" {
  source             = "terraform-aws-modules/alb/aws"
  version            = "~> 9.7.0"
  create             = true
  name               = module.context.id
  load_balancer_type = "application"
  vpc_id             = var.vpc_id
  subnets            = var.public_subnet_ids
  access_logs = {
    bucket = module.log_bucket.s3_bucket_id
    prefix = module.context.id
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
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "wordpress"
      }
    },
    https = var.domain_name != "" ? {
      port            = 443
      protocol        = var.attach_ssl ? "HTTPS" : "HTTP"
      certificate_arn = var.attach_ssl ? (var.wildcard_domain ? data.aws_acm_certificate.wildcard[0].arn : data.aws_acm_certificate.non_wildcard[0].arn) : null
      forward = {
        target_group_key = "wordpress"
      }
    } : null
  }
  target_groups = {
    wordpress = {
      name_prefix          = "wp"
      protocol             = "HTTP"
      port                 = 80
      target_type          = "instance"
      deregistration_delay = 150
      create_attachment    = false
      health_check = {
        enabled             = true
        path                = "/"
        healthy_threshold   = 5
        unhealthy_threshold = 5
        timeout             = 10
        interval            = 45
        protocol            = "HTTP"
        matcher             = "200-499"
        port                = "traffic-port"
      }
    }
  }
  tags = local.tags
}

data "aws_acm_certificate" "wildcard" {
  count    = var.wildcard_domain && var.domain_name != "" && var.attach_ssl ? 1 : 0
  domain   = join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))
  statuses = ["ISSUED"]
}

data "aws_acm_certificate" "non_wildcard" {
  count    = !var.wildcard_domain && var.domain_name != "" && var.attach_ssl ? 1 : 0
  domain   = var.domain_name
  statuses = ["ISSUED"]
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