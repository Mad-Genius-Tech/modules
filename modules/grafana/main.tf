module "grafana" {
  source                   = "terraform-aws-modules/managed-service-grafana/aws"
  version                  = "~> 2.2.0"
  create                   = true
  name                     = module.context.id
  associate_license        = false
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  data_sources             = []
  tags                     = local.tags
}