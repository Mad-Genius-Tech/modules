
data "aws_acm_certificate" "wildcard" {
  count    = var.create && var.wildcard_domain ? 1 : 0
  domain   = join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))
  statuses = ["ISSUED"]
}

data "aws_acm_certificate" "non_wildcard" {
  count    = var.create && !var.wildcard_domain ? 1 : 0
  domain   = var.domain_name
  statuses = ["ISSUED"]
}

locals {
  aws_acm_certificate_arn = var.create ? (var.wildcard_domain ? data.aws_acm_certificate.wildcard[0].arn : data.aws_acm_certificate.non_wildcard[0].arn) : null
}

module "alb" {
  source             = "terraform-aws-modules/alb/aws"
  version            = "~> 8.7.0"
  create_lb          = var.create
  name               = "${module.context.id}-${var.alb_name}"
  load_balancer_type = "application"
  vpc_id             = var.vpc_id
  subnets            = var.public_subnets
  security_groups    = [module.alb_sg.security_group_id]
  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        host        = var.redirect_to
        path        = "/#{path}"
        query       = "#{query}"
        port        = "80"
        protocol    = "HTTP"
        status_code = "HTTP_301"
      }
    }
  ]
  https_listeners = [
    {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = local.aws_acm_certificate_arn
      action_type     = "redirect"
      redirect = {
        host        = var.redirect_to
        path        = "/#{path}"
        query       = "#{query}"
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]
  tags = local.tags
}

module "alb_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "~> 5.1.0"
  create              = var.create
  name                = "${module.context.id}-${var.alb_name}"
  description         = "ALB ${module.context.id}-${var.alb_name} Security group"
  vpc_id              = var.vpc_id
  egress_rules        = ["all-all"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
}

data "aws_route53_zone" "zone" {
  count = var.create && var.create_route53_cname ? 1 : 0
  name  = join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))
}

module "records" {
  source    = "terraform-aws-modules/route53/aws//modules/records"
  version   = "~> 2.10.2"
  create    = var.create && var.create_route53_cname
  zone_name = var.create_route53_cname ? data.aws_route53_zone.zone[0].name : ""
  records = [
    {
      name = "www"
      type = "A"
      alias = {
        name    = module.alb.lb_dns_name
        zone_id = module.alb.lb_zone_id
      }
    }
  ]
}