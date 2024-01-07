<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_context"></a> [context](#module\_context) | cloudposse/label/null | ~> 0.25.0 |
| <a name="module_iam_role"></a> [iam\_role](#module\_iam\_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role | ~> 5.32.0 |

## Resources

| Name | Type |
|------|------|
| [aws_amplify_app.amplify](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/amplify_app) | resource |
| [aws_amplify_backend_environment.backend_environment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/amplify_backend_environment) | resource |
| [aws_amplify_branch.branch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/amplify_branch) | resource |
| [aws_amplify_domain_association.domain_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/amplify_domain_association) | resource |
| [aws_iam_policy.iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_document.iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_token"></a> [access\_token](#input\_access\_token) | n/a | `string` | n/a | yes |
| <a name="input_apps"></a> [apps](#input\_apps) | n/a | <pre>map(object({<br>    repository                    = string<br>    domain_name                   = optional(string)<br>    description                   = optional(string)<br>    platform                      = optional(string)<br>    framework                     = optional(string)<br>    auto_branch_creation_patterns = optional(list(string))<br>    basic_auth_credentials        = optional(string)<br>    build_spec                    = optional(string)<br>    enable_auto_branch_creation   = optional(bool)<br>    enable_branch_auto_build      = optional(bool)<br>    enable_branch_auto_deletion   = optional(bool)<br>    enable_basic_auth             = optional(bool)<br>    environment_variables         = optional(map(string))<br>    auto_branch_creation_config = optional(object({<br>      basic_auth_credentials        = optional(string)<br>      build_spec                    = optional(string)<br>      enable_auto_build             = optional(bool)<br>      enable_basic_auth             = optional(bool)<br>      enable_performance_mode       = optional(bool)<br>      enable_pull_request_preview   = optional(bool)<br>      environment_variables         = optional(map(string))<br>      framework                     = optional(string)<br>      pull_request_environment_name = optional(string)<br>      stage                         = optional(string)<br>    }))<br>    custom_rules = optional(list(object({<br>      condition = optional(string)<br>      source    = string<br>      status    = optional(string)<br>      target    = string<br>    })))<br>    enable_auto_sub_domain = optional(bool)<br>    wait_for_verification  = optional(bool)<br>    backend_environments = optional(map(object({<br>      environment_name     = optional(string)<br>      deployment_artifacts = optional(string)<br>      stack_name           = optional(string)<br>    })))<br>    frontend_branches = optional(map(object({<br>      description                   = optional(string)<br>      branch_name                   = optional(string)<br>      ttl                           = optional(number)<br>      enable_basic_auth             = optional(bool)<br>      enable_auto_build             = optional(bool)<br>      enable_pull_request_preview   = optional(bool)<br>      enable_performance_mode       = optional(bool)<br>      enable_notification           = optional(bool)<br>      environment_variables         = optional(map(string))<br>      pull_request_environment_name = optional(string)<br>      backend_enabled               = optional(bool)<br>      sub_domain_name               = optional(string)<br>      webhook_enabled               = optional(bool)<br>    })))<br>  }))</pre> | n/a | yes |
| <a name="input_create_iam_role"></a> [create\_iam\_role](#input\_create\_iam\_role) | n/a | `bool` | `true` | no |
| <a name="input_iam_service_role_actions"></a> [iam\_service\_role\_actions](#input\_iam\_service\_role\_actions) | n/a | `list(string)` | `[]` | no |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | n/a | `string` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->