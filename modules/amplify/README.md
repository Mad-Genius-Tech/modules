<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_amplify_app"></a> [amplify\_app](#module\_amplify\_app) | cloudposse/amplify-app/aws | 1.0.0 |
| <a name="module_context"></a> [context](#module\_context) | cloudposse/label/null | ~> 0.25.0 |

## Resources

| Name | Type |
|------|------|
| [aws_amplify_webhook.webhook](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/amplify_webhook) | resource |
| [null_resource.webhook_trigger](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_token"></a> [access\_token](#input\_access\_token) | n/a | `string` | `null` | no |
| <a name="input_apps"></a> [apps](#input\_apps) | n/a | <pre>map(object({<br>    repository                  = string<br>    description                 = optional(string)<br>    branch_name                 = optional(string)<br>    platform                    = optional(string)<br>    oauth_token                 = optional(string)<br>    build_spec                  = optional(string)<br>    enable_auto_branch_creation = optional(bool)<br>    enable_branch_auto_build    = optional(bool)<br>    enable_branch_auto_deletion = optional(bool)<br>    environment_variables       = optional(map(string))<br>    iam_service_role_enabled    = optional(bool)<br>    stage                       = optional(string)<br>    domains = optional(map(object({<br>      enable_auto_sub_domain = optional(bool, false)<br>      wait_for_verification  = optional(bool, false)<br>      sub_domain = list(object({<br>        branch_name = string<br>        prefix      = string<br>      }))<br>    })))<br>    environments = optional(map(object({<br>      branch_name                   = optional(string)<br>      backend_enabled               = optional(bool, false)<br>      environment_name              = optional(string)<br>      deployment_artifacts          = optional(string)<br>      stack_name                    = optional(string)<br>      display_name                  = optional(string)<br>      description                   = optional(string)<br>      enable_auto_build             = optional(bool)<br>      enable_basic_auth             = optional(bool)<br>      enable_notification           = optional(bool)<br>      enable_performance_mode       = optional(bool)<br>      enable_pull_request_preview   = optional(bool)<br>      environment_variables         = optional(map(string))<br>      framework                     = optional(string)<br>      pull_request_environment_name = optional(string)<br>      stage                         = optional(string)<br>      ttl                           = optional(number)<br>      webhook_enabled               = optional(bool, false)<br>    })))<br>  }))</pre> | n/a | yes |
| <a name="input_domain_config"></a> [domain\_config](#input\_domain\_config) | Amplify custom domain configuration | <pre>object({<br>    domain_name            = optional(string)<br>    enable_auto_sub_domain = optional(bool, false)<br>    wait_for_verification  = optional(bool, false)<br>    sub_domain = list(object({<br>      branch_name = string<br>      prefix      = string<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | n/a | `string` | `""` | no |
| <a name="input_oauth_token"></a> [oauth\_token](#input\_oauth\_token) | n/a | `string` | `null` | no |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_apps_amplify_domainname"></a> [apps\_amplify\_domainname](#output\_apps\_amplify\_domainname) | n/a |
| <a name="output_apps_info"></a> [apps\_info](#output\_apps\_info) | n/a |
| <a name="output_apps_webhook"></a> [apps\_webhook](#output\_apps\_webhook) | n/a |
<!-- END_TF_DOCS -->