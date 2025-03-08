
# output "apps_info" {
#   value = {
#     for k, v in module.amplify_app : k => {
#       name                = v.name
#       arn                 = v.arn
#       id                  = v.id
#       default_domain      = v.default_domain
#       branch_names        = v.branch_names
#       domain_associations = v.domain_associations
#     }
#   }
# }

# output "apps_amplify_domainname" {
#   value = merge([
#     for k, v in local.apps_map : {
#       for k1, v1 in v.environments : format("%s-%s", k, v1.branch_name) => "${v1.branch_name}.${module.amplify_app[k].default_domain}"
#     }
#   ]...)
# }

# output "apps_webhook" {
#   value = {
#     for k, v in aws_amplify_webhook.webhook : k => v.url
#   }
# }