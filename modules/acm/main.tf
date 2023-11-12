module "regional_acm" {
  for_each                  = var.regional_acm_domains
  source                    = "terraform-aws-modules/acm/aws"
  version                   = "~> 4.3.2"
  domain_name               = each.key
  subject_alternative_names = each.value.alternative_names
  create_route53_records    = false
  wait_for_validation       = each.value.wait_for_validation
  tags                      = local.tags
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

module "global_acm" {
  for_each                  = var.global_acm_domains
  source                    = "terraform-aws-modules/acm/aws"
  version                   = "~> 4.3.2"
  domain_name               = each.key
  subject_alternative_names = each.value.alternative_names
  create_route53_records    = false
  wait_for_validation       = each.value.wait_for_validation
  tags                      = local.tags

  providers = {
    aws = aws.us-east-1
  }
}